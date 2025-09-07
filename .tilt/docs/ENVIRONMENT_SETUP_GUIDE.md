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
    build_strategy: "local|ecr|mixed"
  
  # More environments...

# Global settings
global:
  default_build_strategy: "mixed"
  allowed_build_strategies: ["local", "ecr", "mixed"]
```

### Complete Example

```yaml
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

  # Production-like staging mirror
  staging-mirror:
    description: "Local replica of staging environment using production-like images"
    services: ["ai-agentic-test-app", "database", "redis"]
    build_strategy: "ecr"

  # Lightweight feature development
  feature-branch:
    description: "Lightweight setup optimized for feature development"
    services: ["ai-agentic-test-app", "redis"]
    build_strategy: "local"

  # Integration testing environment
  integration-test:
    description: "Integration testing environment with specific service versions"
    services: ["ai-agentic-test-app", "database"]
    build_strategy: "ecr"

  # Custom demo environment
  my-demo-setup:
    description: "Custom environment for demonstrations"
    services: ["ai-agentic-test-app", "mock-api", "redis"]
    build_strategy: "local"

global:
  default_build_strategy: "mixed"
  allowed_build_strategies: ["local", "ecr", "mixed"]
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

## Build Strategies

### Local Strategy
- All services are built locally with live updates
- Best for active development
- Slower initial startup, fastest iteration

```yaml
my-dev-env:
  services: ["api", "frontend"]
  build_strategy: "local"
```

### ECR Strategy  
- All services use pre-built images from ECR
- Best for integration testing
- Fastest startup, no local builds

```yaml
staging-test:
  services: ["api", "database"]
  build_strategy: "ecr"
```

### Mixed Strategy
- Combines local builds and ECR images
- Build main services locally, use ECR for dependencies
- Balanced approach for most development scenarios

```yaml
balanced-dev:
  services: ["api", "database", "redis"]
  build_strategy: "mixed"  # API built locally, database/redis from ECR
```

## Service Types and Build Behavior

### Application Services (Built Locally in Mixed Strategy)
- Services with `type: "python|java|go|nodejs|crewai"`
- Built locally when `build_strategy: "mixed"`

### External Services (Always from Images)
- Services with `type: "external"`
- Always use images (PostgreSQL, Redis, etc.)
- Never built locally regardless of strategy

## Common Environment Patterns

### Development Patterns

#### Minimal Development
```yaml
minimal:
  description: "Lightweight setup for core development"
  services: ["main-app"]
  build_strategy: "local"
```

#### Full-Stack Development
```yaml
full-stack:
  description: "Complete local development environment"
  services: ["frontend", "api", "worker", "database", "redis"]
  build_strategy: "mixed"
```

#### Backend-Only Development
```yaml
backend-only:
  description: "API development without frontend"
  services: ["api", "worker", "database", "redis"]
  build_strategy: "mixed"
```

### Testing Patterns

#### Integration Testing
```yaml
integration-test:
  description: "Stable versions for integration testing"
  services: ["api", "database", "external-service"]
  build_strategy: "ecr"
```

#### Performance Testing
```yaml
perf-test:
  description: "Production-like performance testing"
  services: ["api", "database", "cache", "load-balancer"]
  build_strategy: "ecr"
```

### Specialized Patterns

#### Demo Environment
```yaml
demo:
  description: "Clean demo setup with mock data"
  services: ["frontend", "api", "mock-data-service"]
  build_strategy: "local"
```

#### Debugging Environment
```yaml
debug:
  description: "Debugging with minimal external dependencies"
  services: ["api", "database"]
  build_strategy: "local"
```

## Environment Validation

The system validates environments automatically:

### Service Validation
- Ensures all specified services exist in `.tilt/service-config.yaml`
- Shows available services if validation fails
- Provides guidance for adding missing services

### Build Strategy Validation
- Validates build strategy values
- Falls back to global defaults if not specified
- Shows allowed strategies in error messages

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
  build_strategy: "local"
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
  build_strategy: "mixed"

# Extended environment
extended-dev:
  description: "Extended development with additional services"
  services: ["api", "database", "redis", "worker"]  
  build_strategy: "mixed"
```

### Environment-Specific Overrides

While environments define service combinations, you can still use runtime overrides:

```bash
# Use environment but override build strategy
./scripts/setup-environment.sh backend-only
# Then in another terminal:
tilt up -- --services=api --build_local=api
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

### Invalid Build Strategy
```bash
Error: Invalid build strategy 'invalid'

Allowed strategies: local, ecr, mixed
```

**Solution**: Use one of the allowed build strategies.

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

### 4. Appropriate Build Strategies
```yaml
# Local for active development
active-dev:
  services: ["my-service"]
  build_strategy: "local"

# Mixed for balanced development  
balanced-dev:
  services: ["my-service", "database", "redis"]
  build_strategy: "mixed"

# ECR for testing stable versions
integration-test:
  services: ["service1", "service2"] 
  build_strategy: "ecr"
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
    build_strategy: "mixed"
```

### Benefits of Migration
- **No Code Changes**: Adding environments requires no script modifications
- **Self-Documenting**: Environments include descriptions
- **Validation**: Automatic service and dependency validation
- **Flexibility**: Any service combination possible
- **Team Collaboration**: Team members can add environments without touching framework code

This environment system provides complete flexibility while maintaining the clear separation between framework code and project-specific configuration.