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
├── framework/                   # Plugin Architecture Framework (FRAMEWORK LAYER)
│   ├── core/
│   │   ├── orchestration.star   # Service lifecycle management
│   │   ├── plugin_discovery.star # Plugin registration and discovery
│   │   └── legacy_bridge.star   # Bridge to existing lib/ modules
│   ├── interfaces/
│   │   ├── service.star         # Service plugin interface contract
│   │   ├── build_strategy.star  # Build strategy interface
│   │   └── environment.star     # Environment plugin interface
│   ├── registry/
│   │   ├── service_registry.star # Service plugin registration
│   │   ├── build_registry.star  # Build strategy registration
│   │   └── environment_registry.star # Environment registration
│   └── validation/
│       ├── config_validator.star # Generic configuration validation
│       └── schema.star          # Configuration schemas
├── plugins/                     # Configuration-Driven Plugins (IMPLEMENTATION LAYER)
│   ├── services/
│   │   └── yaml_config_reader.star # Universal service plugin (ALL types)
│   ├── environments/
│   │   └── yaml_environment_loader.star # Universal environment plugin (ALL envs)
│   └── build_strategies/
│       └── live_update.star     # Live update strategy
├── lib/                         # Legacy Modular Libraries (transitioning)
│   ├── config.star              # Configuration parsing and validation
│   ├── cluster.star             # Cluster safety and environment detection
│   ├── services.star            # Service deployment orchestration
│   └── [other lib modules...]   # Other framework modules
├── service-config.yaml          # Service definitions (PROJECT LAYER)
├── environments.yaml            # User-defined environments (PROJECT LAYER)
└── developer-config.yaml       # Developer-specific settings (optional)

Tiltfile                         # Main orchestration file (FRAMEWORK LAYER)
tilt_config.json                 # Tilt-specific configuration
```

## Simple Port Forwarding System

### Overview

The framework implements a straightforward port forwarding system that uses exactly the ports specified by developers in their service configuration.

### Key Features

#### 1. **Direct Port Mapping**
```starlark
# Use ports exactly as configured by developers
for container_port in ports:
    port_forwards.append("{}:{}".format(container_port, container_port))
```

#### 2. **Developer-Controlled Ports**
- Developers specify exactly which ports they want in service configuration
- No dynamic allocation or modification of ports
- Local port always matches container port

#### 3. **Simple Configuration**
```yaml
services:
  my-service:
    ports: [8080, 8443]  # Forwards localhost:8080 → container:8080, localhost:8443 → container:8443
```

#### 4. **Transparent Port Mapping**
- What you configure is what you get
- No hidden port transformations
- Predictable and explicit port forwarding

### Implementation Benefits

- **Simple and Predictable**: Developers know exactly which ports will be used
- **No Conflicts**: Developers are responsible for choosing non-conflicting ports
- **Transparent**: No hidden logic or port transformations
- **Direct Control**: Full developer control over port allocation

## User-Defined Environment System

### Framework-Project Separation

The architecture implements complete separation between the generic framework and project-specific configuration:

#### Framework Layer (Generic & Reusable)
- `Tiltfile` - Generic orchestration logic with plugin framework integration
- `.tilt/framework/` - Plugin architecture framework (interfaces, registries, validation)
- `.tilt/lib/*.star` - Legacy service-agnostic modules (transitioning)
- `scripts/setup-environment.sh` - Generic environment setup

#### Implementation Layer (Configuration-Driven Plugins)
- `.tilt/plugins/services/yaml_config_reader.star` - Universal service plugin (ALL types)
- `.tilt/plugins/environments/yaml_environment_loader.star` - Universal environment plugin (ALL envs)
- `.tilt/plugins/build_strategies/` - Build strategy plugins

#### Project Layer (User-Configurable - YAML Only)
- `.tilt/service-config.yaml` - Defines ALL service types and configurations
- `.tilt/environments.yaml` - Defines ALL environment combinations
- `services/` directory - Imported service code

### Environment Configuration

```yaml
# .tilt/environments.yaml
environments:
  minimal:
    description: "Essential services only"
    services: ["ai-agentic-test-app"]
  
  backend-only:
    description: "APIs and databases"
    services: ["ai-agentic-test-app", "database", "redis"]
  
  custom-demo:
    description: "My custom environment"
    services: ["service-a", "service-b"]

```

### Benefits

- **Complete Flexibility**: Users define any environment combinations
- **Zero-Code Extensions**: Adding services/environments requires ONLY YAML edits
- **Universal Plugin Architecture**: Two plugins handle ALL service and environment types
- **Pure Configuration-Driven**: No hardcoded service logic anywhere in the implementation
- **Reusable Framework**: Same framework works across different projects
- **Clean Separation**: Framework concerns completely isolated from project specifics

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
- setup_build_method()          # Configure build method based on service configuration
- get_live_updates_for_type()   # Language-specific live update rules
```

**Responsibilities:**
- Automatic build method detection based on service configuration fields
- Language-specific live update configuration
- ECR authentication and image caching
- Build optimization and performance tuning

### 8. **services.star** - Service Orchestration
```starlark
# Functions:
- deploy_service()                    # Complete service deployment orchestration
- deploy_services_orchestrated()      # Deploy multiple services with coordination
- generate_unique_port_forwards()     # Simple port forwarding using developer-configured ports
- create_deployment_summary()         # Generate deployment summary resource
- create_port_mapping_dashboard()     # Dynamic port mapping dashboard
```

**Responsibilities:**
- Complete service deployment workflow coordination
- Simple port forwarding using exactly the ports specified by developers
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

# Deploy specific services (build method determined automatically)
tilt up -- --services=ai-agentic-test-app

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