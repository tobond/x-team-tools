# Dual-Mode Build System Guide

## Overview

The x-team-tools Tilt environment now supports **two modes** for building Docker images:

1. **Dockerfile Mode** (Traditional): Uses `docker_build()` with a Dockerfile
2. **Command Mode** (New): Uses `custom_build()` with any build command (Maven, Gradle, etc.)

## When to Use Each Mode

### Dockerfile Mode
- **Best for**: Python, Node.js, Go applications with custom build requirements
- **Advantages**: Full Docker control, custom base images, complex multi-stage builds
- **Use when**: You need custom Docker layers, specific Linux packages, or complex build processes

### Command Mode  
- **Best for**: Maven, Gradle, Bazel projects with built-in image generation
- **Advantages**: Leverages existing build toolchain, consistent with CI/CD pipeline
- **Use when**: Your build tool already generates Docker images (Spring Boot, etc.)

## Configuration Examples

### Maven Spring Boot (Command Mode)

```yaml
services:
  payment-service:
    type: "java"
    build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=payment-service:latest"
    build_working_dir: "./services/payment-service"
    ports: [8080]
    env_vars:
      - name: "SPRING_PROFILES_ACTIVE"
        value: "local"
```

**Usage:**
```bash
tilt up payment-service -- --developer_id=$(whoami) --build_local=payment-service
```

### Gradle (Command Mode)

```yaml
services:
  order-service:
    type: "java" 
    build_command: "gradle bootBuildImage --imageName=order-service:latest"
    build_working_dir: "./services/order-service"
    ports: [9090]
```

### Python API (Dockerfile Mode)

```yaml
services:
  notification-service:
    type: "python"
    build_context: "./services/notification-service"
    dockerfile: "./services/notification-service/Dockerfile"
    ports: [8001]
```

## Build Mode Selection Logic

The system automatically selects the build mode based on your configuration:

1. **Command Mode**: If `build_command` is specified
2. **Dockerfile Mode**: If `dockerfile` + `build_context` are specified  
3. **ECR Mode**: If `ecr_image` is specified
4. **External Mode**: If `image` is specified (external services)

## Common Build Commands

### Maven Commands

```bash
# Basic build
mvn spring-boot:build-image

# With custom image name
mvn spring-boot:build-image -Dspring-boot.build-image.imageName=myservice:latest

# With registry
mvn spring-boot:build-image -Dspring-boot.build-image.imageName=registry.com/myservice:v1.0

# Multi-module project
mvn -pl submodule spring-boot:build-image -Dspring-boot.build-image.imageName=submodule:latest
```

### Gradle Commands

```bash
# Basic build
gradle bootBuildImage

# With custom image name  
gradle bootBuildImage --imageName=myservice:latest

# Multi-module
gradle :submodule:bootBuildImage --imageName=submodule:latest
```

### Other Build Tools

```bash
# Bazel
bazel run //path/to/service:push_image

# Custom script
./build.sh myservice:latest

# Docker Compose
docker-compose build myservice && docker tag myproject_myservice myservice:latest
```

## Live Updates

Both modes support live updates with language-specific optimizations:

### Command Mode Live Updates
- **Java**: Source files, Maven/Gradle configs, resources
- **Python**: Source files, requirements.txt
- **Go**: Source files, go.mod
- **Node.js**: Source files, package.json

### Dockerfile Mode Live Updates
- Uses the same language-specific patterns
- More granular control over file sync patterns

## Monitoring & Debugging

### Build Strategy Dashboard
```bash
tilt trigger build-strategy-dashboard
```

Shows:
- Total services by build mode
- Dockerfile builds vs Command builds
- Build command details for each service

### Build Monitoring
```bash
tilt trigger tilt-build-monitor
```

Shows:
- Build status for each service
- Live update status
- Build logs and failures

## Migration Guide

### From Dockerfile to Command Mode

**Before (Dockerfile):**
```yaml
payment-service:
  type: "java"
  build_context: "./services/payment-service" 
  dockerfile: "./services/payment-service/Dockerfile"
```

**After (Command):**
```yaml
payment-service:
  type: "java"
  build_command: "mvn spring-boot:build-image -Dspring-boot.build-image.imageName=payment-service:latest"
  build_working_dir: "./services/payment-service"
```

### From Command to Dockerfile Mode

**Before (Command):**
```yaml
python-api:
  type: "python"
  build_command: "./build.sh python-api:latest"
  build_working_dir: "./services/python-api"
```

**After (Dockerfile):**
```yaml
python-api:
  type: "python"
  build_context: "./services/python-api"
  dockerfile: "./services/python-api/Dockerfile"
```

## Best Practices

### Command Mode Best Practices
1. **Image Naming**: Always specify explicit image names in build commands
2. **Working Directory**: Set `build_working_dir` to the correct project root
3. **Build Tool Versions**: Pin build tool versions in your project files
4. **Registry Support**: Use full registry URLs for team deployments

### Dockerfile Mode Best Practices  
1. **Multi-stage Builds**: Use multi-stage builds for smaller images
2. **Layer Caching**: Structure Dockerfiles for optimal layer caching
3. **Security**: Use non-root users and minimal base images
4. **Build Context**: Keep build contexts minimal with `.dockerignore`

## Troubleshooting

### Command Build Issues

**Problem**: Build command not found
```
Solution: Ensure build tool is installed in working directory
Check: ls -la ./services/your-service/pom.xml (for Maven)
```

**Problem**: Image name not recognized
```
Solution: Verify image name matches exactly in build_command
Check: docker images | grep your-service-name
```

### Dockerfile Build Issues

**Problem**: Dockerfile not found
```
Solution: Check dockerfile path is correct
Verify: ls -la ./services/your-service/Dockerfile
```

**Problem**: Build context issues
```
Solution: Verify build_context directory exists
Check: ls -la ./services/your-service/
```

## Performance Considerations

### Command Mode Performance
- ✅ **Faster**: Leverages existing build caches (Maven ~/.m2, Gradle ~/.gradle)
- ✅ **Consistent**: Same build process as CI/CD
- ⚠️ **Dependencies**: Requires build tools installed locally

### Dockerfile Mode Performance  
- ✅ **Flexible**: Complete control over build environment
- ✅ **Isolated**: No local tool dependencies
- ⚠️ **Cache Management**: Docker layer caching needs optimization

## Advanced Configuration

### Mixed Build Environments

You can use both modes in the same project:

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
    
  # External service
  database:
    type: "external"
    image: "postgres:16.4"
```

### Custom Build Commands

```yaml
services:
  custom-service:
    type: "generic"
    build_command: |
      ./scripts/custom-build.sh --service=custom-service --tag=latest --registry=local
    build_working_dir: "./"
    ports: [8080]
```

## Getting Help

- **Tilt UI**: http://localhost:10350 - View build logs and status
- **Build Strategy Dashboard**: `tilt trigger build-strategy-dashboard`
- **Build Monitor**: `tilt trigger tilt-build-monitor`
- **Documentation**: `.tilt/docs/K8S_MANIFEST_GENERATION_GUIDE.md`

The dual-mode build system provides the flexibility to use the best build approach for each service while maintaining consistent deployment and monitoring capabilities.