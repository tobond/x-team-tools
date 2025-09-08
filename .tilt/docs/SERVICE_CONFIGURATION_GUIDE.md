# Service Configuration and Customization Guide

This guide covers the service configuration and customization features implemented in the Tilt development environment, allowing developers to dynamically control service deployment, ECR image versions, environment variables, and build strategies.

## Overview

The service configuration and customization system provides these main capabilities:

1. **Dynamic Port Allocation**: Automatic conflict-free port forwarding for all services
2. **Service Enable/Disable**: Control which services are deployed
3. **ECR Image Version Selection**: Override ECR image versions at runtime
4. **Build Strategy Switching**: Choose between local builds and ECR images
5. **Environment Variable Management**: Override environment variables per service
6. **User-Defined Environments**: Create custom environment configurations

## Features

### 1. Dynamic Port Allocation System

The framework automatically handles port forwarding for all services without conflicts, eliminating the need for manual port management.

#### Key Features

- **Hash-Based Port Generation**: Deterministic port assignment based on service name and container port
- **Standard Port Preservation**: Database services keep familiar ports (5432 for PostgreSQL, 6379 for Redis)
- **Conflict Avoidance**: Automatic detection and resolution of port conflicts
- **Service Agnostic**: Works with any service configuration without hardcoded mappings

#### Port Allocation Algorithm

```bash
# Standard ports are preserved for familiarity
PostgreSQL: 5432 → 5432
Redis: 6379 → 6379
MySQL: 3306 → 3306
MongoDB: 27017 → 27017
Elasticsearch: 9200 → 9200

# Application services get hash-based ports in range 8000-9999
hash_input = service_name + container_port + port_index
local_port = 8000 + (hash(hash_input) % 2000)
```

#### Benefits

- **No Configuration Required**: Ports are assigned automatically
- **Deterministic**: Same service always gets the same ports
- **Conflict-Free**: Multiple services can run simultaneously without port conflicts
- **Developer-Friendly**: Database ports remain familiar and predictable

#### Port Mapping Dashboard

The system provides a dynamic dashboard showing actual port mappings:

```bash
# View current port mappings
tilt ui  # Navigate to "port-mapping-dashboard" resource
```

Example output:
```
🔗 PORT MAPPING DASHBOARD
======================
Service -> localhost:local_port:container_port

  ai-agentic-test-app -> localhost:8123:8000
  database -> localhost:5432:5432
  redis -> localhost:6379:6379
```

### 2. Service Enable/Disable Configuration System

Control which services are deployed without modifying configuration files.

#### Usage Examples

```bash
# Deploy specific services only
tilt up -- --services=database,redis,ai-agentic-mdr-oscar

# Deploy services but exclude specific ones
tilt up -- --services=database,redis,app1,app2,app3 --disable_services=app2,app3

# Disable infrastructure services for application-only testing
tilt up -- --services=app1,app2,database,redis --disable_services=database,redis
```

#### Implementation Details

- Services specified in `--disable_services` are filtered out from the deployment list
- Disabled services are shown in debug output and customization dashboard
- Dependencies are automatically handled - dependent services won't deploy if their dependencies are disabled

### 2. ECR Image Version Selection and Management

Override ECR image versions at runtime without modifying service configuration files.

#### Usage Examples

```bash
# Use specific versions for services
tilt up -- --services=app1,app2 --ecr_versions=app1:v1.2.3,app2:latest

# Mix different versions
tilt up -- --services=app1,app2,app3 --ecr_versions=app1:v1.2.3,app2:develop,app3:feature-branch

# Use latest for some, specific versions for others
tilt up -- --services=app1,app2 --ecr_versions=app1:v2.0.0
```

#### Implementation Details

- ECR version overrides are applied during service customization
- Original ECR image tags are preserved in configuration
- Version information is tracked and displayed in dashboards
- Authentication and pulling are handled automatically

### 3. Local Build vs ECR Image Switching

Dynamically choose between building services locally or using ECR images.

#### Build Strategies

- **`local`** (default): Build all services locally with live updates
- **`ecr`**: Use ECR images for all services  
- **`mixed`**: Use ECR for some services, local builds for others

#### Usage Examples

```bash
# Build all services locally (default)
tilt up -- --services=app1,app2,app3 --build_strategy=local

# Use ECR for all services
tilt up -- --services=app1,app2,app3 --build_strategy=ecr

# Mixed strategy - specify which to build locally
tilt up -- --services=app1,app2,app3 --build_strategy=mixed --build_local=app1,app2

# Override strategy for specific development workflow
tilt up -- --services=app1,app2,database --build_strategy=mixed --build_local=app1
```

#### Implementation Details

- Build strategy is determined during service deployment
- Local builds include comprehensive live update rules
- ECR builds include authentication and caching
- Strategy conflicts are detected and reported

### 4. Service-Specific Environment Variable Management

Override environment variables for specific services at runtime.

#### Usage Examples

```bash
# Override single variable
tilt up -- --services=app1 --env_overrides=app1:LOG_LEVEL=DEBUG

# Override multiple variables for one service
tilt up -- --services=app1 --env_overrides=app1:LOG_LEVEL=DEBUG,app1:PORT=9000,app1:CACHE_SIZE=1000

# Override variables for multiple services
tilt up -- --services=app1,app2 --env_overrides=app1:LOG_LEVEL=DEBUG,app2:ENVIRONMENT=staging

# Mix with other customizations
tilt up -- --services=app1,app2 \
           --build_strategy=mixed \
           --build_local=app1 \
           --ecr_versions=app2:v1.2.3 \
           --env_overrides=app1:LOG_LEVEL=DEBUG,app2:CACHE_SIZE=2000
```

#### Implementation Details

- Environment overrides are applied during service customization
- New variables are added, existing variables are updated
- Original configuration is preserved
- Overrides are validated and displayed in dashboards

## Configuration Files

### Service Configuration (`.tilt/service-config.yaml`)

The main service configuration file defines all available services and their properties:

**Note**: This file should only contain service definitions. Environment combinations are now defined separately in `.tilt/environments.yaml` to maintain framework-project separation.

**Example 1: Local Dockerfile Build**
```yaml
services:
  python-api-local:
    type: "python"
    build_context: "./services/python-api"
    dockerfile: "./services/python-api/Dockerfile"
    dependencies: ["database", "redis"]
    ports: [8080, 8081]
    env_vars:
      - name: "LOG_LEVEL"
        value: "DEBUG"
      - name: "ENVIRONMENT"
        value: "local"
    resources:
      cpu: "500m"
      memory: "512Mi"
    health_check:
      path: "/health"
      port: 8080
```

**Example 2: ECR Pre-built Image**
```yaml
services:
  python-api-ecr:
    type: "python"
    ecr_image: "123456789.dkr.ecr.us-east-1.amazonaws.com/python-api:latest"
    dependencies: ["database", "redis"]
    ports: [8080, 8081]
    env_vars:
      - name: "LOG_LEVEL"
        value: "INFO"
      - name: "ENVIRONMENT"
        value: "production"
    resources:
      cpu: "500m"
      memory: "512Mi"
    health_check:
      path: "/health"
      port: 8080
```

**Example 3: Command Build (Maven/Gradle)**
```yaml
services:
  java-api-command:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=java-api:latest"
    build_working_dir: "./services/java-api"
    dependencies: ["database"]
    ports: [9090]
    env_vars:
      - name: "SPRING_PROFILES_ACTIVE"
        value: "local"
    resources:
      cpu: "1000m"
      memory: "1Gi"
    health_check:
      path: "/actuator/health"
      port: 9090
```

### Environment Configuration (`.tilt/environments.yaml`)

User-defined environment configurations that specify which services to deploy together:

```yaml
# .tilt/environments.yaml
environments:
  # Minimal development environment
  minimal:
    description: "Essential services only for lightweight development"
    services: ["ai-agentic-test-app"]
    build_strategy: "local"

  # Backend development with databases
  backend-only:
    description: "Backend APIs and databases without frontend components"
    services: ["ai-agentic-test-app", "database", "redis"]
    build_strategy: "mixed"

  # Complete development environment
  full-stack:
    description: "Complete environment with all frontend, backend, and data services"
    services: ["ai-agentic-test-app", "database", "redis", "frontend"]
    build_strategy: "mixed"

  # Custom user environments
  my-demo-setup:
    description: "Custom demo environment"
    services: ["ai-agentic-test-app", "redis"]
    build_strategy: "local"

# Global environment settings
global:
  default_build_strategy: "local"
  allowed_build_strategies: ["local", "ecr", "mixed"]
```

### Tilt Configuration (`tilt_config.json`)

Team-wide Tilt settings and defaults:

```json
{
  "team_settings": {
    "default_developer_namespace_prefix": "dev-",
    "default_cluster_type": "docker-desktop", 
    "default_build_strategy": "local"
  }
}
```

## Dashboards and Monitoring

The system provides several dashboards for monitoring and managing service customizations:

### 1. Service Customization Dashboard

Shows current customizations and provides usage examples.

- **Resource Name**: `service-customization-dashboard`
- **Access**: Available in Tilt UI under "customization" label
- **Content**: Disabled services, ECR overrides, environment overrides, build strategy

### 2. Build Strategy Dashboard

Displays build strategies and ECR versions for all services.

- **Resource Name**: `build-strategy-dashboard`
- **Access**: Available in Tilt UI under "build-strategy" label
- **Content**: Service build strategies, ECR versions, usage commands

### 3. ECR Version Monitor

Monitors ECR image availability and versions.

- **Resource Name**: `ecr-version-monitor`
- **Access**: Manual trigger in Tilt UI
- **Content**: ECR image status, version information, management commands

### 4. Service Selection Guide

Comprehensive guide for service selection and customization.

- **Resource Name**: `service-selection-guide`
- **Access**: Available when no services are specified
- **Content**: Available services, dependencies, usage examples

## Advanced Usage

### Complex Deployment Scenarios

```bash
# Development scenario: Local build for main app, ECR for dependencies
tilt up -- --services=app1,app2,database,redis,mock-api \
           --build_strategy=mixed \
           --build_local=app1 \
           --ecr_versions=app2:develop \
           --env_overrides=app1:LOG_LEVEL=DEBUG,app1:ENVIRONMENT=dev \
           --disable_services=mock-api

# Testing scenario: Specific versions with custom environment
tilt up -- --services=app1,app2,database \
           --ecr_versions=app1:v1.2.3,app2:v2.0.0 \
           --env_overrides=app1:ENVIRONMENT=test,app2:ENVIRONMENT=test

# Performance testing: All ECR with production-like settings
tilt up -- --services=app1,app2,app3,database,redis \
           --build_strategy=ecr \
           --env_overrides=app1:LOG_LEVEL=WARN,app2:LOG_LEVEL=WARN,app3:LOG_LEVEL=WARN
```

### Integration with CI/CD

The customization system can be integrated with CI/CD pipelines:

```bash
# Use in CI for integration testing
tilt up -- --services=$SERVICES_TO_TEST \
           --ecr_versions=$ECR_VERSIONS \
           --env_overrides=$TEST_ENV_OVERRIDES \
           --build_strategy=ecr

# Use in development automation
tilt up -- --services=$(cat .dev-services) \
           --build_strategy=mixed \
           --build_local=$(git diff --name-only HEAD~1 | grep -o '^[^/]*' | sort -u | tr '\n' ',')
```

## Troubleshooting

### Common Issues

1. **Service Not Found**: Ensure service is defined in `.tilt/service-config.yaml`
2. **ECR Authentication**: Run `aws ecr get-login-password` before using ECR images
3. **Build Context Missing**: Ensure build context directory exists for local builds
4. **Dependency Conflicts**: Check service dependencies when disabling services

### Debug Mode

Enable debug mode for detailed information:

```bash
tilt up -- --services=app1,app2 --enable_debug=true --env_overrides=app1:LOG_LEVEL=DEBUG
```

Debug mode shows:
- Applied customizations
- Build strategy decisions
- ECR version overrides
- Environment variable changes
- Service filtering results

### Validation

Use the customization validator to check for issues:

- **Resource**: `service-customization-validator`
- **Trigger**: Manual in Tilt UI
- **Checks**: Configuration conflicts, missing dependencies, invalid overrides

## API Reference

### Configuration Functions

#### `apply_service_customizations(service_name, service_config, tilt_config)`

Applies runtime customizations to a service configuration.

**Parameters:**
- `service_name`: Name of the service
- `service_config`: Original service configuration
- `tilt_config`: Tilt runtime configuration with customizations

**Returns:** Customized service configuration

#### `get_effective_build_strategy(service_name, service_config, tilt_config)`

Determines the effective build strategy for a service.

**Parameters:**
- `service_name`: Name of the service
- `service_config`: Service configuration (may include customizations)
- `tilt_config`: Tilt runtime configuration

**Returns:** `"local"` or `"ecr"`

### Dashboard Functions

#### `create_service_customization_dashboard(tilt_config, service_configs)`

Creates the main customization dashboard.

#### `create_build_strategy_dashboard(services_info, tilt_config)`

Creates the build strategy dashboard.

#### `create_ecr_version_monitor(services_info)`

Creates the ECR version monitoring dashboard.

## Best Practices

1. **Use Mixed Strategy**: Combine local builds for active development with ECR for stable dependencies
2. **Version Pinning**: Use specific ECR versions for reproducible environments
3. **Environment Isolation**: Use different environment overrides for different testing scenarios
4. **Dependency Management**: Be careful when disabling services that others depend on
5. **Resource Monitoring**: Use dashboards to monitor customizations and their effects
6. **Debug Mode**: Enable debug mode when troubleshooting customization issues

## Adding New External Services

### Zero-Code Service Addition

The framework uses a completely service-agnostic approach. Adding **any** external service requires **zero code changes** - just add to `.tilt/service-config.yaml`:

```yaml
# Example: Adding MySQL database
mysql:
  type: "external"
  image: "mysql:8.0"
  ports: [3306]
  env_vars:
    - name: "MYSQL_ROOT_PASSWORD"
      value: "testpass"
    - name: "MYSQL_DATABASE"  
      value: "testdb"
    - name: "MYSQL_USER"
      value: "testuser"
    - name: "MYSQL_PASSWORD"
      value: "testpass"
  resources:
    cpu: "500m"
    memory: "1Gi"
  health_check:
    command: ["mysqladmin", "ping", "-h", "localhost", "-u", "testuser", "-ptestpass"]

# Example: Adding Elasticsearch
elasticsearch:
  type: "external" 
  image: "elasticsearch:8.11.0"
  ports: [9200, 9300]
  env_vars:
    - name: "discovery.type"
      value: "single-node"
    - name: "ES_JAVA_OPTS"
      value: "-Xms512m -Xmx512m"
  resources:
    cpu: "1000m"
    memory: "2Gi"

# Example: Adding RabbitMQ
rabbitmq:
  type: "external"
  image: "rabbitmq:3-management"
  ports: [5672, 15672]
  env_vars:
    - name: "RABBITMQ_DEFAULT_USER"
      value: "testuser"
    - name: "RABBITMQ_DEFAULT_PASS"
      value: "testpass"
  resources:
    cpu: "250m"
    memory: "512Mi"
  health_check:
    command: ["rabbitmq-diagnostics", "ping"]
```

### Universal Compatibility

The service-agnostic framework supports **any Docker-based service**:

- **Databases**: PostgreSQL, MySQL, MongoDB, CouchDB, CockroachDB
- **Caches**: Redis, Memcached, Hazelcast
- **Message Queues**: RabbitMQ, Apache Kafka, NATS
- **Search Engines**: Elasticsearch, OpenSearch, Solr
- **Monitoring**: Prometheus, Grafana, Jaeger
- **Custom Services**: Any Docker image

### Standard Configuration Pattern

All external services follow the same configuration pattern:

```yaml
service-name:
  type: "external"              # Always "external" for infrastructure
  image: "image:tag"            # Any Docker image
  ports: [port1, port2]         # Exposed ports
  env_vars:                     # Environment variables
    - name: "ENV_NAME"
      value: "env_value"
  resources:                    # Resource limits
    cpu: "500m"
    memory: "1Gi"
  health_check:                 # Health check (optional)
    command: ["health", "check", "command"]
```

### Benefits

- **Zero Maintenance**: No code changes for new services
- **Universal**: Works with any Docker image
- **Standard Credentials**: Consistent `testuser`/`testpass` pattern
- **Auto Configuration**: ConfigMaps and Secrets generated automatically
- **Health Monitoring**: Configurable health checks per service

## Requirements Satisfied

This implementation satisfies the following requirements from the specification:

- **Requirement 5.1**: Service selection and configuration management ✅
- **Requirement 5.2**: ECR image version selection ✅
- **Requirement 5.3**: Local build vs ECR image switching ✅
- **Requirement 2.4**: Multiple image sources support ✅
- **NEW**: Service-agnostic external service deployment ✅

The system provides comprehensive service configuration and customization capabilities while maintaining the modular architecture and safety-first approach of the Tilt development environment.