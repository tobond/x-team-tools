#!/bin/bash

# Setup Tilt Extensions for x-team-tools Development Environment
# This script automatically installs all required Tilt extensions for the development environment

set -e

echo "🔧 Setting up Tilt extensions for x-team-tools development environment..."
echo

# Check if Tilt is installed
if ! command -v tilt &> /dev/null; then
    echo "❌ Error: Tilt is not installed or not in PATH"
    echo "Please install Tilt first: https://docs.tilt.dev/install.html"
    exit 1
fi

echo "✅ Tilt is installed: $(tilt version)"
echo

# List of required extensions
EXTENSIONS=(
    "namespace"
    "configmap"
    "secret"
)

echo "📦 Installing required Tilt extensions..."
echo

# Install each extension
for extension in "${EXTENSIONS[@]}"; do
    echo "Installing extension: $extension"
    if tilt extension install "$extension"; then
        echo "✅ Successfully installed: $extension"
    else
        echo "❌ Failed to install: $extension"
        exit 1
    fi
    echo
done

echo "🎉 All Tilt extensions installed successfully!"
echo
echo "📋 Installed extensions:"
tilt extension list
echo
echo "💡 You can now run 'tilt up' to start the development environment"
echo "🌐 Tilt UI will be available at: http://localhost:10350"
