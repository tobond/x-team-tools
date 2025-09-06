# Technology Stack

## Core Technologies

- **Orchestration**: Tilt for local development environment management
- **Container Platform**: Kubernetes (local clusters: kind/k3d/Docker Desktop)
- **Configuration**: YAML-based configuration files
- **Documentation**: Markdown for all documentation and templates

## Supported Application Stacks

- **Python**: CrewAI services, general Python applications
- **Java**: Spring Boot services and other Java applications
- **Go**: Microservices and CLI tools
- **Node.js**: Web services and applications

## Development Environment Architecture

- **Local Kubernetes**: Each developer runs their own isolated local cluster
- **Image Sources**: ECR registry, local Docker builds, live source builds
- **Service Discovery**: Kubernetes-native networking
- **Configuration Management**: Tilt configuration with YAML service definitions

## Common Commands

### Environment Setup
```bash
# Start development environment with specific services
tilt up -- --services=service1,service2

# Start with developer identification
tilt up -- --developer_id=your-name

# Enable debug mode
tilt up -- --enable_debug=true
```

### Service Management
```bash
# Deploy specific services
tilt up -- --services=ai-agentic-mdr-oscar,user-management-service

# Build services locally instead of using ECR
tilt up -- --build_local=ai-agentic-mdr-oscar

# View Tilt web UI (typically http://localhost:10350)
tilt up
```

### Cluster Operations
```bash
# Check cluster status
kubectl cluster-info

# View local environment resources
kubectl get all

# Monitor resource usage
kubectl top nodes
kubectl top pods
```

## Configuration Files

- **Tiltfile**: Main orchestration configuration
- **.tilt/service-config.yaml**: Service definitions and deployment settings
- **.tilt/developer-config.yaml**: Developer-specific environment settings
- **cortex.yaml**: Service metadata and organizational information