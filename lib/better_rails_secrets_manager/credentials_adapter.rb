# frozen_string_literal: true

module BetterRailsSecretsManager
  class CredentialsAdapter
    def self.read(environment)
      credentials = get_credentials_for(environment)
      
      Rails.logger.debug "Reading credentials for #{environment}"
      Rails.logger.debug "Credentials class: #{credentials.class}"
      Rails.logger.debug "Credentials inspect: #{credentials.inspect[0..200]}" if credentials
      
      return {} unless credentials
      
      # Convert credentials to a plain hash, handling OrderedOptions
      result = convert_to_hash(credentials)
      Rails.logger.debug "Converted result keys: #{result.keys.inspect}"
      
      result
    rescue => e
      Rails.logger.error "Failed to read credentials for #{environment}: #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
      {}
    end
    
    def self.convert_to_hash(obj)
      case obj
      when ActiveSupport::OrderedOptions
        # Convert OrderedOptions to hash recursively
        result = {}
        obj.each_pair do |key, value|
          result[key] = convert_to_hash(value)
        end
        result
      when Hash
        # Recursively convert nested hashes
        obj.transform_values { |v| convert_to_hash(v) }
      when Array
        # Handle arrays
        obj.map { |item| convert_to_hash(item) }
      else
        # Return primitive values as-is
        obj
      end
    end
    
    def self.write(environment, secrets_hash)
      credentials_path = credentials_path_for(environment)
      key_path = key_path_for(environment)
      
      # Ensure the key exists
      unless File.exist?(key_path)
        Rails.logger.error "Key file not found: #{key_path}"
        return false
      end
      
      # Create encrypted configuration
      config = ActiveSupport::EncryptedConfiguration.new(
        config_path: credentials_path,
        key_path: key_path,
        env_key: env_key_for(environment),
        raise_if_missing_key: false
      )
      
      # Write the secrets
      config.write(secrets_hash.to_yaml.sub(/\A---\n/, ''))
      true
    rescue => e
      Rails.logger.error "Failed to write credentials: #{e.message}"
      false
    end
    
    private
    
    def self.get_credentials_for(environment)
      begin
        if environment.to_s == 'production'
          # For production, use the main credentials file
          creds = Rails.application.credentials
          
          # If it's an EncryptedConfiguration, get the actual config
          if creds.respond_to?(:config)
            creds.config
          else
            creds
          end
        else
          # For other environments, load environment-specific credentials
          # First check if the file exists
          creds_path = Rails.root.join('config', 'credentials', "#{environment}.yml.enc")
          key_path = Rails.root.join('config', 'credentials', "#{environment}.key")
          
          if File.exist?(creds_path) && File.exist?(key_path)
            # Create an EncryptedConfiguration for this environment
            config = ActiveSupport::EncryptedConfiguration.new(
              config_path: creds_path,
              key_path: key_path,
              env_key: "RAILS_#{environment.to_s.upcase}_KEY",
              raise_if_missing_key: false
            )
            
            # Read and parse the credentials
            content = config.read
            if content.is_a?(String)
              YAML.safe_load(content, permitted_classes: [Symbol]) || {}
            else
              content || {}
            end
          else
            {}
          end
        end
      rescue => e
        Rails.logger.error "Error loading credentials for #{environment}: #{e.message}"
        {}
      end
    end
    
    def self.credentials_path_for(environment)
      if environment.to_s == 'production'
        Rails.root.join('config', 'credentials.yml.enc')
      else
        Rails.root.join('config', 'credentials', "#{environment}.yml.enc")
      end
    end
    
    def self.key_path_for(environment)
      if environment.to_s == 'production'
        Rails.root.join('config', 'master.key')
      else
        Rails.root.join('config', 'credentials', "#{environment}.key")
      end
    end
    
    def self.env_key_for(environment)
      if environment.to_s == 'production'
        'RAILS_MASTER_KEY'
      else
        "RAILS_#{environment.to_s.upcase}_KEY"
      end
    end
  end
end