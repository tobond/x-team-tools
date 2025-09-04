# Tilt Architecture Documentation

## Overview

This document describes the modular architecture of the Tilt development environment, designed following Tilt best practices for maintainability, scalability, and clarity.

## Architecture Principles

### 1. **Modular Design**
- **Separation of Concerns**: Each module handles a specific responsibility
- **Reusable Components**: Common functionality extracted into utilities
- **Clear Interfaces**: Well-defined function signatures and contracts
- **Single Responsibility**: Each file focuses on one domain

### 2. **Configuration-Driven**
- **Centralized Configuration**: All settings managed through YAML and command-line args
- **Environment-Specific Defaults**: Sensible defaults with override capabilities
- **Validation**: Comprehensive configuration validation and error reporting
- **Type Safety**: Clear parameter types and validation

### 3. **Safety First**
- **Context Validation**: Prevents accidental operations on production clusters
- **Multi-Layer Checks**: Context, API server, and pattern-based validation
- **Fail-Safe Defaults**: Conservative defaults that prioritize safety
- **Continuous Monitoring**: Ongoing safety validation during execution

## Project Structure

```
.tilt/
├── lib/                          # Modular Starlark libraries
│   ├── config.star              # Configuration parsing and validation
│   ├── cluster.star             # Cluster safety and environment detection
│   ├── namespace.star           # Namespace management and isolation
│   ├── k8s_manifests.star       # Kubernetes manifest generation
│   ├── config_secrets.star      # ConfigMap and Secret management
│   ├── dependencies.star        # Service dependency ordering
│   ├── builds.star              # Build strategies and live updates
│   ├── services.star            # Service deployment orchestration
│   └── monitoring.star          # Monitoring and validation resources
├── service-config.yaml          # Service definitions and configuration
└── developer-config.yaml       # Developer-specific settings (optional)

Tiltfile                         # Main orchestration file
tilt_config.json                 # Tilt-specific configuration
```

## Module Responsibilities

### 1. **config.star** - Configuration Management
```starlark
# Functions:
- parse_tilt_config()           # Parse command-line arguments and environment
- load_service_config()         # Load and validate service configuration YAML
- validate_services()           # Validate requested services exist
```

**Responsibilities:**
- Command-line argument parsing with Tilt's `config` system
- YAML configuration loading and validation
- Default value management and environment variable integration
- Service existence validation

### 2. **cluster.star** - Cluster Safety and Detection
```starlark
# Functions:
- validate_cluster_safety()     # Comprehensive cluster context validation
- detect_cluster_environment()  # Detect cluster type and validate locality
- setup_cluster_monitoring()    # Create cluster monitoring resources
```

**Responsibilities:**
- Dangerous context pattern detection (prod, staging, cloud providers)
- Local cluster validation (kind, k3d, docker-desktop, minikube)
- API server locality verification
- Cluster health monitoring and initialization checks

### 3. **namespace.star** - Namespace Management
```starlark
# Functions:
- setup_namespace()             # Create isolated developer namespace
```

**Responsibilities:**
- Developer-specific namespace creation with proper labeling
- Namespace isolation and resource quotas
- Namespace validation and monitoring

### 4. **k8s_manifests.star** - Manifest Generation
```starlark
# Functions:
- generate_k8s_manifests()      # Generate comprehensive K8s manifests
- _generate_env_vars()          # Environment variable templating
- _generate_probes()            # Health and readiness probe generation
- _generate_labels()            # Comprehensive resource labeling
```

**Responsibilities:**
- Dynamic Kubernetes manifest generation using Tilt templating
- Service-specific configuration (ports, environment, resources)
- Health probe configuration (HTTP for apps, TCP for databases)
- Security context and resource limit management

### 5. **config_secrets.star** - Configuration Management
```starlark
# Functions:
- create_service_configmap()    # Create ConfigMaps for non-sensitive config
- create_service_secret()       # Create Secrets for sensitive data
```

**Responsibilities:**
- ConfigMap creation with service-specific and language-specific configuration
- Secret management for sensitive data (passwords, API keys)
- Type-specific configuration injection (Python, Java, Go, Node.js)

### 6. **dependencies.star** - Dependency Management
```starlark
# Functions:
- setup_service_dependencies()  # Configure service startup dependencies
- _topological_sort()           # Determine safe deployment order
- _build_dependency_graph()     # Create dependency graph from configuration
```

**Responsibilities:**
- Dependency graph creation from service configurations
- Topological sorting for safe deployment order
- Circular dependency detection and prevention
- Resource dependency application to k8s resources

### 7. **builds.star** - Build Management
```starlark
# Functions:
- setup_build_strategy()        # Configure local or ECR build strategy
- get_live_updates_for_type()   # Language-specific live update rules
```

**Responsibilities:**
- Build strategy selection (local Docker build vs ECR image pull)
- Language-specific live update configuration
- ECR authentication and image caching
- Build optimization and performance tuning

### 8. **services.star** - Service Orchestration
```starlark
# Functions:
- deploy_service()              # Complete service deployment orchestration
- create_deployment_summary()   # Generate deployment summary resource
```

**Responsibilities:**
- Complete service deployment workflow coordination
- k8s_resource configuration with comprehensive settings
- Service-specific monitoring resource creation
- Port forwarding and resource labeling

### 9. **monitoring.star** - Monitoring and Validation
```starlark
# Functions:
- setup_monitoring_resources()  # Create monitoring and validation resources
- setup_safety_monitoring()     # Continuous safety monitoring
- setup_cleanup_resources()     # Environment cleanup utilities
```

**Responsibilities:**
- Kubernetes resource validation and monitoring
- Manifest validation and health checking
- Resource usage monitoring and metrics
- Safety monitoring and cleanup utilities

## Main Tiltfile Flow

The main `Tiltfile` orchestrates the entire deployment process:

```starlark
def main():
    # 1. Configuration parsing and validation
    tilt_config = parse_tilt_config()
    service_configs = load_service_config()
    
    # 2. Cluster safety validation and monitoring setup
    current_context = validate_cluster_safety(cluster_type, debug_mode)
    cluster_info = detect_cluster_environment(current_context, debug_mode)
    setup_cluster_monitoring(current_context, cluster_info)
    
    # 3. Namespace setup with isolation
    namespace = setup_namespace(developer_id, current_context, debug_mode)
    
    # 4. Monitoring and safety resources
    setup_monitoring_resources(namespace, services_to_deploy)
    setup_safety_monitoring()
    setup_cleanup_resources(namespace)
    
    # 5. Service deployment
    for service_name in services_to_deploy:
        deployment_result = deploy_service(...)
        deployed_services.append(deployment_result)
    
    # 6. Dependency configuration
    setup_service_dependencies(services_to_deploy, service_configs, debug_mode)
    
    # 7. Summary and success reporting
    create_deployment_summary(deployed_services, namespace, developer_id)
```

## Configuration Schema

### Service Configuration (`.tilt/service-config.yaml`)
```yaml
services:
  service-name:
    type: "python|java|go|nodejs|postgres|redis|generic"
    build_context: "./path/to/service"
    dockerfile: "./path/to/Dockerfile"
    ecr_image: "registry/image:tag"
    dependencies: ["service1", "service2"]
    ports: [8080, 8081]
    env_vars:
      - name: "LOG_LEVEL"
        value: "DEBUG"
      - name: "SECRET_KEY"
        value: "secret"
        from_secret: true
    resources:
      cpu: "500m"
      memory: "512Mi"
    health_check:
      path: "/health"
      port: 8080

global:
  default_resources:
    cpu: "100m"
    memory: "128Mi"
  default_health_check:
    initial_delay_seconds: 30
    period_seconds: 10
```

## Benefits of Modular Architecture

### 1. **Maintainability**
- **Focused Files**: Each file has a single, clear purpose
- **Easy Navigation**: Developers can quickly find relevant code
- **Isolated Changes**: Modifications to one module don't affect others
- **Clear Dependencies**: Module dependencies are explicit and minimal

### 2. **Testability**
- **Unit Testing**: Individual modules can be tested in isolation
- **Mock Dependencies**: Easy to mock dependencies for testing
- **Validation**: Each module has clear input/output contracts
- **Error Handling**: Centralized error handling and validation

### 3. **Reusability**
- **Common Patterns**: Shared utilities across multiple services
- **Language Support**: Extensible support for new languages/frameworks
- **Configuration Templates**: Reusable configuration patterns
- **Best Practices**: Codified best practices in reusable functions

### 4. **Scalability**
- **New Services**: Easy to add new service types and configurations
- **Feature Extension**: New features can be added as separate modules
- **Performance**: Optimized resource usage and build strategies
- **Team Collaboration**: Multiple developers can work on different modules

## Migration from Monolithic Tiltfile

The previous monolithic Tiltfile (1200+ lines) has been refactored into:
- **Main Tiltfile**: 150 lines (orchestration only)
- **9 Focused Modules**: Average 100-200 lines each
- **Clear Separation**: Each module handles one responsibility
- **Improved Readability**: Easy to understand and modify

## Usage Examples

### Basic Service Deployment
```bash
# Deploy specific services
tilt up -- --services=database,redis,ai-agentic-mdr-oscar

# Deploy with local builds
tilt up -- --services=ai-agentic-mdr-oscar --build_local=ai-agentic-mdr-oscar

# Deploy with debug mode
tilt up -- --services=database,ai-agentic-mdr-oscar --enable_debug=true
```

### Development Workflow
```bash
# Start development environment
tilt up -- --services=database,ai-agentic-mdr-oscar --developer_id=john

# Monitor resources
tilt trigger resource-monitor

# Validate manifests
tilt trigger manifest-validation

# Clean up environment
tilt trigger cleanup-environment
```

## Best Practices Implemented

### 1. **Tilt Documentation Compliance**
- **Starlark Modules**: Following Tilt's recommended modular approach
- **Extension Usage**: Proper use of Tilt extensions (namespace, configmap, secret)
- **Resource Management**: Optimal k8s_resource configuration
- **Live Updates**: Language-specific live update optimization

### 2. **Error Handling**
- **Fail Fast**: Early validation and clear error messages
- **Safety Checks**: Multiple layers of safety validation
- **Graceful Degradation**: Fallback behavior for optional features
- **Debug Support**: Comprehensive debug logging and monitoring

### 3. **Performance Optimization**
- **Build Caching**: Docker layer caching and optimization
- **Resource Limits**: Proper CPU/memory management
- **Dependency Ordering**: Optimal service startup sequence
- **Live Updates**: Efficient file watching and synchronization

This modular architecture provides a solid foundation for maintaining and extending the Tilt development environment while following industry best practices and Tilt's recommended patterns.