# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module BetterRailsSecretsManager
  class SimpleCredentialsReader
    def self.read(environment)
      Rails.logger.info "[BetterRailsSecretsManager] Reading credentials for: #{environment}"
      
      # "credentials" refers to the main config/credentials.yml.enc file
      if environment.to_s == 'credentials'
        read_main_credentials
      else
        # ALL other environments (including production) use environment-specific files
        read_environment_credentials(environment)
      end
    rescue => e
      Rails.logger.error "[BetterRailsSecretsManager] Error: #{e.message}"
      {}
    end
    
    def self.write(environment, secrets_hash)
      Rails.logger.info "[BetterRailsSecretsManager] Writing credentials for: #{environment}"
      Rails.logger.info "[BetterRailsSecretsManager] Keys to write: #{secrets_hash.keys.inspect}"
      
      credentials_path = credentials_path_for(environment)
      key_path = key_path_for(environment)
      
      Rails.logger.info "[BetterRailsSecretsManager] Credentials path: #{credentials_path}"
      Rails.logger.info "[BetterRailsSecretsManager] Key path: #{key_path}"
      
      # Check if key exists
      unless File.exist?(key_path)
        # Try environment variable
        env_key = env_key_for(environment)
        if ENV[env_key].blank?
          Rails.logger.error "[BetterRailsSecretsManager] Key file not found and no #{env_key} set"
          return false
        end
      end
      
      # Read the key
      key = if File.exist?(key_path)
        File.read(key_path).strip
      else
        ENV[env_key_for(environment)]
      end
      
      # Ensure credentials directory exists
      FileUtils.mkdir_p(File.dirname(credentials_path))
      
      # Create the encrypted configuration
      config = ActiveSupport::EncryptedConfiguration.new(
        config_path: credentials_path,
        key_path: key_path,
        env_key: env_key_for(environment),
        raise_if_missing_key: false
      )
      
      # Convert hash to proper YAML format
      # Rails credentials expects YAML without the document separator
      yaml_content = secrets_hash.deep_stringify_keys.to_yaml
      yaml_content = yaml_content.sub(/\A---\n/, '') if yaml_content.start_with?("---\n")
      
      Rails.logger.info "[BetterRailsSecretsManager] Writing YAML content (first 100 chars): #{yaml_content[0..100]}"
      
      # Write the content
      config.write(yaml_content)
      
      # Force reload of credentials in Rails
      if environment.to_s == 'credentials'
        # Clear the memoized main credentials
        Rails.application.instance_variable_set(:@credentials, nil)
      end
      
      Rails.logger.info "[BetterRailsSecretsManager] Successfully wrote credentials"
      true
    rescue => e
      Rails.logger.error "[BetterRailsSecretsManager] Write error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      false
    end
    
    private
    
    def self.read_main_credentials
      # Try multiple methods to get main credentials
      
      # Method 1: Direct Rails.application.credentials
      if defined?(Rails.application.credentials)
        creds = Rails.application.credentials
        
        # Try to get the hash representation
        if creds.respond_to?(:to_h)
          return creds.to_h
        elsif creds.respond_to?(:config)
          config = creds.config
          return config.to_h if config.respond_to?(:to_h)
          return config if config.is_a?(Hash)
        end
      end
      
      # Method 2: Manual reading from credentials.yml.enc
      read_manual_credentials('credentials')
    end
    
    def self.read_environment_credentials(environment)
      # Try Rails environment-specific credentials
      if Rails.application.respond_to?(:credentials)
        begin
          env_creds = Rails.application.credentials(environment: environment.to_sym)
          if env_creds && env_creds.respond_to?(:config)
            config = env_creds.config
            return config.to_h if config.respond_to?(:to_h)
            return config if config.is_a?(Hash)
          end
        rescue
          # Fall through to manual reading
        end
      end
      
      # Fallback to manual reading
      read_manual_credentials(environment)
    end
    
    def self.read_manual_credentials(environment)
      credentials_path = credentials_path_for(environment)
      key_path = key_path_for(environment)
      
      return {} unless File.exist?(credentials_path) && File.exist?(key_path)
      
      config = ActiveSupport::EncryptedConfiguration.new(
        config_path: credentials_path,
        key_path: key_path,
        env_key: env_key_for(environment),
        raise_if_missing_key: false
      )
      
      content = config.read
      
      if content.is_a?(String)
        # Parse YAML content
        YAML.safe_load(content, permitted_classes: [Symbol], aliases: true) || {}
      elsif content.is_a?(Hash)
        content
      else
        {}
      end
    end
    
    def self.credentials_path_for(environment)
      # "credentials" refers to the main credentials.yml.enc file ONLY
      if environment.to_s == 'credentials'
        Rails.root.join('config', 'credentials.yml.enc')
      else
        # ALL other environments (including production) use config/credentials/[environment].yml.enc
        Rails.root.join('config', 'credentials', "#{environment}.yml.enc")
      end
    end
    
    def self.key_path_for(environment)
      # "credentials" uses the master.key
      if environment.to_s == 'credentials'
        Rails.root.join('config', 'master.key')
      else
        # ALL other environments (including production) use config/credentials/[environment].key
        Rails.root.join('config', 'credentials', "#{environment}.key")
      end
    end
    
    def self.env_key_for(environment)
      # "credentials" uses RAILS_MASTER_KEY
      if environment.to_s == 'credentials'
        'RAILS_MASTER_KEY'
      else
        # ALL other environments use RAILS_[ENVIRONMENT]_KEY
        "RAILS_#{environment.to_s.upcase}_KEY"
      end
    end
  end
end