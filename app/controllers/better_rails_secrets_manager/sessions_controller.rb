module BetterRailsSecretsManager
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:new, :create]
    
    def new
    end
    
    def create
      password = params[:password]
      
      if authenticate_with_password(password)
        session[:authenticated] = true
        redirect_to secrets_path, notice: "Successfully authenticated"
      else
        redirect_to new_session_path, alert: "Invalid password"
      end
    end
    
    def destroy
      session[:authenticated] = false
      redirect_to new_session_path, notice: "Logged out successfully"
    end
    
    private
    
    def authenticate_with_password(password)
      return true unless BetterRailsSecretsManager.authentication_enabled
      
      stored_password = ENV['SECRETS_MANAGER_PASSWORD'] || Rails.application.credentials.secrets_manager_password
      
      return false if stored_password.blank?
      
      if stored_password.start_with?('$2')
        BCrypt::Password.new(stored_password) == password
      else
        password == stored_password
      end
    end
  end
end