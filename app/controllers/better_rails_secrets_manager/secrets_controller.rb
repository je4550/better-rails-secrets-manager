require 'json'

module BetterRailsSecretsManager
  class SecretsController < ApplicationController
    def index
      @environments = available_environments
      @current_secrets = read_current_secrets
      
      # Debug logging
      Rails.logger.info "BetterRailsSecretsManager: Current environment: #{current_environment}"
      Rails.logger.info "BetterRailsSecretsManager: Available environments: #{@environments.inspect}"
      Rails.logger.info "BetterRailsSecretsManager: Secrets loaded: #{@current_secrets.any? ? 'Yes' : 'No'}"
    end
    
    def edit
      @current_secrets = read_current_secrets
      @formatted_secrets = format_secrets_for_editing(@current_secrets)
    end
    
    def update
      Rails.logger.info "[BetterRailsSecretsManager] Update called for environment: #{current_environment}"
      Rails.logger.info "[BetterRailsSecretsManager] Raw params[:secrets]: #{params[:secrets].inspect[0..500]}"
      
      secrets_hash = parse_secrets_from_params(params[:secrets])
      
      Rails.logger.info "[BetterRailsSecretsManager] Parsed secrets hash keys: #{secrets_hash.keys.inspect}"
      
      if FileBasedCredentials.write(current_environment, secrets_hash)
        redirect_to root_path, notice: "Secrets updated successfully for #{current_environment}"
      else
        redirect_to edit_path, alert: "Failed to update secrets - check Rails logs for details"
      end
    end
    
    def switch_environment
      environment = params[:environment]
      
      if available_environments.include?(environment)
        session[:current_environment] = environment
        redirect_to root_path, notice: "Switched to #{environment} environment"
      else
        redirect_to root_path, alert: "Invalid environment"
      end
    end
    
    def add_environment
      environment_name = params[:environment_name]
      
      # For now, just inform the user they need to create the files manually
      redirect_to root_path, alert: "To add a new environment, create the credential files manually: rails credentials:edit --environment #{environment_name}"
    end
    
    def remove_environment
      environment = params[:environment]
      
      # Don't allow removing the main credentials file
      if environment == 'credentials'
        redirect_to root_path, alert: "Cannot remove the main credentials file"
      else
        # For security, don't actually delete files through the web UI
        redirect_to root_path, alert: "For security, please remove credential files manually from the command line"
      end
    end
    
    def export
      secrets = FileBasedCredentials.read(current_environment)
      
      json_data = {
        environment: current_environment,
        timestamp: Time.current.iso8601,
        secrets: secrets
      }.to_json
      
      send_data json_data,
                filename: "#{current_environment}_secrets_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json",
                type: 'application/json'
    end
    
    def import
      file = params[:import_file]
      
      if file && file.respond_to?(:read)
        begin
          json_data = file.read
          data = JSON.parse(json_data)
          secrets = data['secrets'] || data
          
          if FileBasedCredentials.write(current_environment, secrets)
            redirect_to root_path, notice: "Secrets imported successfully"
          else
            redirect_to root_path, alert: "Failed to import secrets. Please check the file format."
          end
        rescue JSON::ParserError => e
          redirect_to root_path, alert: "Invalid JSON file: #{e.message}"
        end
      else
        redirect_to root_path, alert: "Please select a file to import"
      end
    end
    
    private
    
    def available_environments
      FileBasedCredentials.list_available
    end
    
    def read_current_secrets
      FileBasedCredentials.read(current_environment)
    end
    
    def format_secrets_for_editing(secrets_hash)
      return "" if secrets_hash.blank?
      
      # Clean up the hash - remove empty OrderedOptions
      cleaned_hash = clean_for_yaml(secrets_hash)
      
      # Convert to YAML and remove the document separator
      yaml_content = YAML.dump(cleaned_hash)
      yaml_content.gsub(/^---\n/, '')
    end
    
    def clean_for_yaml(obj)
      case obj
      when Hash
        result = {}
        obj.each do |key, value|
          cleaned_value = clean_for_yaml(value)
          # Only include non-empty values
          if cleaned_value != {} && cleaned_value != nil && cleaned_value != ""
            result[key] = cleaned_value
          elsif value.is_a?(Hash) || value.is_a?(ActiveSupport::OrderedOptions)
            # Keep empty hashes as placeholders for sections
            result[key] = {}
          else
            result[key] = cleaned_value
          end
        end
        result
      when Array
        obj.map { |item| clean_for_yaml(item) }
      else
        obj
      end
    end
    
    def parse_secrets_from_params(secrets_string)
      return {} if secrets_string.blank?
      
      YAML.safe_load(secrets_string, permitted_classes: [Symbol, Date, Time], aliases: true) || {}
    rescue Psych::SyntaxError => e
      Rails.logger.error "Failed to parse YAML: #{e.message}"
      {}
    end
  end
end