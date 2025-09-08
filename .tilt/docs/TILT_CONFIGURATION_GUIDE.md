# Tilt Configuration Guide

This guide covers advanced configuration options and customization for the Tilt-based development environment.

## Table of Contents

- [Configuration Files](#configuration-files)
- [Service Configuration](#service-configuration)
- [Developer Settings](#developer-settings)
- [Build Strategies](#build-strategies)
- [Live Updates](#live-updates)
- [Resource Management](#resource-management)
- [External Services](#external-services)
- [Advanced Features](#advanced-features)

## Configuration Files

### Main Configuration Files

| File | Purpose | Scope |
|------|---------|-------|
| `Tiltfile` | Main orchestration logic | Global |
| `.tilt/service-config.yaml` | Service definitions | Team-wide |
| `.tilt/environments.yaml` | User-defined environments | Team-wide |
| `.tilt/developer-config.yaml` | Developer preferences | Individual |
| `tilt_config.json` | Tilt-specific settings | Team-wide |

### Configuration Flag Support

The system supports both legacy and modern configuration flags for backward compatibility:

| Purpose | Modern Flag | Legacy Flag | Example |
|---------|-------------|-------------|---------|
| Service Selection | `--services` | `enable_services` (positional) | `--services=app1,app2` |
| Developer ID | `--developer_id` | Same | `--developer_id=john` |
| Debug Mode | `--enable_debug` | Same | `--enable_debug=true` |

#### Usage Examples
```bash
# Modern named flags (recommended)
tilt up -- --services=app1,app2 --developer_id=john

# Legacy positional services (still supported)
tilt up app1 app2 -- --developer_id=john

# Mixed usage (both work)
tilt up -- --services=app1,app2 --developer_id=john --enable_debug=true
```

### Configuration Hierarchy

Settings are applied in this order (later overrides earlier):
1. Global defaults in `Tiltfile`
2. Team settings in `.tilt/service-config.yaml`
3. Developer settings in `.tilt/developer-config.yaml`
4. Command-line arguments

## Service Configuration

### Basic Service Definition

```yaml
# .tilt/service-config.yaml
services:
  my-service:
    type: "python"                    # Application type
    build_context: "./my-service"     # Build directory
    dockerfile: "./my-service/Dockerfile"
    ecr_image: "123456789.dkr.ecr.us-east-1.amazonaws.com/my-service"
    dependencies: ["database"]       # Service dependencies
    ports: [8080, 8081]             # Exposed ports
    env_vars:                       # Environment variables
      - name: "LOG_LEVEL"
        value: "DEBUG"
    resources:                      # Resource limits
      cpu: "500m"
      memory: "512Mi"
```

### Supported Service Types

#### Python Services
```yaml
my-python-service:
  type: "python"
  build_context: "./python-service"
  dockerfile: "./python-service/Dockerfile"
  live_update:
    sync_rules:
      - local_path: "./python-service/src"
        remote_path: "/app/src"
    run_commands:
      - "pip install -r requirements.txt"
    restart_on:
      - "requirements.txt"
```

#### Java Services
```yaml
my-java-service:
  type: "java"
  build_context: "./java-service"
  dockerfile: "./java-service/Dockerfile"
  build_args:
    - "MAVEN_OPTS=-Xmx1g"
  live_update:
    sync_rules:
      - local_path: "./java-service/target/classes"
        remote_path: "/app/classes"
    restart_container: true
```

#### Go Services
```yaml
my-go-service:
  type: "go"
  build_context: "./go-service"
  dockerfile: "./go-service/Dockerfile"
  live_update:
    sync_rules:
      - local_path: "./go-service/cmd"
        remote_path: "/app/cmd"
      - local_path: "./go-service/pkg"
        remote_path: "/app/pkg"
    run_commands:
      - "go build -o /app/main ./cmd"
    restart_container: true
```

#### Node.js Services
```yaml
my-node-service:
  type: "nodejs"
  build_context: "./node-service"
  dockerfile: "./node-service/Dockerfile"
  live_update:
    sync_rules:
      - local_path: "./node-service/src"
        remote_path: "/app/src"
    run_commands:
      - "npm install"
    restart_on:
      - "package.json"
```

### Advanced Service Configuration

#### Health Checks
```yaml
my-service:
  health_check:
    path: "/health"
    port: 8080
    initial_delay_seconds: 30
    period_seconds: 10
    timeout_seconds: 5
    failure_threshold: 3
```

#### Resource Limits
```yaml
my-service:
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
```

#### Environment Variables
```yaml
my-service:
  env_vars:
    - name: "DATABASE_URL"
      value: "postgresql://localhost:5432/mydb"
    - name: "SECRET_KEY"
      valueFrom:
        secretKeyRef:
          name: "my-secret"
          key: "secret-key"
    - name: "CONFIG_MAP_VALUE"
      valueFrom:
        configMapKeyRef:
          name: "my-config"
          key: "config-value"
```

## Developer Settings

### Basic Developer Configuration

```yaml
# .tilt/developer-config.yaml
developer:
  id: "john-doe"
  namespace: "dev-john-doe"

cluster:
  type: "docker-desktop"
  name: "tilt-dev"

services:
  enabled:
    - service1
    - service2
  # Services are configured with build methods in .tilt/service-config.yaml
  # No need to specify build methods here
```

### Advanced Developer Settings

```yaml
developer:
  id: "john-doe"
  preferences:
    debug_mode: true
    auto_open_ui: true
    live_updates: true

resources:
  namespace_quota:
    cpu: "4"
    memory: "8Gi"
    storage: "20Gi"
  default_resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"

port_forwards:
  enabled: true
  custom_ports:
    service1: 8080
    service2: 8090
```

## Automatic Build Method Detection

### Dockerfile Builds with Live Updates

```yaml
# Fast development cycle with live updates
services:
  my-service:
    type: "python"
    build_context: "./my-service"
    dockerfile: "./my-service/Dockerfile"
    # Live updates automatically enabled for local builds
```

### ECR Pre-built Images

```yaml
# Use stable ECR images for dependencies
services:
  stable-service:
    type: "python"
    ecr_image: "123456789.dkr.ecr.us-east-1.amazonaws.com/stable-service:v1.2.3"
```

### Command-based Builds

```yaml
# Use build commands (Maven, Gradle, etc.)
services:
  java-service:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=java-service:latest"
    build_working_dir: "./java-service"
```

## Live Updates

### Python Live Updates

```yaml
python-service:
  live_update:
    sync_rules:
      - local_path: "./src"
        remote_path: "/app/src"
      - local_path: "./requirements.txt"
        remote_path: "/app/requirements.txt"
    run_commands:
      - "pip install -r requirements.txt"
    restart_on:
      - "requirements.txt"
    ignore_patterns:
      - "**/*.pyc"
      - "**/__pycache__"
```

### Java Live Updates

```yaml
java-service:
  live_update:
    sync_rules:
      - local_path: "./target/classes"
        remote_path: "/app/classes"
    restart_container: true
    fall_back_on:
      - "pom.xml"
      - "src/main/resources"
```

### Go Live Updates

```yaml
go-service:
  live_update:
    sync_rules:
      - local_path: "./cmd"
        remote_path: "/app/cmd"
      - local_path: "./pkg"
        remote_path: "/app/pkg"
    run_commands:
      - "go build -o /app/main ./cmd"
    restart_container: true
    fall_back_on:
      - "go.mod"
      - "go.sum"
```

### Node.js Live Updates

```yaml
node-service:
  live_update:
    sync_rules:
      - local_path: "./src"
        remote_path: "/app/src"
      - local_path: "./package.json"
        remote_path: "/app/package.json"
    run_commands:
      - "npm install"
    restart_on:
      - "package.json"
    ignore_patterns:
      - "**/node_modules"
      - "**/*.log"
```

## Resource Management

### Namespace Quotas

```yaml
resources:
  namespace_quota:
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.cpu: "4"
    limits.memory: "8Gi"
    persistentvolumeclaims: "10"
    services: "20"
    secrets: "10"
    configmaps: "10"
```

### Service Resource Limits

```yaml
services:
  resource-intensive-service:
    resources:
      requests:
        cpu: "500m"
        memory: "1Gi"
      limits:
        cpu: "2000m"
        memory: "4Gi"
```

### Global Resource Defaults

```yaml
global:
  default_resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
```

## External Services

### Database Configuration

```yaml
external_services:
  database:
    enabled: true
    type: "postgresql"
    version: "13"
    resources:
      cpu: "250m"
      memory: "512Mi"
    storage: "1Gi"
    env_vars:
      - name: "POSTGRES_DB"
        value: "myapp"
      - name: "POSTGRES_USER"
        value: "developer"
      - name: "POSTGRES_PASSWORD"
        value: "password"
```

### Redis Configuration

```yaml
external_services:
  redis:
    enabled: true
    version: "6"
    resources:
      cpu: "100m"
      memory: "256Mi"
```

### Mock Services

```yaml
# Example: Generic mock service configuration
# Users define their own mock services based on their needs
services:
  my-mock-service:
    type: "external"
    image: "mockserver/mockserver:latest"
    ports: [9000]
    env_vars:
      - name: "MOCKSERVER_INITIALIZATION_JSON_PATH"
        value: "/config/expectations.json"
    resources:
      cpu: "100m"
      memory: "256Mi"
    # Volume mount for mock configuration
    volumes:
      - name: "mock-config"
        mount_path: "/config"
        config_map: "my-mock-service-config"
```

## Advanced Features

### Custom Build Commands

```yaml
services:
  custom-build-service:
    custom_build:
      command: "./scripts/custom-build.sh"
      deps: ["./src", "./Dockerfile"]
      tag: "custom-build-service"
```

### Multi-Stage Builds

```yaml
services:
  multi-stage-service:
    dockerfile: "./Dockerfile.multi"
    target: "development"
    build_args:
      - "BUILD_ENV=development"
```

### Conditional Configuration

```yaml
# Different settings based on environment
environments:
  development:
    services:
      my-service:
        replicas: 1
        debug: true
  
  testing:
    services:
      my-service:
        replicas: 2
        debug: false
```

### Service Dependencies

```yaml
services:
  web-service:
    dependencies: ["database", "redis"]
    
  api-service:
    dependencies: ["database"]
    
  worker-service:
    dependencies: ["database", "redis", "api-service"]
```

## Command Line Usage

### Environment-Based Commands (Recommended)

```bash
# Modern approach: Use predefined environments
./scripts/setup-environment.sh minimal
./scripts/setup-environment.sh backend-only  
./scripts/setup-environment.sh full-stack

# Custom environments
./scripts/setup-environment.sh my-demo-setup
./scripts/setup-environment.sh integration-test

# With options
./scripts/setup-environment.sh backend-only --developer-id=john-doe
./scripts/setup-environment.sh minimal --dry-run
```

### Direct Service Commands (Legacy)

```bash
# Start with default configuration
tilt up

# Start specific services (supports both flag formats)
tilt up -- --services=service1,service2
tilt up service1 service2  # Alternative positional format

# Start with developer ID
tilt up -- --developer_id=john-doe

# Enable debug mode
tilt up -- --enable_debug=true

# Deploy specific services (build methods from configuration)
tilt up -- --services=service1,service2
```

### Advanced Commands

```bash
# Start with custom configuration file
tilt up --file=./custom-tiltfile

# Advanced service customization
tilt up -- --services=app1,app2 \
           --developer_id=$(whoami) \
           --enable_debug=true

# Service discovery and management
./scripts/list-services.sh
./scripts/service-info.sh my-service

# Environment management
./scripts/setup-environment.sh --help  # Shows all available environments
```

## Troubleshooting Configuration

### Validation Commands

```bash
# Validate Tilt configuration
tilt validate

# Check service configuration
./scripts/validate-service-config.sh

# Verify cluster connectivity
kubectl cluster-info

# Check resource usage
kubectl top nodes
kubectl top pods -n dev-$(whoami)
```

### Common Issues

#### Service Won't Start
1. Check service logs in Tilt UI
2. Verify dependencies are running
3. Check resource limits
4. Validate configuration syntax

#### Live Updates Not Working
1. Verify sync paths are correct
2. Check file permissions
3. Ensure container has required tools
4. Review ignore patterns

#### Resource Constraints
1. Check namespace quotas
2. Monitor cluster resources
3. Adjust service limits
4. Scale down unused services

## Best Practices

1. **Use meaningful service names** that reflect their purpose
2. **Set appropriate resource limits** to prevent resource starvation
3. **Configure health checks** for reliable service management
4. **Use live updates** for fast development cycles
5. **Organize services by dependencies** for proper startup ordering
6. **Keep configuration in version control** for team consistency
7. **Document custom configurations** for team knowledge sharing
8. **Test configuration changes** before committing
9. **Use environment-specific overrides** for different deployment scenarios
10. **Monitor resource usage** to optimize performance

For more examples and advanced configurations, see the `examples/` directory in this repository.