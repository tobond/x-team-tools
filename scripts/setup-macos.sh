#!/bin/bash

# macOS Development Environment Setup Script
# This script installs all required tools for the Tilt-based development environment

set -e

echo "🚀 Setting up development environment for macOS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    print_status "Homebrew already installed"
fi

# Update Homebrew
print_status "Updating Homebrew..."
brew update

# Install Docker Desktop
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker Desktop..."
    brew install --cask docker
    print_warning "Please start Docker Desktop manually and enable Kubernetes in Settings"
else
    print_status "Docker already installed"
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    print_status "Installing kubectl..."
    brew install kubectl
else
    print_status "kubectl already installed"
fi

# Install Tilt
if ! command -v tilt &> /dev/null; then
    print_status "Installing Tilt..."
    brew install tilt
else
    print_status "Tilt already installed"
fi

# Install kind (optional, lightweight Kubernetes)
if ! command -v kind &> /dev/null; then
    print_status "Installing kind (optional Kubernetes cluster)..."
    brew install kind
else
    print_status "kind already installed"
fi

# Install k3d (optional, another lightweight Kubernetes)
if ! command -v k3d &> /dev/null; then
    print_status "Installing k3d (optional Kubernetes cluster)..."
    brew install k3d
else
    print_status "k3d already installed"
fi

# Install jq for JSON processing
if ! command -v jq &> /dev/null; then
    print_status "Installing jq..."
    brew install jq
else
    print_status "jq already installed"
fi

# Install yq for YAML processing
if ! command -v yq &> /dev/null; then
    print_status "Installing yq..."
    brew install yq
else
    print_status "yq already installed"
fi

# Create developer configuration from template
if [ ! -f ".tilt/developer-config.yaml" ]; then
    if [ -f ".tilt/developer-config.yaml.template" ]; then
        print_status "Creating developer configuration..."
        cp .tilt/developer-config.yaml.template .tilt/developer-config.yaml
        
        # Get current user and set as developer ID
        CURRENT_USER=$(whoami)
        sed -i '' "s/your-name/$CURRENT_USER/g" .tilt/developer-config.yaml
        
        print_warning "Please edit .tilt/developer-config.yaml to customize your settings"
    else
        print_warning "Developer configuration template not found"
    fi
else
    print_status "Developer configuration already exists"
fi

# Verify installations
print_status "Verifying installations..."

echo "Checking Docker..."
if docker --version &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    print_error "❌ Docker installation failed"
fi

echo "Checking kubectl..."
if kubectl version --client &> /dev/null; then
    echo "✅ kubectl: $(kubectl version --client --short)"
else
    print_error "❌ kubectl installation failed"
fi

echo "Checking Tilt..."
if tilt version &> /dev/null; then
    echo "✅ Tilt: $(tilt version)"
else
    print_error "❌ Tilt installation failed"
fi

echo "Checking kind..."
if kind version &> /dev/null; then
    echo "✅ kind: $(kind version)"
else
    print_warning "⚠️  kind not available"
fi

echo "Checking k3d..."
if k3d version &> /dev/null; then
    echo "✅ k3d: $(k3d version)"
else
    print_warning "⚠️  k3d not available"
fi

print_status "Setup complete! 🎉"
echo ""
echo "Next steps:"
echo "1. Start Docker Desktop and enable Kubernetes in Settings"
echo "2. Edit .tilt/developer-config.yaml to customize your settings"
echo "3. Run 'tilt up' to start your development environment"
echo "4. Open http://localhost:10350 to view the Tilt UI"
echo ""
echo "For more information, see DEVELOPER_ONBOARDING.md"