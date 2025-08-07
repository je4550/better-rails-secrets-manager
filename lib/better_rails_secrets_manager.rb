# frozen_string_literal: true

require_relative "better_rails_secrets_manager/version"
require_relative "better_rails_secrets_manager/engine" if defined?(Rails::Engine)
require_relative "better_rails_secrets_manager/secrets_manager"
require_relative "better_rails_secrets_manager/credentials_adapter"
require_relative "better_rails_secrets_manager/simple_credentials_reader"
require_relative "better_rails_secrets_manager/file_based_credentials"

module BetterRailsSecretsManager
  class Error < StandardError; end
  
  mattr_accessor :authentication_enabled
  @@authentication_enabled = false  # No auth needed - if you have keys, you have access
  
  mattr_accessor :allowed_environments
  @@allowed_environments = %w[development staging production]
  
  def self.configure
    yield self
  end
end
