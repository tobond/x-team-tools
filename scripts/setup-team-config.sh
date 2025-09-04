#!/bin/bash

# Team Configuration Setup Script
# Sets up shared team configuration and version control integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

echo "🔧 Setting up team configuration and version control integration..."

# Create team configuration directory structure
print_header "Creating Team Configuration Structure"

mkdir -p .tilt/team
mkdir -p .tilt/environments
mkdir -p .tilt/templates
mkdir -p scripts/team

print_status "Created team configuration directories"

# Create team standards configuration
print_header "Creating Team Standards"

cat > .tilt/team/standards.yaml << 'EOF'
# Team Standards Configuration
# This file defines team-wide standards and requirements

standards:
  # Required tool versions
  tools:
    docker:
      min_version: "20.10.0"
      recommended_version: "24.0.0"
    kubectl:
      min_version: "1.21.0"
      recommended_version: "1.28.0"
    tilt:
      min_version: "0.30.0"
      recommended_version: "0.33.0"
    
  # Cluster requirements
  cluster:
    min_nodes: 1
    min_cpu: "2"
    min_memory: "4Gi"
    required_storage_classes: ["standard"]
    
  # Resource standards
  resources:
    default_requests:
      cpu: "100m"
      memory: "128Mi"
    default_limits:
      cpu: "500m"
      memory: "512Mi"
    max_per_service:
      cpu: "2000m"
      memory: "4Gi"
      
  # Security standards
  security:
    run_as_non_root: true
    read_only_root_filesystem: false  # Many apps need writable filesystem
    allow_privilege_escalation: false
    required_security_context: true
    
  # Development practices
  practices:
    max_services_per_developer: 10
    required_health_checks: true
    required_resource_limits: true
    live_updates_enabled: true
    
validation:
  # Pre-start validation checks
  pre_start_checks:
    - tool_versions
    - cluster_connectivity
    - resource_availability
    - configuration_syntax
    
  # Runtime monitoring
  runtime_checks:
    - resource_usage
    - service_health
    - dependency_status
EOF

print_status "Created team standards configuration"

# Create environment-specific configurations
print_header "Creating Environment Configurations"

# Development environment
cat > .tilt/environments/development.yaml << 'EOF'
# Development Environment Configuration
environment: development

# Override settings for development
settings:
  debug_mode: true
  live_updates: true
  auto_open_ui: true
  
# Resource settings for development
resources:
  default_requests:
    cpu: "50m"      # Lower for development
    memory: "64Mi"
  default_limits:
    cpu: "500m"
    memory: "512Mi"
    
# Service overrides for development
services:
  # Enable debug logging for all services
  global_env_vars:
    - name: "LOG_LEVEL"
      value: "DEBUG"
    - name: "ENVIRONMENT"
      value: "development"
      
# External services for development
external_services:
  database:
    enabled: true
    type: "postgresql"
    version: "13"
  redis:
    enabled: true
    version: "6"
  mock_apis:
    enabled: true
EOF

# Testing environment
cat > .tilt/environments/testing.yaml << 'EOF'
# Testing Environment Configuration
environment: testing

# Override settings for testing
settings:
  debug_mode: false
  live_updates: false  # Use stable builds for testing
  auto_open_ui: false
  
# Resource settings for testing
resources:
  default_requests:
    cpu: "100m"
    memory: "128Mi"
  default_limits:
    cpu: "1000m"
    memory: "1Gi"
    
# Service overrides for testing
services:
  # Use INFO level logging for testing
  global_env_vars:
    - name: "LOG_LEVEL"
      value: "INFO"
    - name: "ENVIRONMENT"
      value: "testing"
      
  # Multiple replicas for testing
  default_replicas: 2
  
# External services for testing
external_services:
  database:
    enabled: true
    type: "postgresql"
    version: "13"
    replicas: 1
  redis:
    enabled: true
    version: "6"
  mock_apis:
    enabled: false  # Use real services in testing
EOF

print_status "Created environment configurations"

# Create service templates
print_header "Creating Service Templates"

# Python service template
cat > .tilt/templates/python-service.yaml << 'EOF'
# Python Service Template
# Use this template for new Python services

type: "python"
build_context: "./{{SERVICE_NAME}}"
dockerfile: "./{{SERVICE_NAME}}/Dockerfile"
ecr_image: "{{ECR_REGISTRY}}/{{SERVICE_NAME}}"

# Default ports for Python services
ports: [8080]

# Default environment variables
env_vars:
  - name: "LOG_LEVEL"
    value: "INFO"
  - name: "PYTHONPATH"
    value: "/app/src"
  - name: "PYTHONUNBUFFERED"
    value: "1"

# Resource defaults for Python services
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

# Live update configuration for Python
live_update:
  sync_rules:
    - local_path: "./{{SERVICE_NAME}}/src"
      remote_path: "/app/src"
    - local_path: "./{{SERVICE_NAME}}/requirements.txt"
      remote_path: "/app/requirements.txt"
  run_commands:
    - "pip install -r requirements.txt"
  restart_on:
    - "requirements.txt"
  ignore_patterns:
    - "**/*.pyc"
    - "**/__pycache__"
    - "**/*.log"

# Health check configuration
health_check:
  path: "/health"
  port: 8080
  initial_delay_seconds: 30
  period_seconds: 10
EOF

# Java service template
cat > .tilt/templates/java-service.yaml << 'EOF'
# Java Service Template
# Use this template for new Java services

type: "java"
build_context: "./{{SERVICE_NAME}}"
dockerfile: "./{{SERVICE_NAME}}/Dockerfile"
ecr_image: "{{ECR_REGISTRY}}/{{SERVICE_NAME}}"

# Default ports for Java services
ports: [8080, 8081]

# Default environment variables
env_vars:
  - name: "JAVA_OPTS"
    value: "-Xmx512m -Xms256m"
  - name: "SPRING_PROFILES_ACTIVE"
    value: "local"

# Resource defaults for Java services
resources:
  requests:
    cpu: "250m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "1Gi"

# Live update configuration for Java
live_update:
  sync_rules:
    - local_path: "./{{SERVICE_NAME}}/target/classes"
      remote_path: "/app/classes"
  restart_container: true
  fall_back_on:
    - "pom.xml"
    - "src/main/resources"

# Health check configuration
health_check:
  path: "/actuator/health"
  port: 8081
  initial_delay_seconds: 60
  period_seconds: 15
EOF

print_status "Created service templates"

# Create team validation script
print_header "Creating Team Validation Script"

cat > scripts/team/validate-team-standards.sh << 'EOF'
#!/bin/bash

# Team Standards Validation Script
# Validates that the development environment meets team standards

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_failure() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🔍 Validating team standards compliance..."

# Load team standards
if [ ! -f ".tilt/team/standards.yaml" ]; then
    print_failure "Team standards file not found"
    exit 1
fi

# Check tool versions (requires yq)
if command -v yq &> /dev/null; then
    # Check Docker version
    if command -v docker &> /dev/null; then
        docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        min_docker=$(yq eval '.standards.tools.docker.min_version' .tilt/team/standards.yaml)
        if [ "$(printf '%s\n' "$min_docker" "$docker_version" | sort -V | head -n1)" = "$min_docker" ]; then
            print_success "Docker version meets requirements ($docker_version >= $min_docker)"
        else
            print_failure "Docker version too old ($docker_version < $min_docker)"
        fi
    fi
    
    # Check kubectl version
    if command -v kubectl &> /dev/null; then
        kubectl_version=$(kubectl version --client --short 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        min_kubectl=$(yq eval '.standards.tools.kubectl.min_version' .tilt/team/standards.yaml)
        if [ "$(printf '%s\n' "$min_kubectl" "$kubectl_version" | sort -V | head -n1)" = "$min_kubectl" ]; then
            print_success "kubectl version meets requirements ($kubectl_version >= $min_kubectl)"
        else
            print_failure "kubectl version too old ($kubectl_version < $min_kubectl)"
        fi
    fi
    
    # Check Tilt version
    if command -v tilt &> /dev/null; then
        tilt_version=$(tilt version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        min_tilt=$(yq eval '.standards.tools.tilt.min_version' .tilt/team/standards.yaml)
        if [ "$(printf '%s\n' "$min_tilt" "$tilt_version" | sort -V | head -n1)" = "$min_tilt" ]; then
            print_success "Tilt version meets requirements ($tilt_version >= $min_tilt)"
        else
            print_failure "Tilt version too old ($tilt_version < $min_tilt)"
        fi
    fi
else
    print_warning "yq not installed - cannot validate tool versions"
fi

# Check cluster resources
if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    # Check node count
    node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$node_count" -ge 1 ]; then
        print_success "Cluster has sufficient nodes ($node_count)"
    else
        print_failure "Cluster has insufficient nodes ($node_count < 1)"
    fi
    
    # Check storage classes
    storage_classes=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
    if [ "$storage_classes" -gt 0 ]; then
        print_success "Storage classes available ($storage_classes)"
    else
        print_warning "No storage classes found"
    fi
fi

# Validate service configurations
if [ -f ".tilt/service-config.yaml" ]; then
    if command -v yq &> /dev/null; then
        # Check that all services have resource limits
        services=$(yq eval '.services | keys | .[]' .tilt/service-config.yaml 2>/dev/null)
        for service in $services; do
            if yq eval ".services.$service.resources" .tilt/service-config.yaml | grep -q "null"; then
                print_warning "Service $service missing resource limits"
            else
                print_success "Service $service has resource limits"
            fi
        done
    fi
fi

echo "Team standards validation complete"
EOF

chmod +x scripts/team/validate-team-standards.sh

print_status "Created team validation script"

# Create service creation script
print_header "Creating Service Creation Script"

cat > scripts/team/create-service.sh << 'EOF'
#!/bin/bash

# Service Creation Script
# Creates a new service from team templates

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <service-name> <service-type> [ecr-registry]"
    echo "Available types: python, java, go, nodejs"
    exit 1
fi

SERVICE_NAME=$1
SERVICE_TYPE=$2
ECR_REGISTRY=${3:-"123456789.dkr.ecr.us-east-1.amazonaws.com"}

# Validate service type
if [ ! -f ".tilt/templates/${SERVICE_TYPE}-service.yaml" ]; then
    print_error "Service type '$SERVICE_TYPE' not supported"
    echo "Available types:"
    ls .tilt/templates/ | grep -E '.*-service\.yaml$' | sed 's/-service\.yaml$//' | sed 's/^/  - /'
    exit 1
fi

print_status "Creating new $SERVICE_TYPE service: $SERVICE_NAME"

# Check if service already exists
if grep -q "^  $SERVICE_NAME:" .tilt/service-config.yaml 2>/dev/null; then
    print_error "Service '$SERVICE_NAME' already exists in service-config.yaml"
    exit 1
fi

# Create service configuration from template
print_status "Adding service configuration..."

# Read template and substitute variables
template_content=$(cat ".tilt/templates/${SERVICE_TYPE}-service.yaml")
service_config=$(echo "$template_content" | sed "s/{{SERVICE_NAME}}/$SERVICE_NAME/g" | sed "s|{{ECR_REGISTRY}}|$ECR_REGISTRY|g")

# Add to service-config.yaml
echo "" >> .tilt/service-config.yaml
echo "  $SERVICE_NAME:" >> .tilt/service-config.yaml
echo "$service_config" | sed 's/^/    /' >> .tilt/service-config.yaml

print_status "Service configuration added to .tilt/service-config.yaml"

# Create basic directory structure
if [ ! -d "$SERVICE_NAME" ]; then
    print_status "Creating service directory structure..."
    mkdir -p "$SERVICE_NAME"
    
    case $SERVICE_TYPE in
        python)
            mkdir -p "$SERVICE_NAME/src"
            mkdir -p "$SERVICE_NAME/tests"
            echo "# $SERVICE_NAME" > "$SERVICE_NAME/README.md"
            echo "flask==2.3.0" > "$SERVICE_NAME/requirements.txt"
            cat > "$SERVICE_NAME/Dockerfile" << EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/ ./src/

EXPOSE 8080

CMD ["python", "-m", "src.main"]
EOF
            ;;
        java)
            mkdir -p "$SERVICE_NAME/src/main/java"
            mkdir -p "$SERVICE_NAME/src/main/resources"
            mkdir -p "$SERVICE_NAME/src/test/java"
            echo "# $SERVICE_NAME" > "$SERVICE_NAME/README.md"
            cat > "$SERVICE_NAME/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>$SERVICE_NAME</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <spring.boot.version>2.7.0</spring.boot.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>\${spring.boot.version}</version>
        </dependency>
    </dependencies>
</project>
EOF
            ;;
    esac
    
    print_status "Created basic service structure in $SERVICE_NAME/"
else
    print_warning "Service directory $SERVICE_NAME/ already exists"
fi

print_status "Service '$SERVICE_NAME' created successfully!"
echo ""
echo "Next steps:"
echo "1. Implement your service in the $SERVICE_NAME/ directory"
echo "2. Test locally: tilt up -- --services=$SERVICE_NAME --build_local=$SERVICE_NAME"
echo "3. Commit changes: git add . && git commit -m 'Add $SERVICE_NAME service'"
echo "4. Share with team: git push"
EOF

chmod +x scripts/team/create-service.sh

print_status "Created service creation script"

# Create Git hooks for team integration
print_header "Setting up Git Hooks"

mkdir -p .git/hooks

# Pre-commit hook for configuration validation
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Pre-commit hook for Tilt configuration validation

echo "🔍 Validating Tilt configuration before commit..."

# Validate Tiltfile syntax
if [ -f "Tiltfile" ]; then
    if ! tilt validate --file=Tiltfile &> /dev/null; then
        echo "❌ Tiltfile validation failed"
        echo "Run 'tilt validate' to see errors"
        exit 1
    fi
    echo "✅ Tiltfile syntax is valid"
fi

# Validate service configuration YAML
if [ -f ".tilt/service-config.yaml" ]; then
    if command -v yq &> /dev/null; then
        if ! yq eval '.services' .tilt/service-config.yaml &> /dev/null; then
            echo "❌ Service configuration YAML is invalid"
            exit 1
        fi
        echo "✅ Service configuration YAML is valid"
    else
        echo "⚠️  yq not installed - cannot validate YAML syntax"
    fi
fi

# Check for secrets in configuration files
if grep -r "password\|secret\|key" .tilt/ --include="*.yaml" --include="*.yml" | grep -v "# Example" | grep -v "{{"; then
    echo "❌ Potential secrets found in configuration files"
    echo "Please remove secrets and use environment variables or Kubernetes secrets"
    exit 1
fi

echo "✅ Pre-commit validation passed"
EOF

chmod +x .git/hooks/pre-commit

# Post-merge hook for team updates
cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash

# Post-merge hook for team configuration updates

echo "🔄 Checking for team configuration updates..."

# Check if team configuration files were updated
if git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD | grep -E "^\.tilt/|^Tiltfile|^scripts/"; then
    echo "📋 Team configuration files were updated"
    echo ""
    echo "Consider running:"
    echo "  ./scripts/validate-environment.sh"
    echo "  ./scripts/team/validate-team-standards.sh"
    echo ""
    echo "If you have Tilt running, restart it to pick up changes:"
    echo "  tilt down && tilt up"
fi
EOF

chmod +x .git/hooks/post-merge

print_status "Created Git hooks for team integration"

# Create team documentation
print_header "Creating Team Documentation"

cat > TEAM_CONFIGURATION.md << 'EOF'
# Team Configuration Guide

This guide explains how to use and maintain team-wide configuration for the development environment.

## Overview

The team configuration system provides:
- Standardized service templates
- Environment-specific configurations
- Team standards validation
- Automated service creation
- Version control integration

## Directory Structure

```
.tilt/
├── team/
│   └── standards.yaml          # Team standards and requirements
├── environments/
│   ├── development.yaml        # Development environment config
│   ├── testing.yaml           # Testing environment config
│   └── staging.yaml           # Staging environment config
├── templates/
│   ├── python-service.yaml    # Python service template
│   ├── java-service.yaml      # Java service template
│   └── ...                    # Other service templates
└── service-config.yaml        # Main service configuration

scripts/team/
├── validate-team-standards.sh # Validate team standards compliance
└── create-service.sh          # Create new service from template
```

## Using Team Standards

### Validate Your Environment

```bash
# Check if your environment meets team standards
./scripts/team/validate-team-standards.sh
```

### Create New Services

```bash
# Create a new Python service
./scripts/team/create-service.sh my-new-service python

# Create a new Java service with custom ECR registry
./scripts/team/create-service.sh my-java-service java my-registry.com
```

## Environment-Specific Configuration

### Development Environment

```bash
# Use development settings
tilt up -- --environment=development
```

### Testing Environment

```bash
# Use testing settings (stable builds, multiple replicas)
tilt up -- --environment=testing
```

## Team Standards

The team standards are defined in `.tilt/team/standards.yaml` and include:

- **Tool Versions**: Minimum required versions for Docker, kubectl, Tilt
- **Resource Standards**: Default and maximum resource limits
- **Security Standards**: Required security contexts and practices
- **Development Practices**: Guidelines for service development

## Version Control Integration

### Automatic Validation

Git hooks automatically validate configuration changes:
- **Pre-commit**: Validates Tiltfile and YAML syntax
- **Post-merge**: Notifies about configuration updates

### Configuration Changes

When making team configuration changes:

1. **Test locally** with your changes
2. **Validate** using team standards script
3. **Document** the changes in commit messages
4. **Communicate** significant changes to the team

### Example Workflow

```bash
# Make configuration changes
vim .tilt/service-config.yaml

# Validate changes
./scripts/team/validate-team-standards.sh
tilt validate

# Test changes
tilt up -- --services=my-service

# Commit and share
git add .tilt/
git commit -m "Add new service configuration for my-service"
git push
```

## Service Templates

### Available Templates

- **Python**: Flask/FastAPI services with live updates
- **Java**: Spring Boot services with Maven
- **Go**: Microservices with Go modules
- **Node.js**: Express services with npm

### Customizing Templates

Templates use variable substitution:
- `{{SERVICE_NAME}}`: Replaced with actual service name
- `{{ECR_REGISTRY}}`: Replaced with ECR registry URL

### Adding New Templates

1. Create template file in `.tilt/templates/`
2. Use variable substitution for dynamic values
3. Test with `create-service.sh` script
4. Document in team standards

## Best Practices

### Configuration Management

1. **Keep shared config in version control**
2. **Use environment-specific overrides**
3. **Validate before committing**
4. **Document significant changes**

### Service Development

1. **Use team templates for new services**
2. **Follow resource limit guidelines**
3. **Include health checks**
4. **Test with team standards validation**

### Team Collaboration

1. **Communicate configuration changes**
2. **Review configuration in pull requests**
3. **Keep documentation updated**
4. **Share knowledge about customizations**

## Troubleshooting

### Configuration Issues

```bash
# Validate team standards
./scripts/team/validate-team-standards.sh

# Check YAML syntax
yq eval '.services' .tilt/service-config.yaml

# Validate Tiltfile
tilt validate
```

### Service Creation Issues

```bash
# Check available templates
ls .tilt/templates/

# Verify service doesn't already exist
grep "my-service:" .tilt/service-config.yaml
```

### Git Hook Issues

```bash
# Re-install hooks if needed
cp scripts/team/git-hooks/* .git/hooks/
chmod +x .git/hooks/*
```

For more help, see [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md).
EOF

print_status "Created team configuration documentation"

# Update .gitignore for team configuration
print_header "Updating .gitignore"

if [ -f ".gitignore" ]; then
    # Add team-specific ignores if not already present
    if ! grep -q "# Tilt team configuration" .gitignore; then
        cat >> .gitignore << 'EOF'

# Tilt team configuration
.tilt/developer-config.yaml
.tilt/local-overrides.yaml
.tilt/.env
EOF
        print_status "Updated .gitignore with team configuration rules"
    else
        print_status ".gitignore already contains team configuration rules"
    fi
else
    print_warning ".gitignore not found - consider creating one"
fi

# Create README update
print_header "Creating Team Setup Instructions"

cat > TEAM_SETUP.md << 'EOF'
# Team Setup Instructions

## For New Team Members

### 1. Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd x-team-tools

# Run the appropriate setup script
./scripts/setup-macos.sh        # macOS
./scripts/setup-linux.sh        # Linux
./scripts/setup-windows.ps1     # Windows
```

### 2. Team Configuration

```bash
# Validate your environment meets team standards
./scripts/team/validate-team-standards.sh

# Create your developer configuration
cp .tilt/developer-config.yaml.template .tilt/developer-config.yaml
# Edit the file with your preferences
```

### 3. First Run

```bash
# Start with a simple service to test
tilt up -- --services=database --developer_id=$(whoami)

# Open Tilt UI
open http://localhost:10350
```

## For Team Leads

### Adding New Services

```bash
# Use the team service creation script
./scripts/team/create-service.sh new-service python

# This creates:
# - Service configuration in .tilt/service-config.yaml
# - Basic directory structure
# - Dockerfile template
```

### Updating Team Standards

1. Edit `.tilt/team/standards.yaml`
2. Test changes locally
3. Run validation: `./scripts/team/validate-team-standards.sh`
4. Commit and communicate changes to team

### Environment Management

```bash
# Create environment-specific configurations
vim .tilt/environments/production.yaml

# Test environment settings
tilt up -- --environment=production --services=test-service
```

## Team Workflows

### Daily Development

```bash
# Start your development environment
tilt up -- --developer_id=$(whoami)

# Work on your code (live updates will handle changes)

# End of day cleanup
tilt down
```

### Adding New Features

```bash
# Create new service if needed
./scripts/team/create-service.sh feature-service python

# Add to your developer config
vim .tilt/developer-config.yaml
# Add 'feature-service' to enabled services

# Test locally
tilt up -- --services=feature-service --build_local=feature-service
```

### Configuration Updates

```bash
# Pull latest team configuration
git pull

# Restart Tilt to pick up changes
tilt down && tilt up

# Validate your environment still meets standards
./scripts/team/validate-team-standards.sh
```

## Troubleshooting

### Environment Issues

```bash
# Full environment validation
./scripts/validate-environment.sh

# Team standards validation
./scripts/team/validate-team-standards.sh

# Reset if needed
tilt down
kubectl delete namespace dev-$(whoami)
tilt up
```

### Configuration Issues

```bash
# Validate configuration syntax
tilt validate
yq eval '.services' .tilt/service-config.yaml

# Check for conflicts
grep -r "duplicate-name" .tilt/
```

For more detailed troubleshooting, see [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md).
EOF

print_status "Created team setup instructions"

print_header "Team Configuration Setup Complete"

echo ""
echo "✅ Team configuration and version control integration is now set up!"
echo ""
echo "What was created:"
echo "  📁 .tilt/team/ - Team standards and configuration"
echo "  📁 .tilt/environments/ - Environment-specific settings"
echo "  📁 .tilt/templates/ - Service templates"
echo "  📁 scripts/team/ - Team management scripts"
echo "  🔧 Git hooks for automatic validation"
echo "  📚 Team documentation and guides"
echo ""
echo "Next steps:"
echo "  1. Review and customize .tilt/team/standards.yaml"
echo "  2. Test service creation: ./scripts/team/create-service.sh test-service python"
echo "  3. Validate team standards: ./scripts/team/validate-team-standards.sh"
echo "  4. Commit team configuration: git add . && git commit -m 'Add team configuration'"
echo "  5. Share with team: git push"
echo ""
echo "For more information, see:"
echo "  - TEAM_CONFIGURATION.md"
echo "  - TEAM_SETUP.md"