# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module BetterRailsSecretsManager
  class FileBasedCredentials
    def self.read(file_identifier)
      Rails.logger.info "[BetterRailsSecretsManager] Reading: #{file_identifier}"
      
      credentials_path = credentials_path_for(file_identifier)
      key_path = key_path_for(file_identifier)
      
      Rails.logger.info "[BetterRailsSecretsManager] Path: #{credentials_path}"
      Rails.logger.info "[BetterRailsSecretsManager] Key: #{key_path}"
      
      return {} unless File.exist?(credentials_path) && File.exist?(key_path)
      
      config = ActiveSupport::EncryptedConfiguration.new(
        config_path: credentials_path,
        key_path: key_path,
        env_key: env_key_for(file_identifier),
        raise_if_missing_key: false
      )
      
      content = config.read
      
      if content.is_a?(String)
        YAML.safe_load(content, permitted_classes: [Symbol], aliases: true) || {}
      elsif content.is_a?(Hash)
        content
      else
        {}
      end
    rescue => e
      Rails.logger.error "[BetterRailsSecretsManager] Error reading #{file_identifier}: #{e.message}"
      {}
    end
    
    def self.write(file_identifier, secrets_hash)
      Rails.logger.info "[BetterRailsSecretsManager] Writing: #{file_identifier}"
      
      credentials_path = credentials_path_for(file_identifier)
      key_path = key_path_for(file_identifier)
      
      unless File.exist?(key_path)
        Rails.logger.error "[BetterRailsSecretsManager] Key not found: #{key_path}"
        return false
      end
      
      FileUtils.mkdir_p(File.dirname(credentials_path))
      
      config = ActiveSupport::EncryptedConfiguration.new(
        config_path: credentials_path,
        key_path: key_path,
        env_key: env_key_for(file_identifier),
        raise_if_missing_key: false
      )
      
      yaml_content = secrets_hash.deep_stringify_keys.to_yaml
      yaml_content = yaml_content.sub(/\A---\n/, '') if yaml_content.start_with?("---\n")
      
      config.write(yaml_content)
      
      # Clear Rails credential cache
      Rails.application.instance_variable_set(:@credentials, nil)
      
      Rails.logger.info "[BetterRailsSecretsManager] Successfully wrote #{file_identifier}"
      true
    rescue => e
      Rails.logger.error "[BetterRailsSecretsManager] Write error: #{e.message}"
      false
    end
    
    def self.list_available
      files = []
      
      # Check for main credentials.yml.enc
      if File.exist?(Rails.root.join('config', 'credentials.yml.enc'))
        files << 'credentials'
      end
      
      # Check for environment-specific files
      Dir.glob(Rails.root.join('config', 'credentials', '*.yml.enc')).each do |file|
        files << File.basename(file, '.yml.enc')
      end
      
      files.uniq.sort
    end
    
    private
    
    def self.credentials_path_for(file_identifier)
      if file_identifier == 'credentials'
        # Main credentials file
        Rails.root.join('config', 'credentials.yml.enc')
      else
        # Environment-specific file
        Rails.root.join('config', 'credentials', "#{file_identifier}.yml.enc")
      end
    end
    
    def self.key_path_for(file_identifier)
      if file_identifier == 'credentials'
        # Main credentials uses master.key
        Rails.root.join('config', 'master.key')
      else
        # Environment-specific uses its own key
        Rails.root.join('config', 'credentials', "#{file_identifier}.key")
      end
    end
    
    def self.env_key_for(file_identifier)
      if file_identifier == 'credentials'
        'RAILS_MASTER_KEY'
      else
        "RAILS_#{file_identifier.upcase}_KEY"
      end
    end
  end
end