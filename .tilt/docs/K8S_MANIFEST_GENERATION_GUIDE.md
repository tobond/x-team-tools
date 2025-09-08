# Kubernetes Manifest Generation System

## Overview

This document describes the comprehensive Kubernetes manifest generation system implemented in the Tilt development environment. The system provides dynamic manifest generation, ConfigMap/Secret management, and proper resource dependency ordering.

## Key Features Implemented

### 1. Dynamic Kubernetes Manifest Generation (`k8s_yaml()`)

The system generates comprehensive Kubernetes manifests dynamically using Tilt's templating capabilities:

#### Enhanced Deployment Manifests
- **Comprehensive Labels**: Includes app, type, developer, environment, and version labels
- **Security Context**: Non-root user, dropped capabilities, privilege escalation prevention
- **Resource Management**: Proper CPU/memory requests and limits with defaults
- **Health Probes**: HTTP probes for applications, TCP probes for databases
- **Rolling Updates**: Zero-downtime deployment strategy
- **Annotations**: Tilt-specific metadata for tracking and debugging

#### Service Manifests
- **Proper Port Naming**: HTTP, HTTPS, and custom port naming conventions
- **Service Discovery**: ClusterIP services with proper selectors
- **Protocol Specification**: TCP protocol specification for all ports
- **Session Affinity**: Configurable session affinity settings

### 2. ConfigMap and Secret Management

#### ConfigMap Creation (`configmap_create()`)
```python
def create_service_configmap(service_name, service_config, namespace):
    """Create ConfigMap for service configuration using Tilt's configmap extension"""
```

**Features:**
- Service-specific configuration data
- Environment-based settings (SERVICE_TYPE, SERVICE_NAME, NAMESPACE)
- Language-specific configuration (PYTHONPATH, JAVA_OPTS, NODE_ENV, etc.)
- Non-sensitive environment variables from service config

#### Secret Management (`secret_create_generic()`)
```python
def create_service_secret(service_name, service_config, namespace):
    """Create Secret for sensitive service configuration using Tilt's secret extension"""
```

**Features:**
- Sensitive environment variables
- Database credentials (postgres_password, postgres_user, etc.)
- Service-specific secrets (redis_password, API keys, etc.)
- Secure handling of sensitive configuration data

### 3. k8s_resource() Configuration with Proper Labels and Dependencies

#### Enhanced Resource Configuration
```python
k8s_resource(
    service_name,
    port_forwards=port_forwards,
    resource_deps=[],  # Set by dependency system
    labels=resource_labels,
    auto_init=True,
    trigger_mode=TRIGGER_MODE_AUTO,
    pod_readiness="wait",
    discovery_strategy="selectors-only",
    extra_pod_selectors=[
        {"app": service_name},
        {"tilt.dev/resource": service_name}
    ]
)
```

**Features:**
- **Port Forwarding**: Automatic port forwarding for all service ports
- **Resource Labels**: Comprehensive labeling system for categorization
- **Pod Readiness**: Wait for pod readiness before considering deployment complete
- **Discovery Strategy**: Optimized resource discovery using selectors
- **Extra Selectors**: Additional pod selectors for better resource management

### 4. Resource Dependency Ordering (`resource_deps`)

#### Topological Sort Implementation
```python
def setup_service_dependencies(services, service_configs):
    """Configure comprehensive service startup dependencies with proper ordering"""
```

**Features:**
- **Dependency Graph**: Builds complete dependency graph from service configurations
- **Topological Sort**: Determines safe deployment order
- **Circular Dependency Detection**: Prevents infinite loops and deployment failures
- **Active Dependency Filtering**: Only includes dependencies that are being deployed
- **Deployment Order Monitoring**: Creates monitoring resource showing deployment sequence

#### Dependency Resolution Process
1. **Graph Building**: Creates dependency graph from service configurations
2. **Validation**: Checks for circular dependencies
3. **Ordering**: Performs topological sort to determine deployment order
4. **Application**: Applies `resource_deps` to k8s resources
5. **Monitoring**: Creates deployment order information resource

## Service Configuration Schema

### Enhanced Service Definition

**Each service must specify exactly ONE build strategy:**

**Option 1: Dockerfile-based Build**
```yaml
services:
  dockerfile-service:
    type: "python"
    build_context: "./path/to/service"
    dockerfile: "./path/to/service/Dockerfile"
    dependencies: ["service1", "service2"]
    ports: [8080, 8081]
```

**Option 2: Command-based Build**
```yaml
services:
  command-service:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=myservice:latest"
    build_working_dir: "./path/to/service"
    dependencies: ["service1", "service2"]
    ports: [8080, 8081]
```

**Option 3: ECR Pre-built Image**
```yaml
services:
  ecr-service:
    type: "python"
    ecr_image: "registry/image:tag"
    dependencies: ["service1", "service2"]
    ports: [8080, 8081]
```

**Common Configuration (all build modes):**
```yaml
services:
  any-service:
    # ... build configuration above ...
    dependencies: ["service1", "service2"]
    ports: [8080, 8081]
    env_vars:
      - name: "LOG_LEVEL"
        value: "DEBUG"
      - name: "SECRET_KEY"
        value: "secret"
        from_secret: true
        key: "secret_key"
      - name: "CONFIG_VALUE"
        value: "config"
        from_configmap: true
        key: "config_value"
    resources:
      cpu: "500m"
      memory: "512Mi"
      cpu_request: "100m"
      memory_request: "128Mi"
    health_check:
      path: "/health"
      port: 8080
```

### Build Mode Selection Logic
1. **Command Mode**: If `build_command` is specified, use command-based build
2. **Dockerfile Mode**: If `dockerfile` + `build_context` are specified, use traditional Docker build
3. **ECR Mode**: If `ecr_image` is specified, use pre-built ECR image
4. **External Mode**: If `image` is specified (for external services), use external image

### Build Mode Examples

#### Maven Spring Boot (Command Mode)
```yaml
services:
  java-service:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=java-service:latest"
    build_working_dir: "./services/java-service"
    ports: [8080]
```

#### Gradle (Command Mode)
```yaml
services:
  gradle-service:
    type: "java" 
    build_command: "gradle bootBuildImage --imageName=gradle-service:latest"
    build_working_dir: "./services/gradle-service"
    ports: [8080]
```

#### Traditional Dockerfile (Dockerfile Mode)
```yaml
services:
  python-service:
    type: "python"
    build_context: "./services/python-service"
    dockerfile: "./services/python-service/Dockerfile"
    ports: [8000]
```

### Advanced Command Build Examples

#### Maven with Custom Image Name and Registry
```yaml
services:
  spring-api:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=myregistry.com/spring-api:latest"
    build_working_dir: "./services/spring-api"
    dependencies: ["database"]
    ports: [8080, 8443]
    env_vars:
      - name: "SPRING_PROFILES_ACTIVE"
        value: "local"
```

#### Gradle Multi-Module Project
```yaml
services:
  gradle-microservice:
    type: "java"
    build_command: "gradle :microservice:bootBuildImage --imageName=gradle-microservice:local"
    build_working_dir: "./services/gradle-project"
    ports: [9090]
    env_vars:
      - name: "JAVA_OPTS"
        value: "-Xmx1g -XX:+UseG1GC"
```

#### Custom Build Tool (e.g., Bazel, Pants)
```yaml
services:
  bazel-service:
    type: "java"
    build_command: "bazel run //services/bazel-service:push_image"
    build_working_dir: "./"
    ports: [8080]
```

### Mixed Build Environments

You can use both build modes in the same project:

```yaml
services:
  # Command-based Java service
  payment-service:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=payment-service:latest"
    build_working_dir: "./services/payment-service"
    ports: [8080]
    
  # Dockerfile-based Python service  
  notification-service:
    type: "python"
    build_context: "./services/notification-service"
    dockerfile: "./services/notification-service/Dockerfile"
    ports: [8001]
    
  # External service
  database:
    type: "external"
    image: "postgres:16.4"
    ports: [5432]
```

### Global Configuration
```yaml
global:
  default_resources:
    cpu: "100m"
    memory: "128Mi"
  default_health_check:
    initial_delay_seconds: 30
    period_seconds: 10
    timeout_seconds: 5
    failure_threshold: 3
  default_readiness_check:
    initial_delay_seconds: 5
    period_seconds: 5
    timeout_seconds: 3
    failure_threshold: 3
```

## Common Build Commands

### Maven Spring Boot Build Commands
```bash
# Basic build with default image name
mvn spring-boot:build-image

# Custom image name and tag
mvn spring-boot:build-image -Dspring-boot.build-image.imageName=myservice:latest

# With registry prefix
mvn spring-boot:build-image -Dspring-boot.build-image.imageName=myregistry.com/myservice:v1.0

# With specific builder
mvn spring-boot:build-image -Dspring-boot.build-image.builder=paketobuildpacks/builder:base

# Multi-module project
mvn -pl submodule spring-boot:build-image -Dspring-boot.build-image.imageName=submodule:latest
```

### Gradle Build Commands
```bash
# Basic Gradle build
gradle bootBuildImage

# With custom image name
gradle bootBuildImage --imageName=myservice:latest

# Multi-module project
gradle :submodule:bootBuildImage --imageName=submodule:latest

# With specific builder
gradle bootBuildImage --builder=paketobuildpacks/builder:base --imageName=myservice:latest
```

### Other Build Tools
```bash
# Bazel
bazel run //path/to/service:push_image

# Docker Compose build and tag
docker-compose build myservice && docker tag myproject_myservice myservice:latest

# Custom script
./build-scripts/build-service.sh myservice latest
```

## Usage Examples

### Basic Service Deployment
```bash
# Deploy specific services with dependency resolution
tilt up -- --services=database,redis,ai-agentic-mdr-oscar

# Deploy specific services (build method determined automatically)
tilt up -- --services=ai-agentic-mdr-oscar

# Deploy with debug mode
tilt up -- --services=database,ai-agentic-mdr-oscar --enable_debug=true
```

### Resource Monitoring
```bash
# Validate Kubernetes resources
tilt trigger k8s-resource-validation

# Monitor resource usage
tilt trigger resource-monitor

# Validate manifest generation
tilt trigger manifest-validation
```

## Validation and Testing

### Automated Testing
The system includes comprehensive testing via `test-k8s-manifest-generation.py`:

- **Configuration Validation**: YAML/JSON syntax and structure validation
- **Manifest Generation**: Function structure and component validation
- **Dependency Ordering**: Circular dependency detection and graph validation
- **Resource Configuration**: Port forwarding and labeling validation
- **Extensions Integration**: Tilt extension configuration validation

### Manual Validation
```bash
# Run comprehensive tests
python3 test-k8s-manifest-generation.py

# Validate Tiltfile syntax
python3 -m py_compile Tiltfile

# Check service configuration
tilt config
```

## Monitoring and Debugging

### Built-in Monitoring Resources
1. **k8s-resource-validation**: Validates all Kubernetes resources
2. **resource-monitor**: Monitors cluster and namespace resource usage
3. **manifest-validation**: Validates manifest structure and configuration
4. **deployment-summary**: Shows deployment overview and quick access links
5. **deployment-order-info**: Shows service dependency order

### Service-Specific Monitoring
Each deployed service gets its own monitoring resource:
```bash
# Monitor specific service
tilt trigger <service-name>-monitor
```

## Security Features

### Security Context
All containers run with enhanced security:
- Non-root user (UID 1000)
- No privilege escalation
- Dropped capabilities
- Read-only root filesystem (configurable)

### Secret Management
- Sensitive data stored in Kubernetes Secrets
- Environment variable scrubbing in logs
- Secure handling of database credentials

## Performance Optimizations

### Build Optimization
- **Live Updates**: Language-specific live update rules
- **Build Caching**: Docker layer caching and build optimization
- **File Watching**: Optimized file watching with ignore patterns
- **Parallel Builds**: Configurable parallel build execution

### Resource Management
- **Resource Limits**: Proper CPU/memory limits and requests
- **Health Checks**: Optimized probe timing and failure thresholds
- **Rolling Updates**: Zero-downtime deployment strategy
- **Pod Readiness**: Wait for pod readiness before traffic routing

## Troubleshooting

### Common Issues
1. **Circular Dependencies**: Check dependency graph in deployment-order-info
2. **Resource Limits**: Monitor resource usage with resource-monitor
3. **Health Check Failures**: Validate probe configuration in manifest-validation
4. **Port Conflicts**: Check port forwarding in deployment-summary

### Debug Commands
```bash
# Enable debug mode
tilt up -- --enable_debug=true

# Check resource status
kubectl get all -n dev-$(whoami)

# View service logs
tilt logs <service-name>

# Validate manifests
tilt trigger manifest-validation
```

## Requirements Satisfied

This implementation satisfies the following requirements from the specification:

- **3.1**: ✅ Kubernetes manifests follow production deployment patterns
- **3.2**: ✅ Services use same networking patterns as production
- **3.5**: ✅ Local environment automatically regenerates manifests
- **8.1**: ✅ Supports deploying any combination of services from monorepo

The system provides a comprehensive, production-ready Kubernetes manifest generation system with proper dependency management, security features, and monitoring capabilities.