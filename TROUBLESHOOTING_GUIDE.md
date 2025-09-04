# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the Tilt-based development environment.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [Service-Specific Issues](#service-specific-issues)
- [Performance Issues](#performance-issues)
- [Configuration Issues](#configuration-issues)
- [Cluster Issues](#cluster-issues)
- [Advanced Troubleshooting](#advanced-troubleshooting)
- [Getting Help](#getting-help)

## Quick Diagnostics

### First Steps for Any Issue

1. **Check the Tilt UI** at [http://localhost:10350](http://localhost:10350)
   - Look for red/yellow status indicators
   - Review error messages and logs

2. **Run environment validation**
   ```bash
   ./scripts/validate-environment.sh
   ```

3. **Check basic connectivity**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

4. **Verify your configuration**
   ```bash
   tilt validate
   ```

### Quick Reset Commands

```bash
# Soft reset - restart Tilt
tilt down
tilt up

# Medium reset - clean namespace
tilt down
kubectl delete namespace dev-$(whoami)
tilt up

# Hard reset - clean everything
tilt down
docker system prune -f
kubectl delete namespace dev-$(whoami)
tilt up
```

## Common Issues

### Issue: Tilt Won't Start

#### Symptoms
- `tilt up` command fails immediately
- Error messages about configuration or cluster connectivity

#### Diagnosis
```bash
# Check Tilt configuration
tilt validate

# Check cluster connectivity
kubectl cluster-info

# Check Docker status
docker info
```

#### Solutions
1. **Invalid Tiltfile syntax**
   ```bash
   tilt validate
   # Fix syntax errors shown in output
   ```

2. **Kubernetes cluster not accessible**
   ```bash
   # For Docker Desktop
   # Enable Kubernetes in Docker Desktop settings
   
   # For kind
   kind create cluster --name tilt-dev
   
   # For k3d
   k3d cluster create tilt-dev
   ```

3. **Docker not running**
   ```bash
   # Start Docker Desktop or Docker daemon
   # On macOS: Start Docker Desktop app
   # On Linux: sudo systemctl start docker
   ```

### Issue: Service Won't Deploy

#### Symptoms
- Service shows red status in Tilt UI
- Build errors or deployment failures
- Pod stuck in pending/error state

#### Diagnosis
```bash
# Check service status
kubectl get pods -n dev-$(whoami)
kubectl describe pod <pod-name> -n dev-$(whoami)

# Check service logs
tilt logs <service-name>
kubectl logs deployment/<service-name> -n dev-$(whoami)
```

#### Solutions
1. **Image build failures**
   ```bash
   # Check Dockerfile syntax
   docker build -t test-build ./path/to/service
   
   # Check build context
   ls -la ./path/to/service
   ```

2. **Resource constraints**
   ```bash
   # Check node resources
   kubectl top nodes
   
   # Reduce resource requests in service-config.yaml
   resources:
     requests:
       cpu: "50m"      # Reduce from higher values
       memory: "64Mi"
   ```

3. **Missing dependencies**
   ```bash
   # Check if dependency services are running
   kubectl get pods -n dev-$(whoami)
   
   # Start dependencies first
   tilt up -- --services=database,redis
   # Then start your service
   ```

### Issue: Live Updates Not Working

#### Symptoms
- Code changes don't trigger rebuilds
- Changes don't appear in running containers
- Slow or no response to file changes

#### Diagnosis
```bash
# Check live update configuration
tilt logs <service-name> | grep -i sync

# Verify file paths
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- ls -la /app

# Check file watching
tilt logs | grep -i watch
```

#### Solutions
1. **Incorrect sync paths**
   ```yaml
   # Fix paths in service-config.yaml
   live_update:
     sync_rules:
       - local_path: "./src"          # Correct local path
         remote_path: "/app/src"      # Correct container path
   ```

2. **Files being ignored**
   ```yaml
   # Check ignore patterns
   live_update:
     ignore_patterns:
       - "**/*.pyc"
       - "**/__pycache__"
       # Remove patterns that might be blocking your files
   ```

3. **Container doesn't support live updates**
   ```yaml
   # Add restart fallback
   live_update:
     sync_rules:
       - local_path: "./src"
         remote_path: "/app/src"
     restart_container: true  # Force restart if sync fails
   ```

### Issue: Port Forwarding Not Working

#### Symptoms
- Cannot access services via localhost
- Connection refused errors
- Services not accessible from browser

#### Diagnosis
```bash
# Check port forwarding status
kubectl get services -n dev-$(whoami)
kubectl port-forward service/<service-name> 8080:8080 -n dev-$(whoami)

# Check if ports are in use
lsof -i :8080
```

#### Solutions
1. **Port conflicts**
   ```bash
   # Find what's using the port
   lsof -i :8080
   
   # Kill the process or use different port
   tilt up -- --port_offset=100  # Use ports 8180, 8181, etc.
   ```

2. **Service not exposing correct port**
   ```yaml
   # Fix service configuration
   services:
     my-service:
       ports: [8080]  # Ensure this matches container port
   ```

3. **Firewall blocking connections**
   ```bash
   # Check firewall rules (varies by OS)
   # macOS: System Preferences > Security & Privacy > Firewall
   # Linux: sudo ufw status
   ```

## Service-Specific Issues

### Python Services

#### Issue: Dependencies not installing
```bash
# Check requirements.txt
cat requirements.txt

# Verify pip install in container
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- pip list

# Fix live update rules
live_update:
  sync_rules:
    - local_path: "./requirements.txt"
      remote_path: "/app/requirements.txt"
  run_commands:
    - "pip install -r requirements.txt"
  restart_on:
    - "requirements.txt"
```

#### Issue: Import errors
```bash
# Check Python path
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- python -c "import sys; print(sys.path)"

# Verify file sync
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- ls -la /app/src
```

### Java Services

#### Issue: Compilation errors
```bash
# Check Maven/Gradle build
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- mvn compile

# Verify classpath
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- java -cp /app/classes MyClass
```

#### Issue: Hot reload not working
```yaml
# Use proper live update for Java
live_update:
  sync_rules:
    - local_path: "./target/classes"
      remote_path: "/app/classes"
  restart_container: true  # Java often needs restart
  fall_back_on:
    - "pom.xml"
    - "src/main/resources"
```

### Go Services

#### Issue: Build failures
```bash
# Check Go modules
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- go mod tidy

# Verify build
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- go build ./cmd
```

### Node.js Services

#### Issue: npm install failures
```bash
# Check package.json
cat package.json

# Clear npm cache
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- npm cache clean --force

# Use npm ci for consistent installs
live_update:
  run_commands:
    - "npm ci"  # Instead of npm install
```

## Performance Issues

### Issue: Slow Builds

#### Diagnosis
```bash
# Check build times in Tilt UI
# Look for bottlenecks in build logs

# Check Docker build cache
docker system df
```

#### Solutions
1. **Optimize Dockerfile**
   ```dockerfile
   # Use multi-stage builds
   FROM node:16-alpine AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci --only=production
   
   FROM node:16-alpine AS runtime
   COPY --from=builder /app/node_modules ./node_modules
   COPY . .
   ```

2. **Improve build context**
   ```bash
   # Add .dockerignore
   echo "node_modules" >> .dockerignore
   echo ".git" >> .dockerignore
   echo "*.log" >> .dockerignore
   ```

3. **Use build caching**
   ```yaml
   services:
     my-service:
       build_args:
         - "BUILDKIT_INLINE_CACHE=1"
   ```

### Issue: High Resource Usage

#### Diagnosis
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n dev-$(whoami)
docker stats
```

#### Solutions
1. **Reduce resource requests**
   ```yaml
   services:
     my-service:
       resources:
         requests:
           cpu: "50m"     # Reduce from higher values
           memory: "64Mi"
   ```

2. **Limit concurrent builds**
   ```yaml
   # In Tiltfile
   update_settings(max_parallel_updates=2)
   ```

3. **Clean up unused resources**
   ```bash
   docker system prune -f
   kubectl delete pods --field-selector=status.phase=Succeeded -n dev-$(whoami)
   ```

## Configuration Issues

### Issue: Invalid YAML Configuration

#### Diagnosis
```bash
# Validate YAML syntax
yq eval '.services' .tilt/service-config.yaml

# Check for common YAML issues
python -c "import yaml; yaml.safe_load(open('.tilt/service-config.yaml'))"
```

#### Solutions
1. **Fix indentation**
   ```yaml
   # Correct indentation (2 spaces)
   services:
     my-service:
       type: "python"
       ports: [8080]
   ```

2. **Quote special values**
   ```yaml
   env_vars:
     - name: "VERSION"
       value: "1.0"  # Quote numeric-looking strings
   ```

### Issue: Service Dependencies Not Working

#### Diagnosis
```bash
# Check dependency order
kubectl get pods -n dev-$(whoami) -o wide

# Verify service discovery
kubectl get endpoints -n dev-$(whoami)
```

#### Solutions
1. **Fix dependency configuration**
   ```yaml
   services:
     web-service:
       dependencies: ["database", "redis"]  # Ensure dependencies exist
   ```

2. **Check service names**
   ```bash
   # Services must match exactly
   kubectl get services -n dev-$(whoami)
   ```

## Cluster Issues

### Issue: Cluster Not Accessible

#### Diagnosis
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# Check kubeconfig
kubectl config current-context
kubectl config get-contexts
```

#### Solutions
1. **Switch to correct context**
   ```bash
   kubectl config use-context docker-desktop
   # or
   kubectl config use-context kind-tilt-dev
   ```

2. **Recreate cluster**
   ```bash
   # For kind
   kind delete cluster --name tilt-dev
   kind create cluster --name tilt-dev
   
   # For k3d
   k3d cluster delete tilt-dev
   k3d cluster create tilt-dev
   ```

### Issue: Insufficient Cluster Resources

#### Diagnosis
```bash
# Check node capacity
kubectl describe nodes

# Check resource quotas
kubectl describe namespace dev-$(whoami)
```

#### Solutions
1. **Increase cluster resources**
   ```bash
   # For Docker Desktop: Increase resources in settings
   # For kind: Create cluster with more resources
   kind create cluster --name tilt-dev --config - <<EOF
   kind: Cluster
   apiVersion: kind.x-k8s.io/v1alpha4
   nodes:
   - role: control-plane
     extraMounts:
     - hostPath: /var/run/docker.sock
       containerPath: /var/run/docker.sock
   EOF
   ```

2. **Reduce service resource requests**
   ```yaml
   resources:
     requests:
       cpu: "50m"
       memory: "64Mi"
   ```

## Advanced Troubleshooting

### Debug Mode

Enable debug mode for verbose logging:
```bash
tilt up -- --enable_debug=true
```

### Tilt Logs Analysis

```bash
# View all Tilt logs
tilt logs --follow

# Filter logs for specific service
tilt logs <service-name>

# Search logs for errors
tilt logs | grep -i error
```

### Kubernetes Debugging

```bash
# Get detailed pod information
kubectl describe pod <pod-name> -n dev-$(whoami)

# Check events
kubectl get events -n dev-$(whoami) --sort-by='.lastTimestamp'

# Debug networking
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- nslookup <other-service>
```

### Container Debugging

```bash
# Access container shell
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- /bin/bash

# Check container processes
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- ps aux

# Check container environment
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- env
```

### File System Debugging

```bash
# Check file permissions
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- ls -la /app

# Verify file sync
kubectl exec -it deployment/<service-name> -n dev-$(whoami) -- find /app -name "*.py" -newer /tmp/sync-marker
```

## Getting Help

### Self-Service Resources

1. **Run diagnostics**
   ```bash
   ./scripts/validate-environment.sh
   ```

2. **Check documentation**
   - [DEVELOPER_ONBOARDING.md](DEVELOPER_ONBOARDING.md)
   - [TILT_CONFIGURATION_GUIDE.md](TILT_CONFIGURATION_GUIDE.md)
   - [TILT_BEST_PRACTICES.md](TILT_BEST_PRACTICES.md)

3. **Official documentation**
   - [Tilt Documentation](https://docs.tilt.dev/)
   - [Kubernetes Documentation](https://kubernetes.io/docs/)

### Collecting Information for Support

When asking for help, include:

```bash
# Environment information
./scripts/validate-environment.sh > environment-report.txt

# Tilt logs
tilt logs > tilt-logs.txt

# Kubernetes information
kubectl get all -n dev-$(whoami) > k8s-resources.txt
kubectl describe pods -n dev-$(whoami) > k8s-pod-details.txt

# Configuration files
tar -czf config-files.tar.gz .tilt/ Tiltfile tilt_config.json
```

### Common Support Channels

1. **Team Slack/Chat** - For team-specific issues
2. **Internal Documentation** - Check team wiki or docs
3. **Tilt Community** - [Tilt Slack](https://tilt.dev/community)
4. **GitHub Issues** - For bugs in this repository

### Emergency Procedures

If you need to quickly get back to a working state:

```bash
# Nuclear option - reset everything
tilt down
docker system prune -af
kubectl delete namespace dev-$(whoami)
kind delete cluster --name tilt-dev
kind create cluster --name tilt-dev
tilt up
```

Remember: Most issues can be resolved with the quick reset commands at the top of this guide. Start simple before trying complex solutions!