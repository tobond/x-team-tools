# Tilt Architecture Documentation

## Overview

This document describes the modular architecture of the Tilt development environment, designed following Tilt best practices for maintainability, scalability, and clarity.

## Architecture Principles

### 1. **Modular Design**
- **Separation of Concerns**: Each module handles a specific responsibility
- **Framework-Project Separation**: Clear boundaries between generic framework and project-specific configuration
- **Reusable Components**: Common functionality extracted into utilities
- **Clear Interfaces**: Well-defined function signatures and contracts
- **Single Responsibility**: Each file focuses on one domain
- **Service-Agnostic Framework**: No hardcoded service names in framework code

### 2. **Configuration-Driven**
- **Centralized Configuration**: All settings managed through YAML and command-line args
- **User-Defined Environments**: Complete environment customization via `.tilt/environments.yaml`
- **Dynamic Service Discovery**: Framework adapts to any service configuration
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
├── lib/                          # Modular Starlark libraries (FRAMEWORK LAYER)
│   ├── config.star              # Configuration parsing and validation
│   ├── cluster.star             # Cluster safety and environment detection
│   ├── namespace.star           # Namespace management and isolation
│   ├── k8s_manifests.star       # Kubernetes manifest generation
│   ├── config_secrets.star      # ConfigMap and Secret management
│   ├── dependencies.star        # Service dependency ordering
│   ├── builds.star              # Build strategies and live updates
│   ├── services.star            # Service deployment orchestration
│   ├── monitoring.star          # Monitoring and validation resources
│   ├── error_handling.star      # Error handling and recovery
│   └── external_services.star   # Service-agnostic external service deployment
├── service-config.yaml          # Service definitions (PROJECT LAYER)
├── environments.yaml            # User-defined environments (PROJECT LAYER)
└── developer-config.yaml       # Developer-specific settings (optional)

Tiltfile                         # Main orchestration file (FRAMEWORK LAYER)
tilt_config.json                 # Tilt-specific configuration
```

## Dynamic Port Allocation System

### Overview

The framework implements a sophisticated dynamic port allocation system that eliminates hardcoded service-to-port mappings while ensuring conflict-free local development.

### Key Features

#### 1. **Hash-Based Port Generation**
```starlark
# Generate deterministic but unique ports
hash_input = service_name + str(container_port) + str(port_index)
port_hash = abs(hash(hash_input)) % 2000  # 0-1999
local_port = 8000 + port_hash
```

#### 2. **Standard Port Preservation**
- PostgreSQL: 5432 → 5432
- Redis: 6379 → 6379
- MySQL: 3306 → 3306
- MongoDB: 27017 → 27017
- Elasticsearch: 9200 → 9200

#### 3. **Conflict Avoidance**
- Automatic detection of port conflicts
- Incremental port assignment for conflicts
- Fallback mechanisms for edge cases

#### 4. **Dynamic Dashboard Generation**
- Real-time port mapping display
- Service-specific forwarding information
- No hardcoded service references

### Implementation Benefits

- **Service Agnostic**: Works with any service configuration
- **Deterministic**: Same service always gets same ports
- **Developer Friendly**: Preserves familiar database ports
- **Conflict Free**: Automatically handles port collisions

## User-Defined Environment System

### Framework-Project Separation

The architecture now implements complete separation between the generic framework and project-specific configuration:

#### Framework Layer (Generic & Reusable)
- `Tiltfile` - Generic orchestration logic
- `.tilt/lib/*.star` - Service-agnostic modules
- `scripts/setup-environment.sh` - Generic environment setup

#### Project Layer (User-Configurable)
- `.tilt/service-config.yaml` - Project's services
- `.tilt/environments.yaml` - User-defined environments
- `services/` directory - Imported service code

### Environment Configuration

```yaml
# .tilt/environments.yaml
environments:
  minimal:
    description: "Essential services only"
    services: ["ai-agentic-test-app"]
    build_strategy: "local"
  
  backend-only:
    description: "APIs and databases"
    services: ["ai-agentic-test-app", "database", "redis"]
    build_strategy: "mixed"
  
  custom-demo:
    description: "My custom environment"
    services: ["service-a", "service-b"]
    build_strategy: "ecr"

global:
  default_build_strategy: "mixed"
```

### Benefits

- **Complete Flexibility**: Users define any environment combinations
- **No Framework Changes**: Adding services/environments requires no code changes
- **Reusable Framework**: Same framework works across different projects
- **Clean Separation**: Framework concerns isolated from project specifics

## Service-Agnostic External Services System

### Overview

The framework implements a completely service-agnostic approach for external services (databases, caches, message queues, etc.) that requires **zero code changes** to add new services.

### Key Features

#### 1. **Configuration-Driven Deployment**
All external services are deployed through a single generic function that reads all configuration from YAML:

```yaml
# .tilt/service-config.yaml
my-new-service:
  type: "external"
  image: "mysql:8.0"          # Any Docker image
  ports: [3306]               # Any ports  
  env_vars:                   # Any environment variables
    - name: "MYSQL_ROOT_PASSWORD"
      value: "mypassword"
  resources:                  # Any resource limits
    cpu: "500m"
    memory: "1Gi"
  health_check:               # Any health check
    command: ["mysqladmin", "ping"]
```

#### 2. **Universal Compatibility**
The framework can deploy any Docker-based service without code modifications:
- **Databases**: PostgreSQL, MySQL, MongoDB, CouchDB, etc.
- **Caches**: Redis, Memcached, etc.
- **Message Queues**: RabbitMQ, Kafka, etc.
- **Search Engines**: Elasticsearch, Solr, etc.
- **Any Docker Image**: Custom services, third-party tools

#### 3. **Simplified Credentials**
For local development, the framework uses standard, predictable credentials:
- **Database**: `testuser` / `testpass` / `testdb`
- **Cache**: `testpass`
- **Consistent**: Same pattern across all services

### Implementation Benefits

- **Zero Maintenance**: No code changes required for new external services
- **Developer Friendly**: Standard credentials across all services
- **Docker Compatible**: Works with any Docker image
- **Resource Aware**: Configurable CPU, memory, and storage limits
- **Health Monitoring**: Configurable health checks per service

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
- setup_namespace()             # Create developer namespace
```

**Responsibilities:**
- Developer-specific namespace creation with proper labeling
- Namespace management and resource quotas
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
- deploy_service()                    # Complete service deployment orchestration
- deploy_services_orchestrated()      # Deploy multiple services with coordination
- generate_unique_port_forwards()     # Dynamic port allocation for conflict avoidance
- create_deployment_summary()         # Generate deployment summary resource
- create_port_mapping_dashboard()     # Dynamic port mapping dashboard
```

**Responsibilities:**
- Complete service deployment workflow coordination
- Dynamic port allocation using hash-based algorithms to avoid conflicts
- k8s_resource configuration with comprehensive settings
- Service-agnostic port forwarding (no hardcoded service names)
- Dynamic monitoring dashboards based on actual deployed services

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
    
    # 3. Namespace setup
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

### Environment-Based Deployment
```bash
# Use predefined environments
./scripts/setup-environment.sh minimal
./scripts/setup-environment.sh backend-only
./scripts/setup-environment.sh full-stack

# Use custom environments
./scripts/setup-environment.sh my-demo-setup
./scripts/setup-environment.sh integration-test

# Dry run to see what would be deployed
./scripts/setup-environment.sh backend-only --dry-run
```

### Direct Service Deployment
```bash
# Deploy specific services (legacy approach)
tilt up -- --services=database,redis,ai-agentic-test-app

# Deploy with local builds
tilt up -- --services=ai-agentic-test-app --build_local=ai-agentic-test-app

# Deploy with debug mode
tilt up -- --services=database,ai-agentic-test-app --enable_debug=true
```

### Development Workflow
```bash
# Modern workflow - environment-based
./scripts/setup-environment.sh backend-only --developer-id=john

# Service discovery and management
./scripts/list-services.sh
./scripts/service-info.sh ai-agentic-test-app

# Legacy workflow - direct service specification
tilt up -- --services=database,ai-agentic-test-app --developer_id=john

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