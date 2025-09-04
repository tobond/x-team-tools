# Live Update System Guide

This guide explains how to use the enhanced live update system in the Tilt-based development environment.

## Overview

The live update system provides near-instant deployment of code changes to your local Kubernetes environment without requiring full Docker image rebuilds. It supports multiple programming languages and includes advanced optimizations for performance.

## Features

### 🚀 Language-Specific Optimizations

- **Python**: Sync source code, handle pip/pipenv dependencies, configuration files
- **Java**: Hot reload compiled classes, Maven/Gradle integration, Spring Boot DevTools support
- **Go**: Fast binary rebuilds, Go modules support, embedded assets
- **Node.js**: TypeScript compilation, npm/yarn/pnpm support, static files

### 🎯 Advanced File Watching

- **Optimized Ignore Patterns**: Automatically excludes build artifacts, logs, and temporary files
- **Smart Sync Rules**: Language-specific sync patterns for maximum efficiency
- **Fallback Rules**: Complex changes (like Dockerfile modifications) trigger full rebuilds
- **Watch File Integration**: Critical configuration files are monitored for immediate rebuilds

### 📊 Performance Monitoring

- **Live Reload Monitor**: Track file watching performance and recent changes
- **Build Performance Monitor**: Docker system usage and cleanup recommendations
- **Validation Testing**: Automated tests to verify live update configuration

## Configuration

### Service Configuration

Each service in `.tilt/service-config.yaml` supports live updates when built locally:

```yaml
services:
  my-python-service:
    type: "python"
    build_context: "./my-python-service"
    dockerfile: "./my-python-service/Dockerfile"
    # ... other configuration
```

### Enabling Live Updates

Use the `--build_local` flag to enable live updates for specific services:

```bash
# Enable live updates for specific services
tilt up -- --services=my-service --build_local=my-service

# Multiple services with live updates
tilt up -- --services=service1,service2 --build_local=service1,service2
```

## Language-Specific Setup

### Python Services

**Recommended Structure:**
```
my-python-service/
├── Dockerfile
├── requirements.txt          # Watched for dependency changes
├── pyproject.toml           # Alternative dependency file
├── src/                     # Source code (synced)
│   ├── __init__.py
│   └── main.py
├── config/                  # Configuration files (synced)
│   └── settings.yaml
└── .dockerignore           # Optimizes build context
```

**Live Update Features:**
- Source code changes sync instantly
- Dependency changes trigger `pip install`
- Configuration files sync without restart
- Ignores `__pycache__`, `.pytest_cache`, etc.

**Fallback Triggers (Full Rebuild):**
- `Dockerfile` changes
- `requirements.txt` modifications
- `pyproject.toml` updates
- `setup.py` changes

### Java Services

**Recommended Structure:**
```
my-java-service/
├── Dockerfile
├── pom.xml                  # Maven configuration (watched)
├── src/
│   ├── main/
│   │   ├── java/           # Source code
│   │   └── resources/      # Resources (synced)
│   └── test/
└── target/
    └── classes/            # Compiled classes (synced)
```

**Live Update Features:**
- Compiled classes sync for hot reload
- Resources and configuration sync
- Spring Boot DevTools integration
- Maven/Gradle build integration

**Fallback Triggers (Full Rebuild):**
- `pom.xml` or `build.gradle` changes
- `Dockerfile` modifications
- Major structural changes

### Go Services

**Recommended Structure:**
```
my-go-service/
├── Dockerfile
├── go.mod                   # Go modules (watched)
├── go.sum                   # Module checksums (watched)
├── cmd/                     # Main packages (synced)
│   └── main.go
├── pkg/                     # Library code (synced)
├── internal/                # Internal packages (synced)
└── config/                  # Configuration (synced)
```

**Live Update Features:**
- Fast binary rebuilds on source changes
- Go modules dependency management
- Configuration and asset syncing
- Optimized for Go project structure

**Fallback Triggers (Full Rebuild):**
- `go.mod` or `go.sum` changes
- `Dockerfile` modifications
- `Makefile` updates

### Node.js Services

**Recommended Structure:**
```
my-nodejs-service/
├── Dockerfile
├── package.json             # Dependencies (watched)
├── package-lock.json        # Lock file (watched)
├── tsconfig.json           # TypeScript config (watched)
├── src/                    # Source code (synced)
│   ├── index.ts
│   └── routes/
├── public/                 # Static files (synced)
└── config/                 # Configuration (synced)
```

**Live Update Features:**
- Source code syncing (JS/TS)
- Automatic TypeScript compilation
- npm/yarn/pnpm dependency management
- Static files and views syncing

**Fallback Triggers (Full Rebuild):**
- `package.json` changes
- Build configuration updates
- `Dockerfile` modifications

## Performance Optimization

### File Watching Optimization

The system automatically ignores common directories and files that don't affect runtime:

```
# Automatically ignored patterns
**/.git/**
**/node_modules/**
**/__pycache__/**
**/target/**
**/build/**
**/dist/**
**/*.log
**/logs/**
**/tmp/**
**/temp/**
```

### Docker Build Context Optimization

Each service type gets optimized `.dockerignore` patterns:

- **Python**: Excludes `__pycache__`, `.pytest_cache`, `venv`, etc.
- **Java**: Excludes `target/`, `.gradle/`, `*.class`, etc.
- **Go**: Excludes `*.exe`, `*.test`, `vendor/`, etc.
- **Node.js**: Excludes `node_modules/`, `coverage/`, `dist/`, etc.

### Custom Ignore Patterns

You can customize ignore patterns by modifying the sync rules in your service configuration or by adding a `.dockerignore` file to your service directory.

## Monitoring and Debugging

### Tilt UI Resources

The system creates several monitoring resources in the Tilt UI:

1. **live-reload-monitor**: Shows file watching performance and recent changes
2. **build-monitor**: Docker system usage and cleanup recommendations
3. **live-update-summary**: Configuration summary for all services
4. **live-update-test**: Validation tests for live update configuration

### Manual Testing

1. **Make a small change** to a source file
2. **Check Tilt UI** for automatic rebuild trigger
3. **Verify the change** is reflected in the running container
4. **Test dependency changes** trigger appropriate rebuilds

### Troubleshooting

#### Slow Live Updates
- Check ignore patterns are properly configured
- Verify `.dockerignore` exists and is optimized
- Monitor file watching statistics in `live-reload-monitor`

#### Changes Don't Trigger Rebuilds
- Verify file paths match sync patterns
- Check if files are being ignored unintentionally
- Ensure build context is correct

#### Too Many Full Rebuilds
- Review fallback rules configuration
- Check if critical files are changing unexpectedly
- Verify ignore patterns exclude temporary files

#### Debug Mode
Enable debug mode for detailed logging:

```bash
tilt up -- --enable_debug=true --services=my-service --build_local=my-service
```

## Best Practices

### 1. Organize Code Structure
- Use standard directory structures for your language
- Keep source code in dedicated directories (`src/`, `lib/`, etc.)
- Separate configuration from code

### 2. Optimize Dependencies
- Pin dependency versions for consistent builds
- Use lock files (`package-lock.json`, `go.sum`, etc.)
- Minimize dependency changes during development

### 3. Configure Ignore Patterns
- Add `.dockerignore` to each service
- Exclude build artifacts and temporary files
- Use language-specific ignore patterns

### 4. Test Live Updates
- Run the `live-update-test` resource regularly
- Test both source code and configuration changes
- Verify fallback rules work for major changes

### 5. Monitor Performance
- Check `live-reload-monitor` for file watching stats
- Use `build-monitor` for Docker system health
- Clean up unused images and volumes regularly

## Advanced Configuration

### Custom Live Update Rules

You can customize live update rules by modifying the `get_live_updates_for_type` function in `.tilt/lib/builds.star`:

```python
# Example: Custom sync rule for a specific directory
sync(build_context + '/custom-dir', '/app/custom-dir', 
     ignore=['**/*.log', '**/tmp/**'])

# Example: Custom run command on file changes
run('npm run custom-build', 
    trigger=[build_context + '/custom-config.json'])
```

### Custom Fallback Rules

Add custom fallback rules for your specific use case:

```python
# Example: Additional fallback triggers
fallback_rules.extend([
    build_context + '/custom-config.yaml',
    build_context + '/schema.sql'
])
```

## Integration with Development Workflow

### IDE Integration
- Use port-forwarding for debugging
- Configure IDE to work with containerized services
- Set up remote debugging when needed

### Testing Integration
- Live updates work with test files
- Use test-specific ignore patterns
- Configure test runners for containerized environment

### CI/CD Integration
- Live updates are development-only
- Production builds use standard Docker builds
- Ensure `.dockerignore` works for both scenarios

## Conclusion

The live update system provides a powerful development experience with near-instant feedback loops. By following the best practices and using the monitoring tools, you can achieve optimal performance for your development workflow.

For more information, check the Tilt UI monitoring resources and run the validation tests regularly to ensure your configuration is optimized.