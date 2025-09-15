# Live Update Guide

Live updates allow you to see code changes reflected in your running services without rebuilding Docker images. The Tilt implementation supports live updates for multiple service types with different strategies.

## How Live Updates Work

### Python Services

For Python services, live updates work through a simple two-step process:

1. **File Sync**: Tilt syncs changed files to the container at `/app/`
2. **Auto-Reload**: Uvicorn's `--reload` flag detects changes and restarts the Python process

This results in updates applying in **under 2 seconds**.

### Node.js Services

For Node.js services, live updates include:

1. **Source Sync**: Syncs `/src` directory and `package.json` files
2. **Dependency Updates**: Runs `npm install` when `package.json` changes
3. **Auto-Restart**: Node process restarts on file changes (requires nodemon or similar)

### Java Services

For Java services, live updates include:

1. **Source Sync**: Syncs `/src` directory and `pom.xml`
2. **Compilation**: Runs `mvn compile` when `pom.xml` changes
3. **Hot Reload**: Requires Spring DevTools or similar for auto-restart

### Go Services

For Go services, live updates include:

1. **Source Sync**: Syncs `/cmd`, `/pkg` directories and go module files
2. **Rebuild**: Runs `go build` when Go files change
3. **Binary Update**: Replaces the running binary

### External Services

Live updates are **NOT** available for:
- ❌ External services (databases, redis, etc.)

These services use pre-built images and don't support live updates.

## Configuration Requirements

### Python Services

1. **Service Type**: Must be `type: "python"` in service config
2. **Dockerfile**: Must use uvicorn with `--reload` flag
3. **WORKDIR**: Must be `/app` in Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

### Node.js Services

1. **Service Type**: Must be `type: "node"` or `type: "nodejs"` in service config
2. **Dockerfile**: Should use nodemon or similar for auto-restart
3. **Directory Structure**: Source code in `/src` directory

```dockerfile
FROM node:18-slim
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]  # Assumes package.json has "dev": "nodemon src/index.js"
```

### Java Services

1. **Service Type**: Must be `type: "java"` in service config
2. **Build Tool**: Maven with `pom.xml` in project root
3. **Hot Reload**: Spring Boot DevTools recommended

```dockerfile
FROM maven:3.8-openjdk-17
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
CMD ["mvn", "spring-boot:run"]
```

### Go Services

1. **Service Type**: Must be `type: "go"` in service config
2. **Structure**: Code in `/cmd` and `/pkg` directories
3. **Module**: `go.mod` and `go.sum` files required

```dockerfile
FROM golang:1.21-alpine
WORKDIR /app
COPY go.* .
RUN go mod download
COPY . .
RUN go build -o main ./cmd
CMD ["./main"]
```

## How It's Implemented

The live update configuration is automatically applied in `.tilt/services.star`:

```python
def get_live_updates(service_type, build_context):
    if service_type == "python":
        return [
            sync(build_context + '/', '/app/'),  # Sync all files to /app
            # Uvicorn --reload handles restart automatically
        ]
    elif service_type == "nodejs" or service_type == "node":
        return [
            sync(build_context + '/src', '/app/src'),
            sync(build_context + '/package*.json', '/app/'),
            run('npm install', trigger=[build_context + '/package.json'])
        ]
    elif service_type == "java":
        return [
            sync(build_context + '/src', '/app/src'),
            sync(build_context + '/pom.xml', '/app/pom.xml'),
            run('mvn compile', trigger=[build_context + '/pom.xml'])
        ]
    elif service_type == "go":
        return [
            sync(build_context + '/cmd', '/app/cmd'),
            sync(build_context + '/pkg', '/app/pkg'),
            sync(build_context + '/go.*', '/app/'),
            run('go build -o /app/main ./cmd', trigger=[build_context + '/**/*.go'])
        ]
    return []  # No live updates for external services
```

## Testing Live Updates

### Python Service Example

1. **Start your Python service:**
   ```bash
   tilt up -- --services=ai-agentic-test-app
   ```

2. **Make a code change:**
   ```python
   # Edit services/ai-agentic-test-app/main.py
   # Add a new endpoint or modify existing code
   ```

3. **Watch the automatic reload:**
   ```
   1 File Changed: [services/ai-agentic-test-app/main.py]
   Will copy 1 file(s) to container
   WARNING: WatchFiles detected changes in 'main.py'. Reloading...
   INFO: Application startup complete.
   ```

### Node.js Service Example

1. **Start your Node.js service:**
   ```bash
   tilt up -- --services=node-service
   ```

2. **Modify source files in `/src`** - changes sync immediately
3. **Update package.json** - triggers `npm install`

### Java Service Example

1. **Start your Java service:**
   ```bash
   tilt up -- --services=java-service
   ```

2. **Modify Java files in `/src`** - syncs and triggers compilation
3. **Update pom.xml** - triggers `mvn compile`

### Go Service Example

1. **Start your Go service:**
   ```bash
   tilt up -- --services=go-service
   ```

2. **Modify Go files** - triggers rebuild and binary replacement

## Common Issues

### Live Updates Not Working

#### Check Service Type
```bash
# Verify service is type: python
grep -A 5 "service-name:" .tilt/service-config.yaml
```

#### Check Dockerfile
```bash
# Ensure uvicorn uses --reload
grep "reload" services/service-name/Dockerfile
```

#### Check WORKDIR
```bash
# WORKDIR must be /app
grep "WORKDIR" services/service-name/Dockerfile
```

#### Verify Files Are Syncing
```bash
# Check files in container
kubectl exec -it deployment/service-name -n dev-$(whoami) -- ls -la /app/
```

### File Permissions Issues

If files aren't updating due to permissions:
```dockerfile
# Add user permissions in Dockerfile
RUN chmod -R 755 /app
```

### Uvicorn Not Reloading

Ensure uvicorn is properly configured:
```dockerfile
# Correct - uses --reload
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Wrong - missing --reload
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Performance Considerations

### What Gets Synced

- **All files** in the build context are synced
- This includes source code, config files, etc.
- Large files or directories should be added to `.dockerignore`

### Sync Speed

- File sync is nearly instantaneous
- Uvicorn reload takes 1-2 seconds
- Total update time: **< 2 seconds**

### Best Practices

1. **Use .dockerignore**: Exclude unnecessary files
   ```
   __pycache__
   *.pyc
   .git
   .env
   venv/
   .pytest_cache/
   ```

2. **Keep build context small**: Only include necessary files

3. **Monitor logs**: Watch for reload messages to confirm updates

## Supported Service Types

### Full Live Update Support

Live updates are fully supported for:
- ✅ **Python**: File sync + uvicorn auto-reload
- ✅ **Node.js**: Source sync + npm updates + nodemon
- ✅ **Java**: Source sync + Maven compilation + Spring DevTools
- ✅ **Go**: Source sync + binary rebuild

### Limited Live Update Support

- ⚠️ **CrewAI services**: File sync only (Python-based agents, may need manual restart)

### No Live Update Support

Live updates are NOT supported for:
- ❌ **External services**: Pre-built images (databases, redis, etc.)

### Manual Rebuild for Unsupported Types

For services without live updates:
1. Use `tilt trigger service-name` to manually rebuild
2. The rebuild will be fast due to Docker layer caching

## Example: Complete Python Service with Live Updates

### Directory Structure
```
services/my-api/
├── Dockerfile
├── requirements.txt
├── main.py
└── .dockerignore
```

### Dockerfile
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

### main.py
```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World - Live Updates Working!"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### requirements.txt
```
fastapi==0.104.1
uvicorn[standard]==0.24.0
```

### Service Configuration
```yaml
services:
  my-api:
    type: "python"
    build_context: "./services/my-api"
    dockerfile: "./services/my-api/Dockerfile"
    ports: [8000]
    health_check:
      path: "/health"
      port: 8000
```

### Deploy and Test
```bash
# Deploy
tilt up -- --services=my-api 
# Edit main.py - change "Hello World" to "Hello Tilt"
# Save the file
# Check http://localhost:8000 - should show updated message in < 2 seconds
```

## Summary

The Tilt implementation provides comprehensive live update support:

✅ **Python**: Full sync + uvicorn auto-reload (< 2 seconds)
✅ **Node.js**: Source sync + dependency updates + nodemon
✅ **Java**: Source sync + Maven compilation + hot reload
✅ **Go**: Source sync + binary rebuild
⚠️ **CrewAI**: File sync only (Python-based, may need manual restart)
❌ **External**: No live updates (use pre-built images)

Live updates significantly speed up the development cycle by eliminating the need for Docker image rebuilds. Each service type has optimized sync patterns for its specific needs.

For unsupported service types, use manual rebuilds:
```bash
tilt trigger service-name
```