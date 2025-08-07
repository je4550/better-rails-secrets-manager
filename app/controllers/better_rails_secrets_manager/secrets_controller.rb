module BetterRailsSecretsManager
  class SecretsController < ApplicationController
    def index
      @environments = secrets_manager.available_environments
      @current_secrets = secrets_manager.read_secrets(current_environment)
    end
    
    def edit
      @current_secrets = secrets_manager.read_secrets(current_environment)
      @formatted_secrets = format_secrets_for_editing(@current_secrets)
    end
    
    def update
      secrets_hash = parse_secrets_from_params(params[:secrets])
      
      if secrets_manager.write_secrets(current_environment, secrets_hash)
        redirect_to secrets_path, notice: "Secrets updated successfully for #{current_environment}"
      else
        redirect_to edit_secrets_path, alert: "Failed to update secrets"
      end
    end
    
    def switch_environment
      environment = params[:environment]
      
      if secrets_manager.available_environments.include?(environment)
        session[:current_environment] = environment
        redirect_to secrets_path, notice: "Switched to #{environment} environment"
      else
        redirect_to secrets_path, alert: "Invalid environment"
      end
    end
    
    def add_environment
      environment_name = params[:environment_name]
      
      if secrets_manager.add_environment(environment_name)
        redirect_to secrets_path, notice: "Environment '#{environment_name}' added successfully"
      else
        redirect_to secrets_path, alert: "Failed to add environment or it already exists"
      end
    end
    
    def remove_environment
      environment = params[:environment]
      
      if secrets_manager.remove_environment(environment)
        session[:current_environment] = 'development' if current_environment == environment
        redirect_to secrets_path, notice: "Environment '#{environment}' removed successfully"
      else
        redirect_to secrets_path, alert: "Cannot remove this environment"
      end
    end
    
    def export
      json_data = secrets_manager.export_secrets(current_environment)
      
      send_data json_data,
                filename: "#{current_environment}_secrets_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json",
                type: 'application/json'
    end
    
    def import
      file = params[:import_file]
      
      if file && file.respond_to?(:read)
        json_data = file.read
        
        if secrets_manager.import_secrets(current_environment, json_data)
          redirect_to secrets_path, notice: "Secrets imported successfully"
        else
          redirect_to secrets_path, alert: "Failed to import secrets. Please check the file format."
        end
      else
        redirect_to secrets_path, alert: "Please select a file to import"
      end
    end
    
    private
    
    def format_secrets_for_editing(secrets_hash)
      YAML.dump(secrets_hash).gsub(/^---\n/, '')
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