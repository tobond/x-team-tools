"""
Live Update Build Strategy Plugin
Implementation of live update strategy for fast development cycles
"""

def get_strategy_info():
    """Return live update strategy metadata."""
    return {
        "name": "Live Update Strategy",
        "description": "Fast development with live file synchronization and hot reload",
        "priority": 100,  # High priority for development
        "supported_service_types": ["python", "nodejs", "java", "go"]
    }

def can_handle_service(service_type, config):
    """Determine if live update strategy can handle the service."""
    
    # Live updates work best with local builds
    if "ecr_image" in config:
        return False  # ECR images don't support live updates
        
    if "image" in config and not "build_context" in config:
        return False  # External images don't support live updates
    
    # Check if service type supports live updates
    supported_types = get_strategy_info()["supported_service_types"]
    if service_type not in supported_types:
        return False
    
    # Require build context for live updates
    if not config.get("build_context"):
        return False
    
    return True

def create_build_config(service_name, service_type, config):
    """Create build configuration for live update strategy."""
    
    build_context = config.get("build_context", "./{}".format(service_name))
    dockerfile = config.get("dockerfile", "{}/Dockerfile".format(build_context))
    
    return {
        "build_method": "docker_build",
        "build_context": build_context,
        "dockerfile": dockerfile,
        "image_name": service_name,
        "build_args": _get_build_args(service_type, config),
        "live_update_enabled": True
    }

def supports_live_updates():
    """Live update strategy supports live updates."""
    return True

def get_live_update_rules(service_type, build_context):
    """Return live update rules based on service type."""
    
    # Define restart file for triggering container restarts
    RESTART_FILE = '/tmp/.restart'
    
    if service_type == "python":
        return [
            # ALL SYNC STEPS MUST COME FIRST
            # Sync Python files (uvicorn --reload will detect changes automatically)
            sync(build_context, '/app'),
            
            # RESTART CONDITIONS - Python files that require restart
            # Restart on requirements.txt changes (need pip install)
            run('pip install -r /app/requirements.txt', trigger=[
                build_context + '/requirements.txt'
            ]),
            
            # Restart on configuration changes
            run('touch ' + RESTART_FILE, trigger=[
                build_context + '/pyproject.toml',
                build_context + '/setup.py',
                build_context + '/.env'
            ])
        ]
    
    elif service_type == "nodejs":
        return [
            # ALL SYNC STEPS FIRST
            # Sync Node.js source code
            sync(build_context + '/src', '/app/src'),
            sync(build_context + '/lib', '/app/lib'),
            sync(build_context + '/routes', '/app/routes'),
            sync(build_context + '/public', '/app/public'),
            sync(build_context + '/*.js', '/app/'),
            sync(build_context + '/*.ts', '/app/'),
            sync(build_context + '/*.json', '/app/'),
            
            # RESTART CONDITIONS 
            # Restart on package.json changes (need npm install)
            run('npm install', trigger=[
                build_context + '/package.json',
                build_context + '/package-lock.json'
            ]),
            
            # Restart on configuration changes
            run('touch ' + RESTART_FILE, trigger=[
                build_context + '/.env',
                build_context + '/tsconfig.json'
            ])
        ]
    
    elif service_type == "java":
        return [
            # ALL SYNC STEPS FIRST
            # For Java, sync compiled classes and resources
            sync(build_context + '/target/classes', '/app/classes'),
            sync(build_context + '/src/main/resources', '/app/resources'),
            
            # RESTART CONDITIONS
            # Restart on POM or Gradle changes
            run('touch ' + RESTART_FILE, trigger=[
                build_context + '/pom.xml',
                build_context + '/build.gradle',
                build_context + '/src/main/resources/application.properties',
                build_context + '/src/main/resources/application.yml'
            ])
        ]
    
    elif service_type == "go":
        return [
            # ALL SYNC STEPS FIRST  
            # Sync Go source files
            sync(build_context, '/app'),
            
            # RESTART CONDITIONS
            # Go requires rebuild on most changes
            run('go build -o /app/main /app', trigger=[
                build_context + '/*.go',
                build_context + '/cmd/**/*.go',
                build_context + '/pkg/**/*.go'
            ]),
            
            # Restart on module changes
            run('touch ' + RESTART_FILE, trigger=[
                build_context + '/go.mod',
                build_context + '/go.sum'
            ])
        ]
    
    else:
        # Generic live update rules
        return [
            sync(build_context, '/app'),
            run('touch ' + RESTART_FILE, trigger=[build_context + '/*'])
        ]

def _get_build_args(service_type, config):
    """Get build arguments based on service type and configuration."""
    
    build_args = {}
    
    # Add service type as build arg
    build_args["SERVICE_TYPE"] = service_type
    
    # Add version information if available
    if "version" in config:
        build_args["SERVICE_VERSION"] = config["version"]
    
    # Add environment-specific build args
    if service_type == "python":
        build_args["PYTHON_VERSION"] = config.get("python_version", "3.9")
        if "requirements.txt" in str(config):
            build_args["REQUIREMENTS_FILE"] = "requirements.txt"
    
    elif service_type == "nodejs":
        build_args["NODE_VERSION"] = config.get("node_version", "16")
        if "package.json" in str(config):
            build_args["PACKAGE_JSON"] = "package.json"
    
    elif service_type == "java":
        build_args["JAVA_VERSION"] = config.get("java_version", "11")
        if "maven" in str(config):
            build_args["BUILD_TOOL"] = "maven"
        elif "gradle" in str(config):
            build_args["BUILD_TOOL"] = "gradle"
    
    elif service_type == "go":
        build_args["GO_VERSION"] = config.get("go_version", "1.19")
    
    return build_args

# Optional interface functions

def get_build_dependencies(service_type, config):
    """Return build dependencies for live update strategy."""
    
    dependencies = []
    
    # Common dependencies for all service types
    dependencies.extend(["Dockerfile"])
    
    # Service-specific dependencies
    if service_type == "python":
        dependencies.extend(["requirements.txt", "pyproject.toml", "setup.py"])
    elif service_type == "nodejs":
        dependencies.extend(["package.json", "package-lock.json", "tsconfig.json"])
    elif service_type == "java":
        dependencies.extend(["pom.xml", "build.gradle"])
    elif service_type == "go":
        dependencies.extend(["go.mod", "go.sum"])
    
    return dependencies

def customize_build_config(build_config, service_type, config):
    """Customize build configuration for live updates."""
    
    # Add live update specific optimizations
    customized_config = dict(build_config)
    
    # Enable caching for faster rebuilds
    customized_config["enable_cache"] = True
    
    # Add live update specific build args
    if "build_args" not in customized_config:
        customized_config["build_args"] = {}
    
    customized_config["build_args"]["LIVE_UPDATE"] = "true"
    customized_config["build_args"]["DEV_MODE"] = "true"
    
    # Service-specific customizations
    if service_type == "python":
        customized_config["build_args"]["PYTHONUNBUFFERED"] = "1"
    elif service_type == "nodejs":
        customized_config["build_args"]["NODE_ENV"] = "development"
    
    return customized_config

def get_optimization_hints(service_type, config):
    """Provide optimization hints for live updates."""
    
    hints = {
        "cache_hints": [
            "Use multi-stage Dockerfile for better caching",
            "Copy dependency files before source code",
            "Use .dockerignore to exclude unnecessary files"
        ],
        "build_hints": [
            "Keep live update sync paths specific to avoid unnecessary syncs",
            "Use restart triggers only for files that require full restart"
        ],
        "performance_hints": [
            "Live updates work best with local development clusters",
            "Consider using volume mounts for very large codebases"
        ]
    }
    
    # Service-specific hints
    if service_type == "python":
        hints["cache_hints"].append("Copy requirements.txt before source code for better caching")
        hints["performance_hints"].append("Use uvicorn --reload for automatic Python reloading")
    
    elif service_type == "nodejs":
        hints["cache_hints"].append("Copy package.json before source code for better caching")
        hints["performance_hints"].append("Use nodemon for automatic Node.js reloading")
    
    elif service_type == "java":
        hints["build_hints"].append("Use Maven/Gradle daemon for faster builds")
        hints["performance_hints"].append("Consider using Spring Boot DevTools for hot reload")
    
    elif service_type == "go":
        hints["build_hints"].append("Use go build with -race flag in development")
        hints["performance_hints"].append("Consider using air or realize for Go hot reload")
    
    return hints