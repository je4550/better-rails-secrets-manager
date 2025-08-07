# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module BetterRailsSecretsManager
  class SecretsManager
    attr_reader :rails_root

    def initialize(rails_root = Rails.root)
      @rails_root = rails_root
    end

    def available_environments
      environments = %w[development test staging production]
      
      Dir.glob(rails_root.join("config", "credentials", "*.yml.enc")).each do |file|
        env = File.basename(file, ".yml.enc")
        environments << env unless environments.include?(env)
      end
      
      environments.uniq.sort
    end

    def read_secrets(environment)
      credentials_path = credentials_path_for(environment)
      key_path = key_path_for(environment)
      
      if File.exist?(credentials_path) && File.exist?(key_path)
        decrypt_credentials(credentials_path, key_path)
      else
        {}
      end
    rescue => e
      Rails.logger.error "Failed to read secrets for #{environment}: #{e.message}"
      {}
    end

    def write_secrets(environment, secrets_hash)
      credentials_path = credentials_path_for(environment)
      key_path = key_path_for(environment)
      
      ensure_credentials_directory
      ensure_key_file(key_path)
      
      encrypt_credentials(credentials_path, key_path, secrets_hash)
      true
    rescue => e
      Rails.logger.error "Failed to write secrets for #{environment}: #{e.message}"
      false
    end

    def add_environment(environment_name)
      return false if environment_name.blank?
      
      environment_name = environment_name.downcase.gsub(/[^a-z0-9_]/, '_')
      key_path = key_path_for(environment_name)
      
      unless File.exist?(key_path)
        ensure_key_file(key_path)
        write_secrets(environment_name, {})
        true
      else
        false
      end
    end

    def remove_environment(environment_name)
      return false if %w[development test staging production].include?(environment_name)
      
      credentials_path = credentials_path_for(environment_name)
      key_path = key_path_for(environment_name)
      
      File.delete(credentials_path) if File.exist?(credentials_path)
      File.delete(key_path) if File.exist?(key_path)
      
      true
    rescue => e
      Rails.logger.error "Failed to remove environment #{environment_name}: #{e.message}"
      false
    end

    def export_secrets(environment)
      secrets = read_secrets(environment)
      {
        environment: environment,
        timestamp: Time.current.iso8601,
        secrets: secrets
      }.to_json
    end

    def import_secrets(environment, json_data)
      data = JSON.parse(json_data)
      secrets = data['secrets'] || data
      write_secrets(environment, secrets.deep_symbolize_keys)
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse import data: #{e.message}"
      false
    end

    private

    def credentials_path_for(environment)
      if environment == 'production'
        rails_root.join("config", "credentials.yml.enc")
      else
        rails_root.join("config", "credentials", "#{environment}.yml.enc")
      end
    end

    def key_path_for(environment)
      if environment == 'production'
        rails_root.join("config", "master.key")
      else
        rails_root.join("config", "credentials", "#{environment}.key")
      end
    end

    def ensure_credentials_directory
      dir = rails_root.join("config", "credentials")
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end

    def ensure_key_file(key_path)
      unless File.exist?(key_path)
        key = SecureRandom.hex(32)
        File.write(key_path, key)
        File.chmod(0600, key_path)
      end
    end

    def decrypt_credentials(credentials_path, key_path)
      key = File.read(key_path).strip
      encrypted_data = File.binread(credentials_path)
      
      credentials = ActiveSupport::EncryptedConfiguration.new(
        config_path: credentials_path,
        key_path: key_path,
        env_key: "RAILS_MASTER_KEY",
        raise_if_missing_key: true
      )
      
      credentials.read || {}
    end

    def encrypt_credentials(credentials_path, key_path, secrets_hash)
      credentials = ActiveSupport::EncryptedConfiguration.new(
        config_path: credentials_path,
        key_path: key_path,
        env_key: "RAILS_MASTER_KEY",
        raise_if_missing_key: true
      )
      
      credentials.write(secrets_hash.to_yaml)
    end
  end
end