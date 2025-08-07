# frozen_string_literal: true

module BetterRailsSecretsManager
  class Engine < ::Rails::Engine
    isolate_namespace BetterRailsSecretsManager

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "better_rails_secrets_manager.assets" do |app|
      app.config.assets.precompile += %w[better_rails_secrets_manager/application.js better_rails_secrets_manager/application.css]
    end

    initializer "better_rails_secrets_manager.importmap", before: "importmap" do |app|
      app.config.importmap.paths << Engine.root.join("config/importmap.rb") if app.config.respond_to?(:importmap)
    end
  end
end