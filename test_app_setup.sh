#!/bin/bash

echo "Setting up test Rails app for Better Rails Secrets Manager"
echo "==========================================================="

# Create a new Rails app for testing
echo "1. Creating test Rails app..."
rails new test_secrets_app --skip-git --skip-bundle

cd test_secrets_app

# Add the gem to Gemfile
echo "2. Adding gem to Gemfile..."
echo "gem 'better_rails_secrets_manager', path: '../'" >> Gemfile

# Bundle install
echo "3. Installing dependencies..."
bundle install

# Run the generator
echo "4. Running the installation generator..."
rails generate better_rails_secrets_manager:install

# Create some sample credentials for different environments
echo "5. Setting up sample credentials..."

# Create credentials directory
mkdir -p config/credentials

# Generate keys for different environments
echo "Generating encryption keys..."
echo "$(openssl rand -hex 32)" > config/credentials/development.key
echo "$(openssl rand -hex 32)" > config/credentials/staging.key
echo "$(openssl rand -hex 32)" > config/master.key

# Set proper permissions
chmod 600 config/credentials/*.key
chmod 600 config/master.key

echo ""
echo "✅ Setup complete!"
echo ""
echo "To test the gem:"
echo "1. cd test_secrets_app"
echo "2. rails server"
echo "3. Visit http://localhost:3000/secrets"
echo ""
echo "You can now:"
echo "- Switch between environments (development, staging, production)"
echo "- Add/edit secrets for each environment"
echo "- Import/export secrets as JSON"
echo "- Add custom environments"