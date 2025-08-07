module BetterRailsSecretsManager
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :authenticate_user!, if: :authentication_enabled?
    
    helper_method :current_environment
    
    private
    
    def authentication_enabled?
      BetterRailsSecretsManager.authentication_enabled
    end
    
    def authenticate_user!
      unless session[:authenticated]
        redirect_to new_session_path, alert: "Please authenticate to continue"
      end
    end
    
    def current_environment
      # Default to 'credentials' (main file) or the first available environment
      session[:current_environment] || default_environment
    end
    
    def default_environment
      # Check what credential files exist and return the first one
      if File.exist?(Rails.root.join('config', 'credentials.yml.enc'))
        'credentials'
      elsif Dir.glob(Rails.root.join('config', 'credentials', '*.yml.enc')).any?
        File.basename(Dir.glob(Rails.root.join('config', 'credentials', '*.yml.enc')).first, '.yml.enc')
      else
        'credentials' # fallback
      end
    end
    
    def secrets_manager
      @secrets_manager ||= BetterRailsSecretsManager::SecretsManager.new
    end
  end
end