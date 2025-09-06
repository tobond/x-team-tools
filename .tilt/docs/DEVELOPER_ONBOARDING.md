# Developer Onboarding Guide

## Quick Start

Welcome to the x-team-tools development environment! This guide will get you up and running with our Tilt-based local Kubernetes development environment in under 10 minutes.

### Prerequisites

Before you begin, ensure you have the following installed:

- **Docker Desktop** (or Docker Engine + kind/k3d)
- **kubectl** (Kubernetes CLI)
- **Tilt** (v0.30.0 or later)
- **Git**

### Installation Scripts

We provide an automated setup script for macOS:

```bash
# macOS (using Homebrew)
./scripts/setup-macos.sh
```

### Manual Installation

If you prefer manual installation:

#### 1. Install Docker Desktop
Download from [Docker Desktop for Mac](https://docs.docker.com/desktop/mac/install/)

#### 2. Install kubectl
```bash
brew install kubectl
```

#### 3. Install Tilt
```bash
brew install tilt
```

#### 4. Set up Local Kubernetes Cluster

Choose one of the following options:

**Option A: Docker Desktop (Recommended)**
1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Check "Enable Kubernetes"
4. Click "Apply & Restart"

**Option B: kind (Lightweight alternative)**
```bash
# Install kind
brew install kind

# Create cluster
kind create cluster --name tilt-dev
```

**Option C: k3d (Another lightweight option)**
```bash
# Install k3d
brew install k3d

# Create cluster
k3d cluster create tilt-dev
```

## First Time Setup

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd x-team-tools

# Copy developer configuration template
cp .tilt/developer-config.yaml.template .tilt/developer-config.yaml

# Edit your developer configuration
vim .tilt/developer-config.yaml
```

### 2. Configure Your Developer Settings

Edit `.tilt/developer-config.yaml`:

```yaml
developer:
  id: "your-name"  # Replace with your name (lowercase, no spaces)
  namespace: "dev-your-name"  # Will be auto-generated if not specified
  
cluster:
  type: "docker-desktop"  # or "kind" or "k3d"
  name: "tilt-dev"
  
services:
  # Services you want to run locally
  enabled:
    - ai-agentic-mdr-oscar
    - user-management-service
  
  # Services to build from source (vs using ECR images)
  build_locally:
    - ai-agentic-mdr-oscar
  
  # Services to pull from ECR
  use_ecr:
    - user-management-service
```

### 3. Start Your Development Environment

```bash
# Start with default configuration
tilt up

# Or start with specific services
tilt up -- --services=ai-agentic-mdr-oscar,user-management-service

# Start with your developer ID
tilt up -- --developer_id=your-name

# Start in debug mode for troubleshooting
tilt up -- --enable_debug=true
```

### 4. Access the Tilt UI

Open your browser to [http://localhost:10350](http://localhost:10350) to see the Tilt web interface.

## Your First Deployment

Let's deploy a simple service to verify everything works:

1. **Start Tilt with a single service:**
   ```bash
   tilt up -- --services=ai-agentic-mdr-oscar --developer_id=your-name
   ```

2. **Check the Tilt UI** - You should see:
   - Green checkmarks for successful deployments
   - Service logs in real-time
   - Port forwarding information

3. **Make a code change:**
   - Edit a file in the `ai-agentic-mdr-oscar` service
   - Save the file
   - Watch Tilt automatically rebuild and redeploy (usually < 30 seconds)

4. **Access your service:**
   - Check the Tilt UI for port forwarding information
   - Typically available at `http://localhost:8080` or similar

## Common Commands

### Environment Management
```bash
# Start development environment
tilt up

# Stop development environment
tilt down

# View logs for a specific service
tilt logs ai-agentic-mdr-oscar

# Restart a specific service
tilt trigger ai-agentic-mdr-oscar
```

### Kubernetes Operations
```bash
# Check your namespace
kubectl get all -n dev-your-name

# View pod logs directly
kubectl logs -f deployment/ai-agentic-mdr-oscar -n dev-your-name

# Port forward manually
kubectl port-forward service/ai-agentic-mdr-oscar 8080:8080 -n dev-your-name
```

### Troubleshooting Commands
```bash
# Validate your environment
./scripts/validate-environment.sh

# Check cluster connectivity
kubectl cluster-info

# View Tilt logs
tilt logs --follow

# Reset your environment
tilt down
kubectl delete namespace dev-your-name
tilt up
```

## Development Workflow

### Daily Workflow
1. **Start your day:**
   ```bash
   tilt up -- --developer_id=your-name
   ```

2. **Work on your code:**
   - Make changes to source files
   - Tilt automatically rebuilds and redeploys
   - Test your changes via port-forwarded endpoints

3. **End your day:**
   ```bash
   tilt down
   ```

### Working with Multiple Services
```bash
# Start multiple services
tilt up -- --services=service1,service2,service3

# Build some locally, use ECR for others
tilt up -- --build_local=service1,service2 --services=service1,service2,service3
```

### Debugging Issues
1. **Check the Tilt UI** for error messages
2. **View service logs** in the Tilt UI or via `tilt logs <service>`
3. **Check Kubernetes resources** with `kubectl get all -n dev-your-name`
4. **Run environment validation** with `./scripts/validate-environment.sh`

## Team Collaboration

### Sharing Configuration Changes
When you make changes to shared configuration files:

```bash
# Always commit configuration changes
git add .tilt/service-config.yaml Tiltfile
git commit -m "Update service configuration"
git push

# Team members should pull and restart
git pull
tilt down && tilt up
```

### Adding New Services
1. Add service configuration to `.tilt/service-config.yaml`
2. Test locally with `tilt up -- --services=new-service`
3. Commit and share with the team

## Next Steps

- Read the [Tilt Configuration Guide](TILT_CONFIGURATION_GUIDE.md) for advanced configuration
- Check out [Best Practices](TILT_BEST_PRACTICES.md) for optimization tips
- Review [Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md) for common issues
- Join the team Slack channel for support

## Getting Help

- **Tilt UI**: [http://localhost:10350](http://localhost:10350) - Real-time status and logs
- **Environment Validation**: `./scripts/validate-environment.sh`
- **Team Documentation**: Check the `docs/` directory
- **Tilt Documentation**: [https://docs.tilt.dev/](https://docs.tilt.dev/)

Welcome to the team! 🚀