# Tilt Best Practices Guide

This guide outlines best practices for using Tilt effectively in your development workflow, optimizing performance, and maintaining a productive development environment.

## Table of Contents

- [Development Workflow](#development-workflow)
- [Configuration Management](#configuration-management)
- [Performance Optimization](#performance-optimization)
- [Resource Management](#resource-management)
- [Team Collaboration](#team-collaboration)
- [Debugging and Troubleshooting](#debugging-and-troubleshooting)
- [Security Considerations](#security-considerations)
- [Maintenance and Updates](#maintenance-and-updates)

## Development Workflow

### Daily Development Routine

#### Starting Your Day
```bash
# 1. Pull latest changes
git pull origin main

# 2. Start your development environment
tilt up -- --developer_id=$(whoami)

# 3. Verify services are running
# Check Tilt UI at http://localhost:10350
```

#### During Development
- **Make small, incremental changes** to leverage live updates
- **Monitor the Tilt UI** for build status and logs
- **Use port forwarding** to test services locally
- **Check resource usage** periodically to avoid cluster overload

#### Ending Your Day
```bash
# Clean shutdown to free resources
tilt down

# Optional: Clean up unused Docker images
docker system prune -f
```

### Service Development Strategy

#### Focus on One Service at a Time
```bash
# Work on a specific service
tilt up -- --services=my-active-service --build_local=my-active-service
```

#### Use Stable Dependencies
```bash
# Use ECR images for services you're not changing
tilt up -- --services=service1,service2,service3 --build_local=service1
```

#### Incremental Service Addition
```bash
# Start with core services, add others as needed
tilt up -- --services=database,api-service
# Later add: --services=database,api-service,web-service
```

## Configuration Management

### File Organization

#### Keep Configuration Modular
```
.tilt/
├── service-config.yaml          # Team-wide service definitions
├── developer-config.yaml        # Your personal settings
├── developer-config.yaml.template  # Template for new developers
└── environments/
    ├── development.yaml         # Development overrides
    ├── testing.yaml            # Testing overrides
    └── staging.yaml            # Staging overrides
```

#### Version Control Best Practices
```bash
# Always commit shared configuration changes
git add .tilt/service-config.yaml Tiltfile
git commit -m "Add new service configuration"

# Keep personal config out of version control
echo ".tilt/developer-config.yaml" >> .gitignore
```

### Configuration Validation

#### Pre-commit Validation
```bash
# Create a pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Validate Tilt configuration before commit
tilt validate --file=Tiltfile
if [ $? -ne 0 ]; then
    echo "Tilt configuration validation failed"
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

#### Regular Configuration Audits
```bash
# Weekly configuration review
./scripts/validate-environment.sh
./scripts/audit-service-config.sh
```

## Performance Optimization

### Build Optimization

#### Use Multi-Stage Dockerfiles
```dockerfile
# Dockerfile.optimized
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:16-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

#### Optimize Docker Build Context
```bash
# .dockerignore
node_modules
.git
.tilt
*.log
.DS_Store
coverage/
.nyc_output
```

#### Use Build Caching
```yaml
# service-config.yaml
services:
  my-service:
    build_args:
      - "BUILDKIT_INLINE_CACHE=1"
    cache_from:
      - "my-service:latest"
```

### Live Update Optimization

#### Minimize Sync Operations
```yaml
# Sync only what's necessary
live_update:
  sync_rules:
    - local_path: "./src"          # Only source code
      remote_path: "/app/src"
  ignore_patterns:
    - "**/*.log"                   # Ignore log files
    - "**/.DS_Store"              # Ignore system files
    - "**/node_modules"           # Ignore dependencies
```

#### Use Efficient Restart Strategies
```yaml
# Python: Restart only when dependencies change
live_update:
  sync_rules:
    - local_path: "./src"
      remote_path: "/app/src"
  run_commands:
    - "pip install -r requirements.txt"
  restart_on:
    - "requirements.txt"          # Only restart for dependency changes
```

### Resource Optimization

#### Right-Size Resource Requests
```yaml
# Start conservative, monitor, and adjust
services:
  my-service:
    resources:
      requests:
        cpu: "100m"               # Start small
        memory: "128Mi"
      limits:
        cpu: "500m"               # Allow bursting
        memory: "512Mi"
```

#### Monitor Resource Usage
```bash
# Regular resource monitoring
kubectl top nodes
kubectl top pods -n dev-$(whoami)

# Set up resource alerts
./scripts/setup-resource-monitoring.sh
```

## Resource Management

### Namespace Management

#### Use Descriptive Namespaces
```yaml
developer:
  id: "john-doe"
  namespace: "dev-john-doe-feature-auth"  # Include feature context
```

#### Set Appropriate Quotas
```yaml
resources:
  namespace_quota:
    requests.cpu: "2"             # Reasonable for development
    requests.memory: "4Gi"
    limits.cpu: "4"               # Allow some bursting
    limits.memory: "8Gi"
    persistentvolumeclaims: "5"   # Limit storage claims
```

### Service Scaling

#### Scale Based on Usage
```yaml
# Development: Single replica
services:
  my-service:
    replicas: 1

# Testing: Multiple replicas
environments:
  testing:
    services:
      my-service:
        replicas: 2
```

#### Use Horizontal Pod Autoscaling
```yaml
services:
  scalable-service:
    hpa:
      enabled: true
      min_replicas: 1
      max_replicas: 3
      target_cpu_utilization: 70
```

## Team Collaboration

### Shared Configuration

#### Document Configuration Changes
```yaml
# service-config.yaml
services:
  new-service:
    # Added for feature XYZ - John Doe, 2024-01-15
    type: "python"
    build_context: "./new-service"
    # Dependencies: requires database migration v1.2.3
    dependencies: ["database"]
```

#### Use Configuration Templates
```bash
# Create service template
./scripts/create-service-template.sh my-new-service python

# This generates:
# - Service configuration
# - Dockerfile template
# - Basic project structure
```

### Environment Consistency

#### Standardize Development Tools
```yaml
# .tilt/team-standards.yaml
standards:
  docker_version: ">=20.10.0"
  kubectl_version: ">=1.21.0"
  tilt_version: ">=0.30.0"
  
validation:
  pre_start_checks:
    - docker_version
    - kubectl_connectivity
    - resource_availability
```

#### Share Environment Validation
```bash
# Team validation script
./scripts/validate-team-environment.sh

# Checks:
# - Tool versions
# - Cluster connectivity
# - Resource availability
# - Configuration validity
```

### Code Review Integration

#### Include Tilt Changes in Reviews
```bash
# Review checklist for Tilt changes:
# □ Service configuration is valid
# □ Resource limits are appropriate
# □ Dependencies are correctly specified
# □ Live update rules are optimized
# □ Documentation is updated
```

## Debugging and Troubleshooting

### Systematic Debugging Approach

#### 1. Check Tilt UI First
- Look for red/yellow status indicators
- Review build logs for errors
- Check service startup logs

#### 2. Validate Configuration
```bash
# Validate Tilt configuration
tilt validate

# Check service configuration
./scripts/validate-service-config.sh

# Verify Kubernetes connectivity
kubectl cluster-info
```

#### 3. Check Resource Constraints
```bash
# Check node resources
kubectl top nodes

# Check namespace resources
kubectl describe namespace dev-$(whoami)

# Check pod resources
kubectl top pods -n dev-$(whoami)
```

#### 4. Examine Service Details
```bash
# Get pod details
kubectl describe pod <pod-name> -n dev-$(whoami)

# Check service logs
kubectl logs -f deployment/<service-name> -n dev-$(whoami)

# Check service endpoints
kubectl get endpoints -n dev-$(whoami)
```

### Common Issues and Solutions

#### Service Won't Start
```bash
# Check image pull status
kubectl describe pod <pod-name> -n dev-$(whoami) | grep -A 10 "Events:"

# Verify image exists
docker images | grep <service-name>

# Check resource availability
kubectl describe nodes
```

#### Live Updates Not Working
```bash
# Check file sync paths
tilt logs <service-name> | grep -i sync

# Verify container file system
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- ls -la /app

# Check ignore patterns
# Review .dockerignore and live_update ignore_patterns
```

#### Performance Issues
```bash
# Monitor resource usage
watch kubectl top pods -n dev-$(whoami)

# Check Docker resource usage
docker stats

# Review Tilt performance
tilt analytics opt-in  # Enable analytics for insights
```

## Security Considerations

### Secrets Management

#### Never Commit Secrets
```bash
# Use environment variables or secret files
echo "SECRET_KEY=your-secret" > .env
echo ".env" >> .gitignore

# Use Kubernetes secrets
kubectl create secret generic my-secret \
  --from-literal=key=value \
  -n dev-$(whoami)
```

#### Use Least Privilege Access
```yaml
# service-config.yaml
services:
  my-service:
    security_context:
      run_as_non_root: true
      run_as_user: 1000
      read_only_root_filesystem: true
      allow_privilege_escalation: false
```

### Network Security

#### Limit Service Exposure
```yaml
services:
  internal-service:
    ports: [8080]
    port_forwards: false        # Don't expose externally
    
  public-service:
    ports: [8080]
    port_forwards: true         # OK to expose for testing
```

#### Use Network Policies
```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: dev-isolation
  namespace: dev-$(whoami)
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: dev-$(whoami)
```

## Maintenance and Updates

### Regular Maintenance Tasks

#### Weekly Tasks
```bash
# Update Tilt and tools
brew upgrade tilt kubectl

# Clean up unused resources
tilt down
docker system prune -f
kubectl delete pods --field-selector=status.phase=Succeeded -n dev-$(whoami)
```

#### Monthly Tasks
```bash
# Review and update service configurations
./scripts/audit-service-config.sh

# Update base images
./scripts/update-base-images.sh

# Review resource usage patterns
./scripts/analyze-resource-usage.sh
```

### Version Management

#### Pin Tool Versions
```yaml
# .tilt/tool-versions
tilt: "0.30.12"
kubectl: "1.25.4"
docker: "20.10.21"
```

#### Gradual Updates
```bash
# Test updates in isolation
tilt up -- --services=test-service --developer_id=$(whoami)-test

# Validate before team rollout
./scripts/validate-update.sh

# Communicate changes to team
git commit -m "Update Tilt to v0.30.12 - tested with all services"
```

### Backup and Recovery

#### Configuration Backup
```bash
# Backup important configurations
tar -czf tilt-config-backup-$(date +%Y%m%d).tar.gz \
  .tilt/ Tiltfile tilt_config.json

# Store in secure location
```

#### Environment Recovery
```bash
# Quick environment reset
tilt down
kubectl delete namespace dev-$(whoami)
tilt up -- --developer_id=$(whoami)

# Full environment rebuild
./scripts/reset-development-environment.sh
```

## Performance Metrics

### Key Metrics to Monitor

#### Build Performance
- **Build time**: Target < 2 minutes for full builds
- **Live update time**: Target < 10 seconds
- **Image size**: Optimize for < 500MB per service

#### Resource Usage
- **CPU utilization**: Keep < 70% average
- **Memory usage**: Monitor for memory leaks
- **Disk usage**: Clean up regularly

#### Developer Experience
- **Time to first deployment**: Target < 5 minutes
- **Code change to running**: Target < 30 seconds
- **Environment setup time**: Target < 10 minutes

### Optimization Targets

```yaml
# Performance targets
targets:
  build_time:
    full_build: "< 2 minutes"
    live_update: "< 10 seconds"
  
  resource_usage:
    cpu_average: "< 70%"
    memory_growth: "< 10% per hour"
  
  developer_experience:
    first_deployment: "< 5 minutes"
    change_to_running: "< 30 seconds"
    setup_time: "< 10 minutes"
```

By following these best practices, you'll maintain a fast, reliable, and collaborative development environment that scales with your team's needs.