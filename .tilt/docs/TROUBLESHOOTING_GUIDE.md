# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the simplified Tilt development environment.

## Quick Diagnostics

### Check System Status
```bash
# 1. Check Tilt is running
tilt version

# 2. Check Kubernetes cluster
kubectl cluster-info

# 3. Check your namespace
kubectl get all -n dev-$(whoami)

# 4. Check Tilt UI
open http://localhost:10350
```

## Common Issues and Solutions

### 1. Tilt Won't Start

#### Symptom
```
Error: cannot connect to Kubernetes cluster
```

#### Solution
1. Verify Docker Desktop is running
2. Enable Kubernetes in Docker Desktop settings
3. Check cluster context:
   ```bash
   kubectl config current-context
   kubectl cluster-info
   ```

### 2. Service Not Deploying

#### Symptom
Service doesn't appear in Tilt UI or shows errors

#### Diagnosis
```bash
# Check if service is defined
grep "service-name" .tilt/service-config.yaml

# Check Tilt logs
tilt logs

# Check namespace
kubectl get all -n dev-$(whoami)
```

#### Common Causes
- **Service name typo**: Check spelling in `--services` flag
- **Missing configuration**: Verify service exists in `.tilt/service-config.yaml`
- **Build context missing**: Ensure `build_context` path exists
- **Dockerfile missing**: Verify `dockerfile` path is correct

### 3. Build Failures

#### Symptom
Red build status in Tilt UI

#### Diagnosis
```bash
# View build logs in Tilt UI
# Or check via CLI
tilt logs service-name
```

#### Common Causes
- **Dockerfile errors**: Check Dockerfile syntax
- **Missing files**: Ensure all COPY sources exist
- **Base image issues**: Verify base image is accessible

#### Example Fix
```dockerfile
# Ensure WORKDIR matches your app structure
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

### 4. Live Updates Not Working

#### Symptom
Code changes don't trigger reload in supported services

#### Diagnosis
```bash
# Check if files are syncing
kubectl exec -it deployment/service-name -n dev-$(whoami) -- ls -la /app/

# Check service type configuration
grep "type:" .tilt/service-config.yaml -A 1
```

#### Solutions by Service Type

**Python Services:**
```dockerfile
# Ensure uvicorn has --reload
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
WORKDIR /app  # Must be /app
```

**Node.js Services:**
```json
// package.json must have nodemon
"scripts": {
  "dev": "nodemon src/index.js"
}
```

**Java Services:**
```xml
<!-- pom.xml needs Spring DevTools -->
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-devtools</artifactId>
</dependency>
```

**Go Services:**
```bash
# Verify directory structure
ls services/service-name/cmd
ls services/service-name/pkg
```

### 5. Port Forwarding Issues

#### Symptom
Cannot access service on localhost

#### Diagnosis
```bash
# Check port forwarding in Tilt UI
# Or manually forward
kubectl port-forward service/service-name 8000:8000 -n dev-$(whoami)
```

#### Common Causes
- **Port already in use**: Another process using the port
- **Service not running**: Pod may be crashing
- **Wrong port**: Check service configuration

### 6. Database Connection Errors

#### Symptom
Application can't connect to database

#### Diagnosis
```bash
# Check database is running
kubectl get pods -n dev-$(whoami) | grep database

# Check database logs
kubectl logs deployment/database -n dev-$(whoami)

# Test connection
kubectl exec -it deployment/database -n dev-$(whoami) -- pg_isready
```

#### Solution
1. Ensure database is included in services:
   ```bash
   tilt up -- --services=app,database,redis    ```

2. Verify connection string:
   ```yaml
   env_vars:
     - name: "DATABASE_URL"
       value: "postgresql://testuser:testpass@database:5432/testdb"
   ```

### 7. Namespace Issues

#### Symptom
Resources not found or permission denied

#### Diagnosis
```bash
# Check current namespace
kubectl config view --minify --output 'jsonpath={..namespace}'

# List all namespaces
kubectl get namespaces

# Check resources in your namespace
kubectl get all -n dev-$(whoami)
```

#### Solution
```bash
# Create namespace if missing
kubectl create namespace dev-$(whoami)

# Use correct developer_id
tilt up -- --services=app ```

### 8. Dependencies Not Starting

#### Symptom
Service fails because dependencies aren't ready

#### Solution
Include all dependencies in the services list:
```bash
# Wrong - missing dependencies
tilt up -- --services=app 
# Correct - includes dependencies
tilt up -- --services=app,database,redis ```

### 9. Memory/Resource Issues

#### Symptom
Pods getting OOMKilled or evicted

#### Diagnosis
```bash
# Check pod status
kubectl describe pod <pod-name> -n dev-$(whoami)

# Check Docker Desktop resources
# Settings -> Resources -> Advanced
```

#### Solution
1. Increase Docker Desktop memory allocation
2. Reduce number of services running
3. Add resource limits to service config

### 10. Cluster Safety Errors

#### Symptom
```
ERROR: Refusing to run on production-like cluster
```

#### Solution
The system prevents running on production clusters. Use only:
- docker-desktop
- kind
- minikube
- k3d

## Debugging Commands

### Essential Commands
```bash
# View all resources
kubectl get all -n dev-$(whoami)

# Describe a failing pod
kubectl describe pod <pod-name> -n dev-$(whoami)

# View pod logs
kubectl logs <pod-name> -n dev-$(whoami)

# Execute commands in container
kubectl exec -it <pod-name> -n dev-$(whoami) -- /bin/bash

# Check events
kubectl get events -n dev-$(whoami) --sort-by='.lastTimestamp'
```

### Tilt-Specific Commands
```bash
# View Tilt logs
tilt logs --follow

# Trigger rebuild
tilt trigger service-name

# Check Tilt status
curl http://localhost:10350/api/view
```

## Reset Procedures

### Soft Reset
```bash
# Restart services
tilt down
tilt up -- --services=app,database,redis ```

### Hard Reset
```bash
# Delete everything and start fresh
tilt down
kubectl delete namespace dev-$(whoami)
docker system prune -a  # Warning: removes all unused images
tilt up -- --services=app,database,redis ```

## Architecture Reference

The simplified implementation has only 3 files to check:

1. **Tiltfile** - Main orchestration logic
2. **.tilt/config.star** - Configuration parsing
3. **.tilt/services.star** - Service deployment

If something isn't working, the issue is likely in one of these files or your service configuration.

## Service Configuration Issues

### Invalid YAML
```bash
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('.tilt/service-config.yaml'))"
```

### Missing Required Fields
Each service needs:
- `type` - Service type (python, external, etc.)
- Either `build_context`+`dockerfile` OR `image`

### Example Working Configuration
```yaml
services:
  my-app:
    type: "python"
    build_context: "./services/my-app"
    dockerfile: "./services/my-app/Dockerfile"
    ports: [8000]
    env_vars:
      - name: "LOG_LEVEL"
        value: "DEBUG"
```

## Getting Help

1. **Check Tilt UI**: http://localhost:10350 for real-time status
2. **Review logs**: Both Tilt logs and kubectl logs
3. **Verify configuration**: Check `.tilt/service-config.yaml`
4. **Check source code**: Only 3 files to review
5. **Tilt Documentation**: https://docs.tilt.dev/

## Known Limitations

The simplified implementation does NOT support:
- ECR images
- Dynamic port allocation
- Monitoring dashboards
- Environment configurations
- Plugin framework
- Command-based builds (Maven, Gradle)
- Live updates for non-Python services

These features were intentionally removed for simplicity.