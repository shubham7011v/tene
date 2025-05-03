# Git Setup for Multi-Environment Flutter Project

This document explains how the Git configuration is set up for this multi-environment Flutter project.

## .gitignore Configuration

The `.gitignore` file has been configured to support the multi-environment setup:

### Environment Files

- `.env` files are generally ignored to prevent secrets from being committed
- `.env.dev` and `.env.prod` are tracked in version control but should only contain placeholders
- `.env.example` is tracked and serves as a template for creating environment files

### Firebase Configuration

- Firebase configuration files (`firebase_options_dev.dart` and `firebase_options_prod.dart`) are tracked in version control
- These files contain environment-specific Firebase configurations that should be shared across the team
- **Important**: Ensure that these files do not contain sensitive information that should be kept secret

## Best Practices

### Environment Variables

1. **Never commit real secrets** in any tracked file
2. When adding a new environment variable:
   - Add it to `.env.example` with a placeholder value
   - Add it to `.env.dev` and `.env.prod` with placeholder values for version control
   - Add the real values to your local untracked `.env` file

### Firebase Configuration

1. The Firebase configuration files contain API keys, but these are generally safe to commit as they require additional authentication to use
2. However, be cautious with any sensitive information and follow Firebase security best practices
3. Consider obfuscating the configuration in production builds

## Initial Setup for New Team Members

When a new developer joins the project:

1. Clone the repository
2. Copy `.env.example` to `.env.dev` and `.env.prod`
3. Fill in the actual values in each environment file based on the environment
4. Run the app using the appropriate environment: `flutter run --dart-define=ENV=dev` or `flutter run --dart-define=ENV=prod`

## Version Control Workflow

When making changes:

1. Add new environment variables to `.env.example` first
2. Add placeholder values to `.env.dev` and `.env.prod` (that will be tracked)
3. Commit these changes
4. Each developer updates their local untracked `.env` file with real values 