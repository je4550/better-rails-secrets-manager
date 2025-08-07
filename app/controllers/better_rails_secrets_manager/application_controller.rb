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
      session[:current_environment] || 'development'
    end
    
    def secrets_manager
      @secrets_manager ||= BetterRailsSecretsManager::SecretsManager.new
    end
  end
end