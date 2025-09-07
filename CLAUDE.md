# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

x-team-tools is a comprehensive **Service Import/Integration Platform** powered by Tilt for local Kubernetes development. Import existing services from any repository and set up complete development environments in minutes. The platform supports multiple service types (Python, Java, Go, Node.js, CrewAI) with modular architecture and strict safety controls.

## Development Commands

### Environment Setup
```bash
# Initial setup (macOS)
./scripts/setup-macos.sh

# Validate environment
./scripts/validate-environment.sh

# Setup team configuration
./scripts/setup-team-config.sh
```

### Core Development Workflow
```bash
# Import existing services
./scripts/import-service.sh github:company/user-service
./scripts/import-service.sh git@github.com:company/payment-service.git --branch develop

# Set up predefined environments  
./scripts/setup-environment.sh backend-only    # APIs + databases
./scripts/setup-environment.sh full-stack     # All services
./scripts/setup-environment.sh minimal        # Core services only

# Service discovery and management
./scripts/list-services.sh                    # Show all available services
./scripts/service-info.sh user-service        # Detailed service information

# Manual service control
tilt up service1 service2 -- --developer_id=$(whoami)
tilt down

# View service logs
tilt logs service-name

# Reset environment if needed  
tilt down && kubectl delete namespace dev-$(whoami)
```

### Kubernetes Operations
```bash
# Check your namespace
kubectl get all -n dev-$(whoami)

# View pod logs
kubectl logs -f deployment/service-name -n dev-$(whoami)

# Check cluster status
kubectl cluster-info
```

## Architecture Overview

### Modular Tilt Architecture
The main `Tiltfile` (193 lines) orchestrates a modular system with clear separation of concerns:

```
Tiltfile                       # Main orchestration
├── .tilt/lib/config.star      # Configuration management and validation
├── .tilt/lib/cluster.star     # Cluster safety detection and validation
├── .tilt/lib/services.star    # Service deployment orchestration
├── .tilt/lib/builds.star      # Build strategies and live updates
├── .tilt/lib/monitoring.star  # Monitoring and validation resources
├── .tilt/lib/dependencies.star # Service dependency management
├── .tilt/lib/namespace.star   # Isolated namespace setup
├── .tilt/lib/external_services.star # External service deployment
└── .tilt/lib/error_handling.star   # Comprehensive error handling
```

### Key Design Principles
- **Safety First**: Multi-layer validation prevents operations on production clusters
- **Configuration-Driven**: All settings managed through `.tilt/service-config.yaml`
- **Developer Isolation**: Each developer gets their own namespace (`dev-$USER`)
- **Flexible Build Strategies**: Support for ECR images, local builds, or live source builds
- **Comprehensive Monitoring**: Built-in debugging and monitoring resources

## Service Configuration

Services are defined in `.tilt/service-config.yaml`:

### Service Types Supported
- **python**: Python applications with live reload
- **external**: External services (postgres, redis, mock)
- **java**: Java applications (Spring Boot, etc.)
- **go**: Go applications with fast rebuilds
- **node**: Node.js applications
- **crewai**: AI agent services

### Example Service Definition
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
    health_check:
      path: "/health"
      port: 8000
```

## Safety Features

The system includes multiple safety layers:

### Cluster Safety Validation
- Context name validation (blocks production-like contexts)
- API server URL validation
- Kubernetes cluster type detection
- Continuous safety monitoring during deployment

### Namespace Isolation
- Each developer gets isolated namespace: `dev-$USER`
- Automatic namespace creation and cleanup
- Resource quotas and monitoring

### Error Handling
- Comprehensive error recovery dashboards
- Build failure monitoring and reporting
- Service health validation
- Dependency resolution monitoring

## Service Import & Management

### Service Import
```bash
# Import existing service from repository
./scripts/import-service.sh github:company/user-service
./scripts/import-service.sh git@github.com:company/service.git --branch develop

# Import local directory reference
./scripts/import-service.sh ../existing-service --type reference
```

### Service Discovery
```bash
# List all available services
./scripts/list-services.sh

# Get detailed service information
./scripts/service-info.sh service-name

# Set up predefined environments
./scripts/setup-environment.sh backend-only
./scripts/setup-environment.sh full-stack
```

### Configuration Management
- Team-wide configuration in `.tilt/team/`
- Environment-specific settings in `.tilt/environments/`
- Imported services in `services/` directory

## Common Development Patterns

### Working with Services
1. **Import existing service**: `./scripts/import-service.sh github:company/service-name`
2. **Review service info**: `./scripts/service-info.sh service-name`
3. **Test service**: `tilt up service-name -- --developer_id=$(whoami)`
4. **Set up environment**: `./scripts/setup-environment.sh backend-only`

### Debugging Services
- Use Tilt UI at `http://localhost:10350` for real-time monitoring
- Check service logs: `tilt logs service-name`
- Use debugging resources created automatically in Tilt UI
- Access comprehensive dashboards for build strategies and service health

### Build Strategy Selection
- **ECR Images**: Use pre-built images from ECR registry (default)
- **Local Builds**: Build images locally with `--build_local=service-name`
- **Live Updates**: Hot-reload source changes without rebuilds (Python, Node.js)

## Testing and Validation

### Environment Validation
- Run `./scripts/validate-environment.sh` to check all dependencies
- Validates: Docker, kubectl, Tilt, cluster connectivity, and safety

### Service Testing
- Health checks defined per service in configuration
- Automatic dependency validation
- Build and deployment monitoring through Tilt UI

## Important File Locations

- **Main Configuration**: `.tilt/service-config.yaml`
- **Team Standards**: `.tilt/team/`
- **Imported Services**: `services/`
- **Documentation**: `.tilt/docs/`
- **Import Scripts**: `scripts/import-service.sh`, `scripts/list-services.sh`, `scripts/service-info.sh`
- **Environment Scripts**: `scripts/setup-environment.sh`
- **AI Prompts**: `prompts/`

## Tilt Best Practices Followed

- Modular Starlark libraries for maintainability
- Configuration-driven approach with validation
- Comprehensive error handling and recovery
- Safety-first design with multiple validation layers
- Developer isolation and team collaboration features
- Live updates and fast development cycles