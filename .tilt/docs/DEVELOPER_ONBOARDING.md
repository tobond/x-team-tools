# Developer Onboarding Guide

## Quick Start

Welcome to the x-team-tools development environment! This guide will get you up and running with our Tilt-based local Kubernetes development environment in under 5 minutes.

### Prerequisites

Before you begin, ensure you have the following installed:

- **Docker Desktop** (or Docker Engine + kind/k3d)
- **kubectl** (Kubernetes CLI)
- **Tilt** (v0.30.0 or later)
- **Git**

### Installation Scripts

We provide automated setup scripts:

```bash
# macOS (using Homebrew)
./scripts/setup-macos.sh

# Validate your environment
./scripts/validate-environment.sh
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

### 1. Clone the Repository

```bash
# Clone the repository
git clone <repository-url>
cd x-team-tools
```

### 2. Review Service Configuration

All services are defined in `.tilt/service-config.yaml`:

```yaml
services:
  ai-agentic-test-app:
    type: "python"
    build_context: "./services/ai-agentic-test-app"
    dockerfile: "./services/ai-agentic-test-app/Dockerfile"
    dependencies: ["database", "redis"]
    ports: [8000]
    env_vars:
      - name: "DATABASE_URL"
        value: "postgresql://testuser:testpass@database:5432/testdb"
  
  database:
    type: "external"
    image: "postgres:14"
    ports: [5432]
    # ... configuration
```

### 3. Review Environment Configurations

Predefined environments are in `.tilt/environments.yaml`:

```yaml
environments:
  minimal:
    description: "Essential services only"
    services: ["ai-agentic-test-app"]
  
  backend-only:
    description: "Backend APIs and databases"
    services: ["ai-agentic-test-app", "database", "redis"]
  
  full-stack:
    description: "Complete environment"
    services: ["ai-agentic-test-app", "database", "redis", "frontend"]
```

### 4. Start Your Development Environment

> **Note**: The `developer_id` automatically defaults to your username (`$USER`). Your namespace will be `dev-$USER`. Only use `--developer_id=custom` if you need a different namespace.

#### Option A: Using Environments (Recommended)

```bash
# Deploy using predefined environments
tilt up -- --environment=minimal
tilt up -- --environment=backend-only
tilt up -- --environment=full-stack

# List available environments
grep "^  [a-z]" .tilt/environments.yaml | sed 's/://'
```

#### Option B: Direct Service Selection

```bash
# Start specific services directly
tilt up -- --services=ai-agentic-test-app,database,redis 
# Or start with just one service
tilt up -- --services=ai-agentic-test-app ```

### 5. Access the Tilt UI

Open your browser to [http://localhost:10350](http://localhost:10350) to see the Tilt web interface.

## Your First Deployment

Let's deploy a simple service to verify everything works:

1. **Start Tilt with an environment:**
   ```bash
   # Using the backend-only environment (recommended)
   tilt up -- --environment=backend-only
   
   # This will automatically deploy: ai-agentic-test-app, database, redis
   ```

2. **Check the Tilt UI** - You should see:
   - Green checkmarks for successful deployments
   - Service logs in real-time
   - Port forwarding information

3. **Test live updates (supported service types):**
   - Edit a file in your service directory
   - Save the file
   - Watch Tilt sync and reload:
     - Python: uvicorn auto-reload (< 2 seconds)
     - Node.js: nodemon restart
     - Java: Maven recompile + Spring DevTools
     - Go: Binary rebuild

4. **Access your service:**
   - Check the Tilt UI for port forwarding
   - Access at `http://localhost:8000`

## Common Commands

### Environment Management
```bash
# Start with an environment
tilt up -- --environment=backend-only 
# List available environments
grep "^  [a-z]" .tilt/environments.yaml | sed 's/://'

# Stop all services
tilt down
```

### Service Management
```bash
# Start specific services (when not using environments)
tilt up -- --services=service1,service2 
# View logs for a specific service
tilt logs ai-agentic-test-app

# Restart a specific service
tilt trigger ai-agentic-test-app
```

### Kubernetes Operations
```bash
# Check your namespace
kubectl get all -n dev-$(whoami)

# View pod logs directly
kubectl logs -f deployment/ai-agentic-test-app -n dev-$(whoami)

# Port forward manually
kubectl port-forward service/ai-agentic-test-app 8000:8000 -n dev-$(whoami)
```

### Troubleshooting Commands
```bash
# Check cluster connectivity
kubectl cluster-info

# View Tilt logs
tilt logs --follow

# Reset your environment
tilt down
kubectl delete namespace dev-$(whoami)
tilt up -- --services=ai-agentic-test-app ```

## Development Workflow

### Daily Workflow
1. **Start your day with an environment:**
   ```bash
   # For backend development
   tilt up -- --environment=backend-only    
   # For minimal testing
   tilt up -- --environment=minimal    
   # For full-stack work
   tilt up -- --environment=full-stack    ```

2. **Work on your code:**
   - Make changes to Python source files
   - Tilt syncs files and uvicorn auto-reloads
   - Test your changes via port-forwarded endpoints

3. **End your day:**
   ```bash
   tilt down
   ```

### Working with Environments

#### Available Environments
```bash
# Check available environments
cat .tilt/environments.yaml

# Common environments:
# - minimal: Just the app
# - backend-only: App + databases
# - full-stack: Everything
# - feature-branch: Lightweight for features
```

#### Creating Custom Environments
Add to `.tilt/environments.yaml`:
```yaml
environments:
  my-custom-env:
    description: "Custom setup for my feature"
    services: ["app", "database", "custom-service"]
```

Then deploy:
```bash
tilt up -- --environment=my-custom-env ```

### Mixing Environments and Direct Services
```bash
# You can override environment with specific services if needed
tilt up -- --services=service1,service2,service3 
# But using environments is recommended for consistency
```

### Live Updates
Live updates are automatic for supported service types:

**Python Services:**
- Files synced to `/app/`
- Uvicorn's `--reload` flag detects changes
- Updates in < 2 seconds

**Node.js Services:**
- Source files synced to `/app/src`
- Nodemon or similar handles restarts
- Package.json changes trigger npm install

**Java Services:**
- Source files synced to `/app/src`
- Maven recompiles on changes
- Spring DevTools handles hot reload

**Go Services:**
- Source directories synced
- Binary rebuilt on file changes
- Running process updated

**Note**: External services (databases, redis) don't support live updates.

## Understanding the Architecture

The Tilt implementation consists of 3 focused files:

1. **Tiltfile** (90 lines) - Main orchestration
2. **.tilt/config.star** (42 lines) - Configuration parsing (includes environment loading)
3. **.tilt/services.star** (252 lines) - Service deployment logic

Total: **384 lines** of maintainable code

### Key Configuration Files
- **`.tilt/service-config.yaml`** - Service definitions
- **`.tilt/environments.yaml`** - Environment presets

### Service Types
- **python** - Python apps with uvicorn live reload
- **external** - Pre-built images (PostgreSQL, Redis)
- **java**, **go**, **node** - Basic Docker builds (no live updates)

### Build Methods
- **Local Docker Build** - When `build_context` and `dockerfile` are present
- **External Image** - When `type: "external"` and `image` are present

## Adding New Services

### Step 1: Define the Service
Edit `.tilt/service-config.yaml`:
```yaml
my-new-service:
  type: "python"
  build_context: "./services/my-new-service"
  dockerfile: "./services/my-new-service/Dockerfile"
  ports: [8080]
```

### Step 2: Add to an Environment
Edit `.tilt/environments.yaml`:
```yaml
environments:
  backend-only:
    description: "Backend APIs and databases"
    services: ["ai-agentic-test-app", "database", "redis", "my-new-service"]
```

### Step 3: Create Service Directory
```bash
mkdir -p services/my-new-service
# Add Dockerfile and source code
```

### Step 4: Deploy with Environment
```bash
# Deploy using the updated environment
tilt up -- --environment=backend-only 
# Or deploy individually
tilt up -- --services=my-new-service ```

## Scope and Limitations

The implementation focuses on essential features and does NOT support:
- Dynamic port allocation
- Runtime configuration overrides
- ECR images
- Monitoring dashboards
- Plugin framework
- Command-based builds (Maven, Gradle)

This focused scope ensures simplicity and fast feedback loops.

## Getting Help

- **Tilt UI**: [http://localhost:10350](http://localhost:10350) - Real-time status and logs
- **Documentation**: Check updated guides in `.tilt/docs/`
- **Source Code**: Only 3 files to understand:
  - `Tiltfile`
  - `.tilt/config.star`
  - `.tilt/services.star`
- **Tilt Documentation**: [https://docs.tilt.dev/](https://docs.tilt.dev/)

## Common Issues

### Service Not Deploying
- Check service name spelling in `--services` flag
- Verify service exists in `.tilt/service-config.yaml`
- Check Tilt UI for error messages

### Dependencies Not Working
- Include all dependent services in `--services` flag
- Example: `--services=app,database,redis`

### Port Conflicts
- Check if another service is using the same port
- Stop conflicting services or change ports in config

### Live Updates Not Working (Python)
- Ensure Dockerfile uses uvicorn with `--reload`
- Verify WORKDIR is `/app/`
- Check file permissions

Welcome to the team! 🚀