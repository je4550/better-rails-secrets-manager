require 'rails/generators/base'

module BetterRailsSecretsManager
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      desc "Install BetterRailsSecretsManager and mount the engine"
      
      def add_route
        route_string = <<-ROUTES
  
  # Rails Secrets Manager UI (Development Only for security)
  mount BetterRailsSecretsManager::Engine => "/secrets" if Rails.env.development?
        ROUTES
        
        route route_string
      end
      
      def create_initializer
        create_file "config/initializers/better_rails_secrets_manager.rb", <<-RUBY
BetterRailsSecretsManager.configure do |config|
  # No authentication needed - if you have the keys, you have access
  config.authentication_enabled = false
  
  # Configure allowed environments for your project
  # You can edit ANY environment's secrets if you have the encryption keys
  # config.allowed_environments = %w[development test staging production custom]
end

# This interface only loads in development environment for security.
# You can edit any environment's secrets as long as you have the encryption keys:
# - config/master.key for production
# - config/credentials/[environment].key for other environments
        RUBY
      end
      
      def show_instructions
        say "\n", :green
        say "=" * 60, :green
        say "BetterRailsSecretsManager has been installed!", :green
        say "=" * 60, :green
        say "\n"
        say "Next steps:", :yellow
        say "\n"
        say "1. Start your Rails server in development:", :yellow
        say "   rails server", :cyan
        say "\n"
        say "2. Visit the secrets manager:", :yellow
        say "   http://localhost:3000/secrets", :cyan
        say "\n"
        say "Features:", :yellow
        say "• The UI only loads in development environment", :green
        say "• You can edit ANY environment's secrets (dev, staging, prod)", :green
        say "• You need the encryption keys for each environment", :green
        say "• No password needed - key access = secret access", :green
        say "\n"
      end
    end
  end
end