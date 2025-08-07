# frozen_string_literal: true

module BetterRailsSecretsManager
  class CredentialsAdapter
    def self.read(environment)
      credentials = get_credentials_for(environment)
      return {} unless credentials
      
      # Convert credentials to a hash
      credentials.to_h
    rescue => e
      Rails.logger.error "Failed to read credentials for #{environment}: #{e.message}"
      {}
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
      if environment.to_s == 'production'
        Rails.application.credentials
      else
        # For Rails 6+, use environment-specific credentials
        if Rails.application.respond_to?(:credentials)
          Rails.application.credentials(environment: environment.to_sym)
        else
          nil
        end
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