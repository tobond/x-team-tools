# Tilt Configuration Guide

This guide covers the configuration system for the Tilt implementation.

## Overview

The Tilt system uses configuration files and command-line flags to control deployments. The entire system consists of 3 files totaling 384 lines of code.

## Configuration Files

### Primary Configuration: `.tilt/service-config.yaml`

This is the **only** configuration file you need to modify. It defines all available services and their settings.

#### Structure
```yaml
services:
  service-name:
    type: "service-type"
    # Build configuration (choose one)
    build_context: "path"      # For local builds
    dockerfile: "path"         # For local builds
    image: "image:tag"         # For external images
    
    # Optional configuration
    dependencies: ["service1", "service2"]
    ports: [8000, 8001]
    env_vars:
      - name: "ENV_VAR"
        value: "value"
    health_check:
      path: "/health"          # HTTP check
      command: ["cmd", "arg"]  # Command check
```

### Service Types

| Type | Description | Live Updates |
|------|-------------|--------------|
| `python` | Python applications | ✅ Yes (uvicorn auto-reload) |
| `node`/`nodejs` | Node.js applications | ✅ Yes (nodemon) |
| `java` | Java applications | ✅ Yes (Maven + Spring DevTools) |
| `go` | Go applications | ✅ Yes (binary rebuild) |
| `external` | Pre-built images (databases, etc.) | ❌ No |
| `crewai` | AI agent services | ❌ No |

## Command-Line Configuration

### Basic Usage
```bash
tilt up -- --services=service1,service2 --developer_id=username
```

### Available Flags

| Flag | Description | Default | Example |
|------|-------------|---------|---------|
| `--services` | Comma-separated list of services to deploy | None | `--services=app,database,redis` |
| `--environment` | Predefined environment from environments.yaml | None | `--environment=backend-only` |
| `--developer_id` | Developer namespace identifier | **`$USER`** (automatic) | `--developer_id=john` |

**Note**: The implementation supports core flags. Additional flags like `--ecr_versions`, `--env_overrides`, `--disable_services` are not supported.

## Service Configuration Examples

### Python Application
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
      - name: "REDIS_URL"
        value: "redis://redis:6379"
      - name: "LOG_LEVEL"
        value: "INFO"
    health_check:
      path: "/health"
      port: 8000
```

### External Database
```yaml
services:
  database:
    type: "external"
    image: "postgres:14"
    ports: [5432]
    env_vars:
      - name: "POSTGRES_USER"
        value: "testuser"
      - name: "POSTGRES_PASSWORD"
        value: "testpass"
      - name: "POSTGRES_DB"
        value: "testdb"
    health_check:
      command: ["pg_isready", "-U", "testuser"]
```

### External Redis
```yaml
services:
  redis:
    type: "external"
    image: "redis:7"
    ports: [6379]
    health_check:
      command: ["redis-cli", "ping"]
```

## Build Methods

The system automatically detects the build method based on configuration:

### Local Docker Build
Triggered when `build_context` and `dockerfile` are present:
```yaml
my-service:
  type: "python"
  build_context: "./services/my-service"
  dockerfile: "./services/my-service/Dockerfile"
```

### External Image
Triggered when `type: "external"` and `image` are present:
```yaml
postgres:
  type: "external"
  image: "postgres:14"
```

## Live Updates

Live updates are automatically configured for supported service types:

### Python Services
- **File Sync**: All files synced to `/app/`
- **Auto-Reload**: Uvicorn with `--reload` flag
- **Update Time**: < 2 seconds

### Node.js Services
- **Source Sync**: `/src` directory and package files
- **Dependency Updates**: Auto `npm install` on package.json changes
- **Auto-Restart**: Requires nodemon or similar

### Java Services
- **Source Sync**: `/src` directory and pom.xml
- **Compilation**: Auto `mvn compile` on changes
- **Hot Reload**: Requires Spring DevTools

### Go Services
- **Source Sync**: `/cmd`, `/pkg` directories and go modules
- **Binary Rebuild**: Auto rebuild on file changes
- **Binary Replacement**: Updates running binary

### Requirements for Live Updates
Each service type must follow specific Dockerfile patterns:
```dockerfile
# Python: uvicorn with --reload
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Node.js: nodemon or similar
CMD ["npm", "run", "dev"]  # with "dev": "nodemon src/index.js"

# Java: Spring Boot DevTools
CMD ["mvn", "spring-boot:run"]

# Go: Standard binary execution
CMD ["./main"]
```

## Dependencies

Services can declare dependencies to ensure proper startup order:

```yaml
services:
  api:
    type: "python"
    dependencies: ["database", "redis"]
    # ... rest of config

  database:
    type: "external"
    image: "postgres:14"
    # ... rest of config

  redis:
    type: "external"
    image: "redis:7"
    # ... rest of config
```

**Important**: When deploying a service with dependencies, include all dependencies in the `--services` flag:
```bash
tilt up -- --services=api,database,redis ```

## Port Configuration

Ports are configured directly in the service definition:

```yaml
services:
  my-service:
    ports: [8000, 8001, 9000]
```

Tilt automatically sets up port forwarding from localhost to the container ports.

## Environment Variables

Environment variables are defined in the service configuration:

```yaml
services:
  my-service:
    env_vars:
      - name: "LOG_LEVEL"
        value: "DEBUG"
      - name: "DATABASE_URL"
        value: "postgresql://user:pass@host:5432/db"
      - name: "API_KEY"
        value: "secret-key"
```

**Note**: The implementation does not support runtime environment overrides. All environment variables must be defined in the configuration file.

## Health Checks

Two types of health checks are supported:

### HTTP Health Check
```yaml
health_check:
  path: "/health"
  port: 8000
```

### Command Health Check
```yaml
health_check:
  command: ["pg_isready", "-U", "postgres"]
```

## Namespace Configuration

Each developer gets an isolated namespace:
- Pattern: `dev-{developer_id}`
- Default: `dev-$USER`
- Override: `--developer_id=custom`

Example:
```bash
# Uses dev-john namespace
tilt up -- --services=app --developer_id=john

# Uses dev-$USER namespace
tilt up -- --services=app
```

## Complete Configuration Example

Here's a complete `.tilt/service-config.yaml` example:

```yaml
services:
  # Python API Service
  api:
    type: "python"
    build_context: "./services/api"
    dockerfile: "./services/api/Dockerfile"
    dependencies: ["database", "redis", "auth-service"]
    ports: [8000]
    env_vars:
      - name: "DATABASE_URL"
        value: "postgresql://testuser:testpass@database:5432/apidb"
      - name: "REDIS_URL"
        value: "redis://redis:6379/0"
      - name: "AUTH_SERVICE_URL"
        value: "http://auth-service:8080"
      - name: "LOG_LEVEL"
        value: "INFO"
    health_check:
      path: "/health"
      port: 8000

  # Authentication Service
  auth-service:
    type: "python"
    build_context: "./services/auth"
    dockerfile: "./services/auth/Dockerfile"
    dependencies: ["database"]
    ports: [8080]
    env_vars:
      - name: "DATABASE_URL"
        value: "postgresql://testuser:testpass@database:5432/authdb"
      - name: "JWT_SECRET"
        value: "development-secret"
    health_check:
      path: "/health"
      port: 8080

  # PostgreSQL Database
  database:
    type: "external"
    image: "postgres:14"
    ports: [5432]
    env_vars:
      - name: "POSTGRES_USER"
        value: "testuser"
      - name: "POSTGRES_PASSWORD"
        value: "testpass"
      - name: "POSTGRES_DB"
        value: "apidb"
    health_check:
      command: ["pg_isready", "-U", "testuser"]

  # Redis Cache
  redis:
    type: "external"
    image: "redis:7-alpine"
    ports: [6379]
    health_check:
      command: ["redis-cli", "ping"]

  # Frontend (if needed)
  frontend:
    type: "node"
    build_context: "./services/frontend"
    dockerfile: "./services/frontend/Dockerfile"
    dependencies: ["api"]
    ports: [3000]
    env_vars:
      - name: "API_URL"
        value: "http://localhost:8000"
```

## Deployment Commands

### Deploy Everything
```bash
tilt up -- --services=api,auth-service,database,redis,frontend ```

### Deploy Backend Only
```bash
tilt up -- --services=api,auth-service,database,redis ```

### Deploy Single Service
```bash
tilt up -- --services=api ```

## Supported Features

- ✅ **Environment presets via `--environment` flag**
- ✅ **Custom environments in `.tilt/environments.yaml`**
- ✅ **Live updates for Python, Node.js, Java, and Go services**
- ✅ **Basic dependency management**
- ✅ **Developer namespace isolation**
- ✅ **Health checks (HTTP and command)**
- ✅ **Port forwarding**
- ✅ **Automatic --developer_id defaulting to $USER**

## Not Supported

The implementation does not include:
- ❌ Runtime environment variable overrides
- ❌ ECR image support
- ❌ Dynamic port allocation
- ❌ Service disable flags
- ❌ Build strategy selection
- ❌ Monitoring dashboards
- ❌ Plugin system
- ❌ Command-based builds (Maven, Gradle)

This focused feature set maintains simplicity and follows Tilt best practices.

## Troubleshooting Configuration

### Validate YAML Syntax
```bash
python -c "import yaml; yaml.safe_load(open('.tilt/service-config.yaml'))"
```

### Check Service Exists
```bash
grep "service-name" .tilt/service-config.yaml
```

### View Parsed Configuration
Check Tilt UI at http://localhost:10350 to see how Tilt interpreted your configuration.

## Best Practices

1. **Keep it Simple**: Don't add unnecessary configuration
2. **Use Defaults**: Let the system use default values when possible
3. **Document Services**: Add comments in YAML for team members
4. **Version Control**: Always commit configuration changes
5. **Test Locally**: Test configuration changes before sharing

## Summary

The Tilt configuration system:
- Uses `.tilt/service-config.yaml` for service definitions
- Uses `.tilt/environments.yaml` for environment presets
- Supports `--services`, `--environment`, and `--developer_id` flags
- Automatically detects build methods
- Provides live updates for Python services
- Focuses on simplicity and maintainability

For more details, review the source code:
- `Tiltfile` (90 lines)
- `.tilt/config.star` (42 lines)
- `.tilt/services.star` (252 lines)