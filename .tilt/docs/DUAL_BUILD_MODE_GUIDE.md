# Automatic Build Method Detection Guide

## Overview

The x-team-tools Tilt environment automatically detects the appropriate build method for each service based on the configuration in `.tilt/service-config.yaml`. No command-line arguments or manual build strategy selection is required.

## Automatic Detection Logic

The system automatically determines the build method based on service configuration fields:

1. **External Services** (services with `type: "external"` + `image` field) → External image
2. **ECR Services** (services with `ecr_image` field) → ECR build  
3. **Command Builds** (services with `build_command` field) → Command build
4. **Dockerfile Builds** (services with `build_context` field) → Dockerfile build

## Build Method Examples

### External Services (Databases, Cache, etc.)

```yaml
services:
  database:
    type: "external"
    image: "postgres:16.4"
    ports: [5432]
    env_vars:
      - name: "POSTGRES_PASSWORD"
        value: "testpass"
```

**Detection**: Framework detects `type: "external"` + `image` field → Uses external image directly.

### ECR Pre-built Images

```yaml
services:
  stable-service:
    type: "python"
    ecr_image: "123456789.dkr.ecr.us-east-1.amazonaws.com/stable-service:v1.2.3"
    ports: [8080]
```

**Detection**: Framework detects `ecr_image` field → Pulls from ECR registry.

### Command-Based Builds (Maven, Gradle, etc.)

```yaml
services:
  payment-service:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=payment-service:latest"
    build_working_dir: "./services/payment-service"
    ports: [8080]
```

**Detection**: Framework detects `build_command` field → Uses custom build command.

### Dockerfile-Based Builds

```yaml
services:
  notification-service:
    type: "python"
    build_context: "./services/notification-service"
    dockerfile: "./services/notification-service/Dockerfile"
    ports: [8001]
```

**Detection**: Framework detects `build_context` + `dockerfile` fields → Uses traditional Docker build.

## Build Method Benefits

### External Images
- ✅ **Fastest**: No build time required
- ✅ **Reliable**: Uses stable, tested images
- ✅ **Consistent**: Same image across all environments
- Use for: Databases, caches, message queues, stable services

### ECR Images  
- ✅ **Fast**: Pre-built images from registry
- ✅ **Consistent**: Same build process as CI/CD
- ✅ **Stable**: Production-tested images
- Use for: Stable services, dependencies, integration testing

### Command Builds
- ✅ **Tool Integration**: Leverages existing build toolchain
- ✅ **Cached**: Uses existing build caches (Maven ~/.m2, Gradle ~/.gradle)
- ✅ **Consistent**: Same process as local development
- Use for: Maven, Gradle, Bazel projects with built-in image generation

### Dockerfile Builds
- ✅ **Flexible**: Complete control over build environment
- ✅ **Customizable**: Custom base images, multi-stage builds
- ✅ **Live Updates**: Supports fast development cycles
- Use for: Custom build requirements, Python, Node.js, Go applications

## Common Build Commands (Command Mode)

### Maven Spring Boot
```yaml
build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=myservice:latest"

# With registry
build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=registry.com/myservice:v1.0"

# Multi-module project
build_command: "mvn -pl submodule spring-boot:build-image -Dspring-boot.build-image.imageName=submodule:latest"
```

### Gradle
```yaml
build_command: "gradle bootBuildImage --imageName=myservice:latest"

# Multi-module
build_command: "gradle :submodule:bootBuildImage --imageName=submodule:latest"
```

### Custom Build Tools
```yaml
# Bazel
build_command: "bazel run //path/to/service:push_image"

# Custom script
build_command: "./build.sh myservice:latest"
```

## Live Updates

All build methods support live updates when appropriate:

### Command Mode Live Updates
- **Java**: Source files, Maven/Gradle configs, resources
- **Python**: Source files, requirements.txt
- **Go**: Source files, go.mod
- **Node.js**: Source files, package.json

### Dockerfile Mode Live Updates
- Uses language-specific patterns automatically
- More granular control over file sync patterns

## Service Configuration Examples

### Mixed Environment
You can use different build methods in the same project:

```yaml
services:
  # Command-based Java service
  payment-api:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=payment-api:latest"
    build_working_dir: "./services/payment-api"
    
  # Dockerfile-based Python service
  notification-api:
    type: "python" 
    build_context: "./services/notification-api"
    dockerfile: "./services/notification-api/Dockerfile"
    
  # ECR pre-built service
  stable-service:
    type: "go"
    ecr_image: "123456789.dkr.ecr.us-east-1.amazonaws.com/stable-service:v2.1.0"
    
  # External service
  database:
    type: "external"
    image: "postgres:16.4"
```

## Usage

Simply deploy services - the framework handles build method detection automatically:

```bash
# Deploy specific services (build methods detected automatically)
tilt up -- --services=payment-api,notification-api,database --developer_id=$(whoami)

# All services - framework chooses appropriate build method for each
tilt up -- --services=payment-api,notification-api,stable-service,database
```

## Migration from Manual Build Strategy

### Before (Manual Strategy Selection)
```bash
# Old approach with manual flags (no longer needed)
tilt up -- --services=app1,app2 --build_local=app1 --build_strategy=mixed
```

### After (Automatic Detection)
```bash
# New approach - no build flags needed
tilt up -- --services=app1,app2 --developer_id=$(whoami)
```

The build method is determined by service configuration, not command-line arguments.

## Troubleshooting

### Wrong Build Method Detected
**Problem**: Service uses unexpected build method
```
Solution: Check service configuration fields:
- Remove conflicting fields (e.g., both ecr_image and build_context)
- Ensure required fields are present for desired build method
```

### Build Command Not Working
**Problem**: Command build fails
```
Solution: 
- Verify build command syntax
- Check build_working_dir path
- Ensure build tools are available in working directory
```

### ECR Image Not Found
**Problem**: ECR image pull fails
```
Solution:
- Verify ECR image name and tag
- Check AWS credentials and permissions
- Ensure image exists in specified registry
```

## Best Practices

### 1. Clear Service Configuration
```yaml
# Good: Clear single build method
my-service:
  type: "python"
  build_context: "./my-service"
  dockerfile: "./my-service/Dockerfile"

# Avoid: Conflicting build configurations
# Don't specify both ecr_image and build_context
```

### 2. Appropriate Build Method Selection
- **External**: For databases, caches, third-party services
- **ECR**: For stable, production-tested services
- **Command**: For Maven/Gradle projects with built-in image generation
- **Dockerfile**: For custom builds, active development

### 3. Environment-Specific Configuration
Use environment files to override build methods when needed:
```yaml
# .tilt/environments/production-test.yaml
services:
  my-service:
    ecr_image: "registry/my-service:production-v1.2.3"  # Override for prod testing
```

## Performance Considerations

- **External Images**: Fastest startup, no build time
- **ECR Images**: Fast startup, network dependency
- **Command Builds**: Variable speed, depends on build tool and cache
- **Dockerfile Builds**: Moderate speed, Docker layer caching helps

The automatic detection system chooses the most appropriate method based on your configuration, ensuring optimal performance for each service type.

## Getting Help

- **Service Configuration**: Check `.tilt/service-config.yaml` syntax
- **Build Issues**: Review Tilt UI logs for specific build method
- **Tilt UI**: [http://localhost:10350](http://localhost:10350) - Real-time build status
- **Documentation**: See related guides for specific build methods

The automatic build method detection simplifies development by removing manual build strategy decisions while maintaining flexibility through configuration.