# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

x-team-tools is a comprehensive **Service Import/Integration Platform** powered by Tilt for local Kubernetes development. Import existing services from any repository and set up complete development environments in minutes. The platform supports multiple service types (Python, Java, Go, Node.js, CrewAI) with a simplified 3-file Tilt architecture.

## Development Commands

### Environment Setup
```bash
# Initial setup (macOS)
./scripts/setup-macos.sh

# Validate environment (checks Docker, kubectl, Tilt, cluster)
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

# Manual service control (--developer_id defaults to $USER)
tilt up -- --services=service1,service2       # Start specific services
tilt up -- --environment=backend-only         # Use environment preset
tilt down                                      # Stop all services

# View service logs
tilt logs service-name

# Trigger manual rebuild (for services without live updates)
tilt trigger service-name

# Reset environment if needed  
tilt down && kubectl delete namespace dev-$(whoami)
```

### Kubernetes Operations
```bash
# Check your namespace
kubectl get all -n dev-$(whoami)

# View pod logs
kubectl logs -f deployment/service-name -n dev-$(whoami)

# Execute into container
kubectl exec -it deployment/service-name -n dev-$(whoami) -- /bin/bash

# Check cluster status
kubectl cluster-info
```

## Architecture Overview

### Simplified Tilt Architecture (384 lines total)
The system uses just 3 files with direct, clear implementations:

```
Tiltfile (90 lines)                # Main orchestration
├── .tilt/config.star (42 lines)   # Configuration parsing & environment loading
└── .tilt/services.star (252 lines) # Service deployment & live updates
```

### Key Design Principles
- **Simplicity First**: Direct functions over abstractions, 96% code reduction from original
- **Safety Validation**: Prevents operations on production clusters
- **Configuration-Driven**: All settings in `.tilt/service-config.yaml`
- **Developer Isolation**: Each developer gets `dev-$USER` namespace by default
- **Live Updates**: Comprehensive support for Python, Node.js, Java, and Go services

## Service Configuration

Services are defined in `.tilt/service-config.yaml`:

### Service Types & Live Update Support
- **python**: Full live reload with uvicorn (< 2 seconds)
- **node/nodejs**: Source sync + npm updates + nodemon
- **java**: Source sync + Maven compilation + Spring DevTools
- **go**: Source sync + binary rebuild
- **crewai**: Limited support (file sync only, Python-based)
- **external**: No live updates (databases, redis, etc.)

### Example Service Definition
```yaml
services:
  my-python-app:
    type: "python"
    build_context: "./services/my-python-app"
    dockerfile: "./services/my-python-app/Dockerfile"
    dependencies: ["database", "redis"]
    ports: [8000]
    env_vars:
      - name: "DATABASE_URL"
        value: "postgresql://testuser:testpass@database:5432/testdb"
    health_check:
      path: "/health"
      port: 8000
```

## Live Updates Configuration

### Requirements by Service Type

**Python**: Dockerfile must use uvicorn with --reload
```dockerfile
WORKDIR /app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

**Node.js**: Package.json must have nodemon
```json
"scripts": {
  "dev": "nodemon src/index.js"
}
```

**Java**: pom.xml needs Spring DevTools
```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-devtools</artifactId>
</dependency>
```

**Go**: Standard directory structure required
- Code in `/cmd` and `/pkg` directories
- `go.mod` and `go.sum` files

## Environment Presets

Defined in `.tilt/environments.yaml`:
- **minimal**: Core services only
- **backend-only**: APIs + databases
- **full-stack**: All services
- **staging-mirror**: Matches staging environment
- **test-env**: Testing configuration

Use with: `tilt up -- --environment=backend-only`

## Common Development Patterns

### Working with Services
1. **Import service**: `./scripts/import-service.sh github:company/service-name`
2. **Review info**: `./scripts/service-info.sh service-name`
3. **Test service**: `tilt up -- --services=service-name`
4. **Set up environment**: `./scripts/setup-environment.sh backend-only`

### Debugging Services
- Tilt UI at `http://localhost:10350` for real-time monitoring
- Service logs: `tilt logs service-name`
- Pod details: `kubectl describe pod <pod-name> -n dev-$(whoami)`
- Container exec: `kubectl exec -it deployment/service-name -n dev-$(whoami) -- /bin/bash`

### Testing Live Updates
1. Make code changes in service directory
2. Save files
3. Watch automatic reload:
   - Python: < 2 seconds with uvicorn
   - Node.js: nodemon restart
   - Java: Maven recompile + Spring DevTools
   - Go: Binary rebuild

## Important File Locations

- **Service Configuration**: `.tilt/service-config.yaml`
- **Environment Presets**: `.tilt/environments.yaml`
- **Main Tilt Files**: `Tiltfile`, `.tilt/config.star`, `.tilt/services.star`
- **Imported Services**: `services/` directory
- **Documentation**: `.tilt/docs/` directory
- **Scripts**: `scripts/` directory
- **Team Standards**: `.tilt/team/`

## Tilt Best Practices Followed

- Direct use of `docker_build()` with live updates instead of complex abstractions
- Simple `k8s_resource()` for resource management
- Configuration validation before deployment
- Namespace isolation per developer (`dev-$USER`)
- Dependency filtering for deployed services only
- Clear separation of concerns across 3 focused files
- Live update configurations optimized per language/framework