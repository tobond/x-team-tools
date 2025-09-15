# Service Configuration Guide

This guide covers the service configuration system for the Tilt development environment.

## Overview

The service configuration system provides a straightforward way to define and deploy services using:

1. **Service Configuration File**: Single YAML file defining all services
2. **Simple Deployment**: Direct service selection via command-line flags
3. **Automatic Build Detection**: Framework detects build method from configuration
4. **Dependency Management**: Basic service dependency handling

## Service Configuration File

All services are defined in `.tilt/service-config.yaml`:

### Service Types Supported

- **python**: Python applications with live reload via uvicorn
- **java**: Java/Spring Boot applications  
- **go**: Go applications
- **node**: Node.js applications
- **external**: External services (PostgreSQL, Redis, etc.)

### Configuration Fields

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| `type` | Service type | Yes | `"python"`, `"external"` |
| `build_context` | Path to build context | For local builds | `"./services/app"` |
| `dockerfile` | Path to Dockerfile | For local builds | `"./services/app/Dockerfile"` |
| `image` | External image | For external services | `"postgres:14"` |
| `dependencies` | List of service dependencies | No | `["database", "redis"]` |
| `ports` | List of exposed ports | No | `[8000, 8001]` |
| `env_vars` | Environment variables | No | See examples below |
| `health_check` | Health check configuration | No | See examples below |

### Example Configurations

#### Python Application with Local Build
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
      - name: "REDIS_URL"
        value: "redis://redis:6379"
      - name: "LOG_LEVEL"
        value: "INFO"
    health_check:
      path: "/health"
      port: 8000
```

#### External Database Service
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

#### External Redis Service
```yaml
services:
  redis:
    type: "external"
    image: "redis:7"
    ports: [6379]
    health_check:
      command: ["redis-cli", "ping"]
```

## Deployment Commands

### Environment-Based Deployment (Recommended)

The simplified implementation **DOES support environments** via `.tilt/environments.yaml`:

```bash
# Deploy using predefined environments
tilt up -- --environment=minimal tilt up -- --environment=backend-only tilt up -- --environment=full-stack tilt up -- --environment=feature-branch ```

### Direct Service Deployment
```bash
# Deploy specific services directly
tilt up -- --services=ai-agentic-test-app 
# Deploy multiple services
tilt up -- --services=ai-agentic-test-app,database,redis 
# Stop all services
tilt down
```

## Build Methods

The framework automatically detects the build method based on service configuration:

### Local Docker Build
Services with `build_context` and `dockerfile` fields use local Docker builds:
- Live updates are configured for Python services (sync files + uvicorn reload)
- Image names are automatically generated for Tilt tracking
- Builds are cached for efficiency

### External Images
Services with `type: "external"` and `image` field use pre-built images:
- Pulls directly from Docker Hub or other registries
- No build step required
- Suitable for databases and infrastructure services

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

Example Dockerfiles for live updates:
```dockerfile
# Python with uvicorn
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Node.js with nodemon
FROM node:18-slim
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]  # with "dev": "nodemon src/index.js"

# Java with Spring Boot DevTools
FROM maven:3.8-openjdk-17
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
CMD ["mvn", "spring-boot:run"]

# Go with binary rebuild
FROM golang:1.21-alpine
WORKDIR /app
COPY go.* .
RUN go mod download
COPY . .
RUN go build -o main ./cmd
CMD ["./main"]
```

## Service Dependencies

Dependencies ensure services start in the correct order:

```yaml
services:
  app:
    type: "python"
    dependencies: ["database", "redis"]  # Waits for these services
    # ... other configuration
```

**Note**: Dependencies only work when all dependent services are deployed together. Use `--services` to include all required services.

## Port Configuration

Ports are configured directly in the service definition:

```yaml
services:
  my-service:
    ports: [8000, 8001]  # Exposes ports 8000 and 8001
```

Tilt automatically sets up port forwarding from localhost to the container ports.

## Health Checks

Health checks verify service readiness:

### HTTP Health Check
```yaml
health_check:
  path: "/health"
  port: 8000
```

### Command Health Check
```yaml
health_check:
  command: ["pg_isready", "-U", "testuser"]
```

## Adding New Services

To add a new service:

1. Add service definition to `.tilt/service-config.yaml`
2. Create service directory in `services/` (for local builds)
3. Deploy with `tilt up -- --services=<service-name> --developer_id=$(whoami)`

### Example: Adding MySQL
```yaml
mysql:
  type: "external"
  image: "mysql:8.0"
  ports: [3306]
  env_vars:
    - name: "MYSQL_ROOT_PASSWORD"
      value: "testpass"
    - name: "MYSQL_DATABASE"
      value: "testdb"
  health_check:
    command: ["mysqladmin", "ping", "-h", "localhost"]
```

## Troubleshooting

### Service Not Deploying
- Ensure service is defined in `.tilt/service-config.yaml`
- Check service name spelling in `--services` flag
- Verify build context path exists (for local builds)
- Check Tilt UI at http://localhost:10350 for errors

### Dependencies Not Working
- Include all dependent services in `--services` flag
- Example: `--services=app,database,redis`

### Port Already in Use
- Check for other services using the same port
- Stop conflicting services or use different ports

### Live Updates Not Working
- Ensure Python service uses uvicorn with `--reload` flag
- Verify Dockerfile WORKDIR matches sync path (`/app/`)
- Check file permissions in container

## Implementation Details

The implementation consists of:

1. **Tiltfile** (90 lines): Main orchestration
2. **.tilt/config.star** (42 lines): Configuration parsing
3. **.tilt/services.star** (252 lines): Service deployment logic

Total: 384 lines of focused, maintainable code.

## Environment Configuration

Environments are defined in `.tilt/environments.yaml`:

```yaml
environments:
  minimal:
    description: "Essential services only"
    services: ["ai-agentic-test-app"]
  
  backend-only:
    description: "Backend APIs and databases"
    services: ["ai-agentic-test-app", "database", "redis"]
  
  full-stack:
    description: "Complete environment"
    services: ["ai-agentic-test-app", "database", "redis", "frontend"]
  
  feature-branch:
    description: "Lightweight for feature development"
    services: ["ai-agentic-test-app", "redis"]
```

## Limitations

The implementation does not support:
- Dynamic port allocation
- ECR image version overrides  
- Environment variable overrides at runtime
- Service disable flags
- Monitoring dashboards
- Command-based builds (Maven, Gradle)

These features are not included to maintain simplicity and fast feedback loops.