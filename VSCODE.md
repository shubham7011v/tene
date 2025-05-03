# VSCode Setup for Tene Flutter App

This document provides instructions on how to use VSCode effectively with the Tene multi-environment setup.

## Recommended Extensions

VSCode will automatically recommend the following extensions when you open this project:

- **Dart** and **Flutter** - Essential for Flutter development
- **DotENV** - Syntax highlighting for .env files
- **YAML** - For YAML file support
- **Code Spell Checker** - To catch typos in code
- **Todo Tree** - Highlights and lists TODO comments
- **Better Comments** - Improves comment formatting
- **Flutter Riverpod Snippets** - Snippets for Riverpod usage

## Launch Configurations

The project includes the following launch configurations:

1. **Tene (Development)** - Run the app in development mode (--dart-define=ENV=dev)
2. **Tene (Production)** - Run the app in production mode (--dart-define=ENV=prod)
3. **Tene (Profile Mode - Dev)** - Run the app in profile mode with development configuration
4. **Tene (Profile Mode - Prod)** - Run the app in profile mode with production configuration
5. **Tene (Release Mode - Dev)** - Run the app in release mode with development configuration
6. **Tene (Release Mode - Prod)** - Run the app in release mode with production configuration

To use these configurations:
1. Open the Run and Debug view in VSCode (Ctrl+Shift+D or Cmd+Shift+D)
2. Select a configuration from the dropdown
3. Click the green play button or press F5

## Tasks

Custom tasks are available to streamline your workflow:

1. **Flutter: Run (Development)** - Run the app in development mode
2. **Flutter: Run (Production)** - Run the app in production mode
3. **Flutter: Clean Project** - Clean the Flutter project
4. **Flutter: Get Packages** - Get pub dependencies

To run a task:
1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type "Tasks: Run Task"
3. Select the desired task

## Settings

The project includes VSCode settings optimized for Flutter development:

- Format on save enabled
- Line length set to 100 characters
- Flutter UI guides enabled
- File associations for .env files
- Excluded irrelevant files from the explorer

## Environment Files

The VSCode configuration is set up to properly highlight and recognize the environment files:

- `.env.dev` - Development environment variables
- `.env.prod` - Production environment variables

## Multi-Environment Development

When working on features that need to be tested in both environments:

1. Use the "Tene (Development)" configuration for day-to-day development
2. Switch to "Tene (Production)" to verify that everything works in the production environment

For more details about the environments themselves, refer to `ENVIRONMENT.md`. 