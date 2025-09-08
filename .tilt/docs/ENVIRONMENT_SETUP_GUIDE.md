# Environment Setup Guide

This guide covers the user-defined environment system that allows developers to create custom service combinations for different development scenarios.

## Overview

The environment system provides complete flexibility in defining which services to deploy together, without requiring any modifications to the framework code. 
This separation ensures the framework remains generic and reusable across different projects.

## Architecture: Framework vs Project Separation

### Framework Layer (Generic & Reusable)
- `scripts/setup-environment.sh` - Generic environment setup script
- `Tiltfile` - Service-agnostic orchestration
- `.tilt/lib/*.star` - Reusable deployment modules

### Project Layer (User-Configurable)  
- `.tilt/environments.yaml` - User-defined environment configurations
- `.tilt/service-config.yaml` - Available services
- `services/` - Imported service code

## Environment Configuration File

### Basic Structure

The `.tilt/environments.yaml` file defines all available environments:

```yaml
# .tilt/environments.yaml
environments:
  # Environment definitions
  environment-name:
    description: "Human-readable description"
    services: ["service1", "service2"]
  
  # More environments...
```

### Complete Example

```yaml
environments:
  # Minimal development environment
  minimal:
    description: "Essential services only for lightweight development"
    services: ["ai-agentic-test-app"]

  # Backend development with databases
  backend-only:
    description: "Backend APIs and databases without frontend components"
    services: ["ai-agentic-test-app", "database", "redis"]

  # Complete development environment
  full-stack:
    description: "Complete environment with all frontend, backend, and data services"
    services: ["ai-agentic-test-app", "database", "redis", "frontend"]

  # Production-like staging mirror
  staging-mirror:
    description: "Local replica of staging environment using production-like images"
    services: ["ai-agentic-test-app", "database", "redis"]

  # Lightweight feature development
  feature-branch:
    description: "Lightweight setup optimized for feature development"
    services: ["ai-agentic-test-app", "redis"]

  # Integration testing environment
  integration-test:
    description: "Integration testing environment with specific service versions"
    services: ["ai-agentic-test-app", "database"]

  # Custom demo environment
  my-demo-setup:
    description: "Custom environment for demonstrations"
    services: ["ai-agentic-test-app", "mock-api", "redis"]
```

## Usage

### Basic Environment Setup

```bash
# Start predefined environments
./scripts/setup-environment.sh minimal
./scripts/setup-environment.sh backend-only
./scripts/setup-environment.sh full-stack

# Start custom environments
./scripts/setup-environment.sh my-demo-setup
./scripts/setup-environment.sh integration-test
```

### Advanced Options

```bash
# Dry run to see what would be deployed
./scripts/setup-environment.sh backend-only --dry-run

# Override developer ID
./scripts/setup-environment.sh minimal --developer-id=john-doe

# Get help and see available environments
./scripts/setup-environment.sh --help
```

### Environment Discovery

```bash
# List all available environments
./scripts/setup-environment.sh --help

# The help output shows all configured environments dynamically
```

Example help output:
```
Usage: ./scripts/setup-environment.sh <environment> [options]

User-defined environments (configure in .tilt/environments.yaml):
  minimal
  backend-only
  full-stack
  staging-mirror
  feature-branch
  integration-test
  my-demo-setup

Options:
  --dry-run        Show what would be started without starting
  --developer-id   Override developer ID (default: $(whoami))
```

## Automatic Build Method Detection

The framework automatically determines the appropriate build method for each service based on its configuration:

- **External Services** (type: "external" + image field) → Use external image directly  
- **ECR Services** (ecr_image field) → Pull from ECR registry
- **Command Services** (build_command field) → Use custom build command
- **Dockerfile Services** (build_context field) → Use Docker build

```yaml
my-environment:
  services: ["api", "database", "redis"]
  # Build methods determined automatically from service configuration
```

## Service Types and Build Behavior

### Application Services
- Services with `type: "python|java|go|nodejs|crewai"`
- Build method determined by configuration fields (build_context, ecr_image, build_command)

### External Services  
- Services with `type: "external"`
- Always use images (PostgreSQL, Redis, etc.)
- Build method automatically detected from image field

## Common Environment Patterns

### Development Patterns

#### Minimal Development
```yaml
minimal:
  description: "Lightweight setup for core development"
  services: ["main-app"]
```

#### Full-Stack Development
```yaml
full-stack:
  description: "Complete local development environment"
  services: ["frontend", "api", "worker", "database", "redis"]
```

#### Backend-Only Development
```yaml
backend-only:
  description: "API development without frontend"
  services: ["api", "worker", "database", "redis"]
```

### Testing Patterns

#### Integration Testing
```yaml
integration-test:
  description: "Stable versions for integration testing"
  services: ["api", "database", "external-service"]
```

#### Performance Testing
```yaml
perf-test:
  description: "Production-like performance testing"
  services: ["api", "database", "cache", "load-balancer"]
```

### Specialized Patterns

#### Demo Environment
```yaml
demo:
  description: "Clean demo setup with mock data"
  services: ["frontend", "api", "mock-data-service"]
```

#### Debugging Environment
```yaml
debug:
  description: "Debugging with minimal external dependencies"
  services: ["api", "database"]
```

## Environment Validation

The system validates environments automatically:

### Service Validation
- Ensures all specified services exist in `.tilt/service-config.yaml`
- Shows available services if validation fails
- Provides guidance for adding missing services

### Configuration Validation
- Validates service configuration syntax
- Shows configuration errors with helpful messages
- Ensures services have required fields for their build method

### Dependency Resolution
- Automatically includes required dependencies
- Shows dependency conflicts if they exist
- Ensures services start in correct order

## Advanced Features

### Dynamic Environment Creation

You can create environments on-demand by modifying `.tilt/environments.yaml`:

```yaml
# Add new environment
experimental:
  description: "Testing new service combination"
  services: ["new-service", "database"]
```

The new environment becomes immediately available:
```bash
./scripts/setup-environment.sh experimental
```

### Environment Templating

Use similar environments as templates:

```yaml
# Base environment
base-dev:
  description: "Base development setup"
  services: ["api", "database"]

# Extended environment
extended-dev:
  description: "Extended development with additional services"
  services: ["api", "database", "redis", "worker"]  
```

### Environment-Specific Overrides

While environments define service combinations, build methods are always determined by service configuration:

```bash
# Use environment - build methods determined automatically
./scripts/setup-environment.sh backend-only
```

## Troubleshooting

### Environment Not Found
```bash
Error: Environment 'my-env' not found or has no services defined

Available environments:
  minimal
  backend-only
  full-stack
```

**Solution**: Add the environment to `.tilt/environments.yaml` or check for typos.

### Service Not Found
```bash
Error: Required service not found in configuration: missing-service

Available services:
  - ai-agentic-test-app
  - database  
  - redis
```

**Solution**: Add the service to `.tilt/service-config.yaml` or remove from environment.

### Configuration Error
```bash
Error: Service 'my-service' has conflicting build configuration
- Both 'ecr_image' and 'build_context' are specified
- Please use only one build method per service
```

**Solution**: Remove conflicting configuration fields from service definition.

## Best Practices

### 1. Descriptive Environment Names
```yaml
# Good
backend-api-dev:
  description: "Backend API development with databases"
  
# Avoid  
env1:
  description: "Some environment"
```

### 2. Meaningful Descriptions
```yaml
integration-test:
  description: "Stable service versions for automated integration testing"
  # Not just: "Integration environment"
```

### 3. Logical Service Groupings
```yaml
# Group related services together
data-pipeline:
  services: ["ingestion", "processing", "storage", "database"]
  
# Don't mix unrelated services
# avoid: ["frontend", "database", "random-utility"]
```

### 4. Appropriate Service Configuration
Ensure each service has appropriate configuration in `.tilt/service-config.yaml`:

```yaml
# Service with local Dockerfile build
services:
  my-service:
    type: "python"
    build_context: "./my-service"
    dockerfile: "./my-service/Dockerfile"

# Service with ECR image
  stable-service:
    type: "go"
    ecr_image: "123456789.dkr.ecr.us-east-1.amazonaws.com/stable:v1.0"

# External service
  database:
    type: "external"
    image: "postgres:16.4"
```

### 5. Environment Documentation
Keep environment descriptions up-to-date and descriptive. Other team members should understand the purpose from the description.

## Migration from Hardcoded Environments

If you previously had hardcoded environment logic, migration is straightforward:

### Before (Hardcoded)
```bash
# Old hardcoded approach
if [ "$ENV" = "backend-only" ]; then
  SERVICES="api database redis"
fi
```

### After (User-Defined)
```yaml
# .tilt/environments.yaml
environments:
  backend-only:
    description: "Backend development environment"
    services: ["api", "database", "redis"]
```

### Benefits of Migration
- **No Code Changes**: Adding environments requires no script modifications
- **Self-Documenting**: Environments include descriptions
- **Validation**: Automatic service and dependency validation
- **Flexibility**: Any service combination possible
- **Automatic Build Detection**: Build methods determined from service configuration
- **Team Collaboration**: Team members can add environments without touching framework code

This environment system provides complete flexibility while maintaining the clear separation between framework code and project-specific configuration. Build methods are automatically detected from service configuration, eliminating the need for manual build strategy management.