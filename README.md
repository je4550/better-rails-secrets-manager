# Better Rails Secrets Manager 🔐

A beautiful web interface for managing Rails secrets and credentials across ALL environments. Edit development, staging, AND production secrets through an intuitive UI - no more wrestling with terminal editors!

## 🔒 Security Model

- **Development Environment Only**: The web interface only loads when Rails.env.development? is true
- **Key-Based Access**: If you have the encryption keys, you have access to the secrets
- **No Additional Authentication**: No password needed - having the keys IS the authentication
- **Rails Native Security**: Uses Rails' built-in encryption system for all operations

## ✨ Features

- **Beautiful Web Interface**: Modern, responsive UI built with Tailwind CSS
- **ALL Environments**: Edit development, test, staging, AND production secrets from one interface
- **Visual Secret Editor**: Syntax-highlighted YAML editor with validation
- **Environment Switching**: Easily switch between any environment with one click
- **Import/Export**: Backup and restore secrets in JSON format
- **Rails Native**: Works seamlessly with Rails' built-in credentials system
- **Custom Environments**: Add unlimited custom environments for your specific needs
- **Secure by Design**: Only accessible in development environment with proper keys

## 📦 Installation

Add this gem to your Rails application's Gemfile:

```ruby
group :development do
  gem 'better_rails_secrets_manager'
end
```

Then execute:

```bash
$ bundle install
```

Run the installation generator:

```bash
$ rails generate better_rails_secrets_manager:install
```

This will:
- Mount the engine at `/secrets` (development only)
- Create an initializer for configuration

## 🚀 Quick Start

1. Start your Rails server in development:
   ```bash
   rails server
   ```

2. Visit http://localhost:3000/secrets

3. Edit secrets for ANY environment (dev, staging, production) - as long as you have the encryption keys!

## 🎨 Features in Detail

### Environment Management
- **Default Environments**: development, test, staging, production
- **Custom Environments**: Add any custom environment your project needs
- **One-Click Switching**: Switch between environments instantly
- **Environment Removal**: Remove custom environments when no longer needed

### Secret Editing
- **Visual Editor**: Modern code editor with YAML syntax highlighting
- **Real-time Validation**: Validates YAML as you type
- **Format Button**: Auto-format your YAML with proper indentation
- **Nested Secrets**: Full support for complex nested structures
- **Masked Values**: Sensitive values are masked in the view mode

### Import/Export
- **JSON Export**: Export secrets to JSON for backup or sharing
- **Timestamped Exports**: Each export includes timestamp for versioning
- **Easy Import**: Import secrets from JSON files with validation
- **Environment-Specific**: Import/export is per-environment

### Developer Experience
- **Single Interface**: Edit ALL environments from one place
- **No Password Hassle**: If you have the keys, you're in
- **No External Dependencies**: Everything runs locally
- **Rails Integration**: Works with your existing Rails credentials
- **Key Management**: Automatically manages encryption keys

## 🔧 Configuration

Configure in `config/initializers/better_rails_secrets_manager.rb`:

```ruby
BetterRailsSecretsManager.configure do |config|
  # No authentication needed - if you have the keys, you have access
  config.authentication_enabled = false
  
  # Configure allowed environments for your project
  config.allowed_environments = %w[development test staging production custom]
end
```

### Required Keys

To edit secrets for each environment, you need:
- **Production**: `config/master.key`
- **Other environments**: `config/credentials/[environment].key`

If you don't have a key for an environment, you won't be able to decrypt/edit its secrets.

## 📁 How It Works

The gem works with Rails' native credentials system:

- **Development**: `config/credentials/development.yml.enc`
- **Test**: `config/credentials/test.yml.enc`
- **Staging**: `config/credentials/staging.yml.enc`
- **Production**: `config/credentials.yml.enc`
- **Custom**: `config/credentials/[name].yml.enc`

Each environment has its own encryption key:
- `config/credentials/[environment].key`
- Production uses `config/master.key`

## 🖼️ UI Overview

The interface includes:

1. **Sidebar**
   - Environment list with active indicator
   - Add new environment form
   - Quick environment switcher

2. **Main Panel**
   - Current secrets display (masked values)
   - Edit button for modification
   - Visual tree structure for nested secrets

3. **Import/Export Section**
   - Export current environment to JSON
   - Import from JSON file
   - Maintains backup history

4. **Editor View**
   - Syntax-highlighted YAML editor
   - Format and validate buttons
   - Save and cancel actions

## 🔐 Security Architecture

### Why Development Environment Only?

The web interface only loads when `Rails.env.development?` is true. This provides:

1. **Reduced Attack Surface**: The UI doesn't exist in production servers
2. **Development Workflow**: Use locally to manage ALL environments
3. **Key-Based Security**: You can only decrypt environments you have keys for
4. **Simplified Access**: No additional passwords - keys are the authentication
5. **No Network Exposure**: Typically only accessible on localhost

### Managing Production Secrets

From your development machine, you can safely edit production secrets:

1. Ensure you have the production master key locally
2. Start the Rails app in development mode
3. Login with your password
4. Switch to "production" environment in the UI
5. Edit and save (changes are encrypted with the production key)

The production servers never expose the web interface, but you can manage their secrets from your secure development environment.

## 🐛 Troubleshooting

### Can't access `/secrets`?
- Ensure you're running in development mode (`Rails.env.development?` must be true)
- Check if the route is mounted: `rails routes | grep secrets`
- Restart your Rails server after installation

### Secrets not saving?
- Check file permissions on `config/credentials/` directory
- Ensure the key file exists for the environment you're editing
- For production: ensure `config/master.key` is present
- For other environments: ensure `config/credentials/[env].key` exists
- Check Rails logs for detailed error messages

### Environment not showing?
- Verify the environment name is valid (alphanumeric and underscores)
- Check if credentials file was created successfully
- Try restarting the Rails server

## 🤝 Contributing

We welcome contributions! This project aims to make Rails development more enjoyable.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

The gem is available as open source under the terms of the MIT License.

## 🙏 Acknowledgments

Built with ❤️ for the Rails community. Making development easier, one tool at a time!