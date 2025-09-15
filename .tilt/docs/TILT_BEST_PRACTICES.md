# Tilt Best Practices

This guide provides best practices for using the simplified Tilt development environment effectively.

## Core Philosophy

### Simplicity First
The current implementation follows Tilt's philosophy:
- **384 lines of code** (down from 7,500+)
- **3 files only** (Tiltfile, config.star, services.star)
- **Direct functions** instead of complex abstractions
- **Fast feedback loops** over feature richness

## Configuration Best Practices

### 1. Keep Service Configuration Simple

✅ **DO**: Use minimal configuration
```yaml
services:
  my-service:
    type: "python"
    build_context: "./services/my-service"
    dockerfile: "./services/my-service/Dockerfile"
    ports: [8000]
```

❌ **DON'T**: Add unnecessary complexity
```yaml
# Don't add config you don't need
services:
  my-service:
    type: "python"
    build_context: "./services/my-service"
    dockerfile: "./services/my-service/Dockerfile"
    ports: [8000, 8001, 8002, 8003]  # Too many ports
    env_vars:  # 20+ environment variables
      - name: "VAR1"
        value: "value1"
      # ... 20 more
```

### 2. Use Appropriate Service Types

| Use Case | Service Type | Why |
|----------|--------------|-----|
| Python APIs | `python` | Live updates support |
| Databases | `external` | Pre-built images |
| Java/Go/Node | Their type | Basic Docker builds |

### 3. Manage Dependencies Properly

Always include all dependencies when deploying:
```bash
# Correct - includes all dependencies
tilt up -- --services=api,database,redis 
# Wrong - missing dependencies
tilt up -- --services=api ```

## Development Workflow Best Practices

### 1. Daily Development Pattern

**Morning Startup:**
```bash
# Start your standard stack
tilt up -- --services=api,database,redis 
# Open Tilt UI
open http://localhost:10350
```

**During Development:**
- Make code changes
- Save files
- For Python: Live updates apply automatically
- For others: Use `tilt trigger service-name`

**End of Day:**
```bash
# Clean shutdown
tilt down
```

### 2. Use Developer Namespaces

Always use developer isolation:
```bash
# Good - isolated namespace
tilt up -- --services=api 
# Better - custom namespace for testing
tilt up -- --services=api --developer_id=feature-test
```

### 3. Monitor Resource Usage

Check Docker Desktop resources periodically:
- **Memory**: Allocate at least 4GB
- **CPU**: 2+ cores recommended
- **Disk**: Keep 10GB+ free

## Python Service Best Practices

### 1. Optimize for Live Updates

**Dockerfile Requirements:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app  # Must be /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

### 2. Use .dockerignore

Always exclude unnecessary files:
```
__pycache__
*.pyc
.git
.env
venv/
.pytest_cache/
*.log
.DS_Store
```

### 3. Keep Build Context Small

```bash
# Check build context size
du -sh services/my-service/

# Should be < 10MB for fast syncing
```

## Service Configuration Best Practices

### 1. Standard Ports

Use conventional ports for clarity:
```yaml
services:
  api: 
    ports: [8000]      # APIs: 8000-8999
  database:
    ports: [5432]      # PostgreSQL: 5432
  redis:
    ports: [6379]      # Redis: 6379
  frontend:
    ports: [3000]      # Frontend: 3000
```

### 2. Environment Variables

Keep environment variables minimal and clear:
```yaml
env_vars:
  - name: "DATABASE_URL"
    value: "postgresql://testuser:testpass@database:5432/db"
  - name: "LOG_LEVEL"
    value: "INFO"  # Use INFO for development, not DEBUG
```

### 3. Health Checks

Always define health checks:
```yaml
# HTTP health check for APIs
health_check:
  path: "/health"
  port: 8000

# Command health check for databases
health_check:
  command: ["pg_isready", "-U", "postgres"]
```

## Troubleshooting Best Practices

### 1. Check Tilt UI First

The Tilt UI provides immediate feedback:
- Build status
- Service logs
- Port forwarding info
- Error messages

### 2. Use Structured Debugging

```bash
# 1. Check Tilt status
tilt logs service-name

# 2. Check Kubernetes
kubectl get pods -n dev-$(whoami)
kubectl describe pod <pod-name> -n dev-$(whoami)

# 3. Check container
kubectl logs <pod-name> -n dev-$(whoami)
kubectl exec -it <pod-name> -n dev-$(whoami) -- /bin/bash
```

### 3. Clean Resets When Needed

```bash
# Soft reset
tilt down
tilt up -- --services=api,database 
# Hard reset (if issues persist)
tilt down
kubectl delete namespace dev-$(whoami)
docker system prune -f
tilt up -- --services=api,database ```

## Team Collaboration Best Practices

### 1. Service Configuration Changes

When modifying `.tilt/service-config.yaml`:
```bash
# 1. Test locally first
tilt up -- --services=new-service --developer_id=test

# 2. Commit with clear message
git add .tilt/service-config.yaml
git commit -m "Add new-service with PostgreSQL dependency"

# 3. Notify team
# "Added new-service - run: tilt up -- --services=new-service,database"
```

### 2. Documentation

Keep documentation current:
- Update service README when adding services
- Document special requirements
- Note any workarounds or limitations

### 3. Shared Standards

Agree on team conventions:
- Service naming (kebab-case)
- Port ranges for service types
- Standard environment variable names
- Common dependency patterns

## Performance Best Practices

### 1. Limit Concurrent Services

Don't run more than necessary:
```bash
# Good - only what you need
tilt up -- --services=api,database 
# Bad - everything at once
tilt up -- --services=api,auth,frontend,admin,database,redis,elasticsearch ```

### 2. Use External Images for Infrastructure

```yaml
# Good - use pre-built images
database:
  type: "external"
  image: "postgres:14"

# Avoid - building PostgreSQL locally
database:
  type: "external"
  build_context: "./custom-postgres"
```

### 3. Clean Up Unused Resources

```bash
# Remove unused images
docker image prune -f

# Remove unused volumes
docker volume prune -f

# Clean everything (careful!)
docker system prune -a --volumes -f
```

## Anti-Patterns to Avoid

### 1. ❌ Over-Engineering

**Don't** add complexity for hypothetical needs:
- No plugin systems
- No dynamic configuration
- No abstract frameworks

### 2. ❌ Ignoring Simplicity

**Don't** try to recreate removed features:
- No monitoring dashboards
- No ECR integration
- No environment presets

### 3. ❌ Manual Port Management

**Don't** hardcode localhost ports in code:
```python
# Bad
API_URL = "http://localhost:8000"

# Good
API_URL = os.getenv("API_URL", "http://api:8000")
```

### 4. ❌ Skipping Health Checks

Always define health checks for proper dependency management.

### 5. ❌ Large Build Contexts

Keep build contexts under 10MB for fast live updates.

## Quick Reference

### Essential Commands
```bash
# Start services
tilt up -- --services=api,database 
# Stop everything
tilt down

# View logs
tilt logs service-name

# Trigger rebuild
tilt trigger service-name

# Check status
kubectl get all -n dev-$(whoami)
```

### File Locations
```
Tiltfile                    # Main orchestration (90 lines)
.tilt/config.star          # Config parsing (42 lines)
.tilt/services.star        # Service deployment (252 lines)
.tilt/service-config.yaml  # Service definitions
```

### Key Principles
1. **Simplicity**: Less code is better code
2. **Fast Feedback**: Live updates for Python
3. **Isolation**: Developer namespaces
4. **Clarity**: Direct, obvious implementations

## Summary

The simplified Tilt implementation prioritizes:
- **Simplicity** over features
- **Clarity** over abstraction
- **Speed** over flexibility
- **Maintainability** over extensibility

Follow these practices to maintain a clean, fast, and reliable development environment.

Remember: **If it seems complex, you're probably doing it wrong.**