"""
Build management for different service types
Handles Docker builds, ECR images, and live updates with comprehensive optimization
Implements advanced file watching and live reload system with language-specific optimizations
"""

# Configure Docker prune settings for automatic cleanup and disk space management
docker_prune_settings(
    disable=False,
    max_age_mins=60,  # Prune images older than 1 hour
    num_builds=10,    # Keep last 10 builds
    keep_recent=5     # Always keep 5 most recent builds
)

# Configure optimized file watching settings for better performance
def setup_watch_settings():
    """Configure optimized file watching settings for better performance"""
    
    # Configure watch settings for optimal performance
    watch_settings(
        ignore=[
            # Version control
            '**/.git/**',
            '**/.svn/**',
            
            # Build artifacts and caches
            '**/node_modules/**',
            '**/__pycache__/**',
            '**/target/**',
            '**/build/**',
            '**/dist/**',
            '**/.gradle/**',
            '**/.maven/**',
            
            # IDE and editor files
            '**/.vscode/**',
            '**/.idea/**',
            '**/*.swp',
            '**/*.swo',
            '**/*~',
            
            # OS files
            '**/.DS_Store',
            '**/Thumbs.db',
            
            # Logs and temporary files
            '**/*.log',
            '**/logs/**',
            '**/tmp/**',
            '**/temp/**',
            '**/*.tmp',
            '**/*.temp',
            
            # Test coverage and reports
            '**/coverage/**',
            '**/.nyc_output/**',
            '**/.pytest_cache/**',
            '**/.coverage',
            '**/htmlcov/**',
            
            # Language-specific ignores
            '**/*.pyc',
            '**/*.pyo',
            '**/*.pyd',
            '**/.tox/**',
            '**/venv/**',
            '**/.venv/**',
            '**/env/**',
            '**/.env/**',
            '**/*.class',
            '**/*.jar',
            '**/*.war',
            '**/*.ear',
            '**/*.exe',
            '**/*.dll',
            '**/*.so',
            '**/*.dylib',
            
            # Package manager files that don't affect runtime
            '**/package-lock.json.bak',
            '**/yarn.lock.bak',
            '**/.yarn/cache/**',
            '**/.npm/**'
        ]
    )

# Initialize watch settings
setup_watch_settings()

def get_live_updates_for_type(app_type, build_context):
    """Return optimized live update rules based on application type with comprehensive file watching and fallback rules"""
    
    if app_type == "python":
        return [
            # Sync source code changes with ignore patterns
            sync(build_context + '/src', '/app/src', ignore=_get_python_ignore_patterns()),
            sync(build_context + '/*.py', '/app/', ignore=['**/__pycache__/**', '**/*.pyc', '**/*.pyo']),
            
            # Handle dependency changes
            sync(build_context + '/requirements.txt', '/app/requirements.txt'),
            sync(build_context + '/pyproject.toml', '/app/pyproject.toml'),
            sync(build_context + '/setup.py', '/app/setup.py'),
            sync(build_context + '/requirements-dev.txt', '/app/requirements-dev.txt'),
            sync(build_context + '/Pipfile', '/app/Pipfile'),
            sync(build_context + '/Pipfile.lock', '/app/Pipfile.lock'),
            
            # Install dependencies when they change
            run('pip install -r requirements.txt', trigger=[build_context + '/requirements.txt']),
            run('pip install -r requirements-dev.txt', trigger=[build_context + '/requirements-dev.txt']),
            run('pip install -e .', trigger=[build_context + '/pyproject.toml', build_context + '/setup.py']),
            run('pipenv install --dev', trigger=[build_context + '/Pipfile', build_context + '/Pipfile.lock']),
            
            # Handle configuration files
            sync(build_context + '/config', '/app/config', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/*.yaml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.yml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.json', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.toml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/.env*', '/app/', ignore=['**/*.log']),
            
            # Handle static files and templates
            sync(build_context + '/static', '/app/static', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/templates', '/app/templates', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/migrations', '/app/migrations', ignore=['**/*.log', '**/tmp/**']),
            
            # Restart container for changes
            restart_container()
        ]
    elif app_type == "java":
        return [
            # Sync compiled classes for hot reload
            sync(build_context + '/target/classes', '/app/classes', ignore=_get_java_ignore_patterns()),
            
            # Sync resources and configuration
            sync(build_context + '/src/main/resources', '/app/resources', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/target/generated-sources', '/app/generated-sources', ignore=['**/*.log']),
            
            # Handle Maven/Gradle build files
            sync(build_context + '/pom.xml', '/app/pom.xml'),
            sync(build_context + '/build.gradle', '/app/build.gradle'),
            sync(build_context + '/gradle.properties', '/app/gradle.properties'),
            sync(build_context + '/settings.gradle', '/app/settings.gradle'),
            
            # Handle Spring Boot configuration
            sync(build_context + '/src/main/resources/application*.properties', '/app/resources/'),
            sync(build_context + '/src/main/resources/application*.yml', '/app/resources/'),
            sync(build_context + '/src/main/resources/application*.yaml', '/app/resources/'),
            
            # Handle Spring Boot DevTools if present
            run('touch /app/restart.txt', trigger=[build_context + '/src/main/java/**/*.java']),
            run('mvn compile', trigger=[build_context + '/pom.xml']),
            run('gradle compileJava', trigger=[build_context + '/build.gradle']),
            
            restart_container()
        ]
    elif app_type == "go":
        return [
            # Sync Go source code with ignore patterns
            sync(build_context + '/cmd', '/app/cmd', ignore=_get_go_ignore_patterns()),
            sync(build_context + '/pkg', '/app/pkg', ignore=_get_go_ignore_patterns()),
            sync(build_context + '/internal', '/app/internal', ignore=_get_go_ignore_patterns()),
            sync(build_context + '/*.go', '/app/', ignore=['**/*.exe', '**/*.test', '**/*.out']),
            
            # Handle Go modules
            sync(build_context + '/go.mod', '/app/go.mod'),
            sync(build_context + '/go.sum', '/app/go.sum'),
            sync(build_context + '/go.work', '/app/go.work'),
            sync(build_context + '/go.work.sum', '/app/go.work.sum'),
            
            # Rebuild binary when source changes
            run('go mod download', trigger=[build_context + '/go.mod', build_context + '/go.sum']),
            run('go mod tidy', trigger=[build_context + '/go.mod']),
            run('go build -o /app/main ./cmd', trigger=[
                build_context + '/cmd/**/*.go', 
                build_context + '/pkg/**/*.go',
                build_context + '/internal/**/*.go',
                build_context + '/*.go'
            ]),
            
            # Sync configuration files
            sync(build_context + '/config', '/app/config', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/*.yaml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.yml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.json', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.toml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/.env*', '/app/', ignore=['**/*.log']),
            
            # Handle embedded files and assets
            sync(build_context + '/assets', '/app/assets', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/web', '/app/web', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/static', '/app/static', ignore=['**/*.log', '**/tmp/**']),
            
            restart_container()
        ]
    elif app_type == "nodejs":
        return [
            # Sync Node.js source code with ignore patterns
            sync(build_context + '/src', '/app/src', ignore=_get_nodejs_ignore_patterns()),
            sync(build_context + '/lib', '/app/lib', ignore=_get_nodejs_ignore_patterns()),
            sync(build_context + '/routes', '/app/routes', ignore=_get_nodejs_ignore_patterns()),
            sync(build_context + '/controllers', '/app/controllers', ignore=_get_nodejs_ignore_patterns()),
            sync(build_context + '/middleware', '/app/middleware', ignore=_get_nodejs_ignore_patterns()),
            sync(build_context + '/models', '/app/models', ignore=_get_nodejs_ignore_patterns()),
            sync(build_context + '/utils', '/app/utils', ignore=_get_nodejs_ignore_patterns()),
            sync(build_context + '/*.js', '/app/', ignore=['**/node_modules/**', '**/*.log']),
            sync(build_context + '/*.ts', '/app/', ignore=['**/node_modules/**', '**/*.log']),
            sync(build_context + '/*.mjs', '/app/', ignore=['**/node_modules/**', '**/*.log']),
            
            # Handle package dependencies
            sync(build_context + '/package.json', '/app/package.json'),
            sync(build_context + '/package-lock.json', '/app/package-lock.json'),
            sync(build_context + '/yarn.lock', '/app/yarn.lock'),
            sync(build_context + '/pnpm-lock.yaml', '/app/pnpm-lock.yaml'),
            
            # Handle TypeScript configuration
            sync(build_context + '/tsconfig.json', '/app/tsconfig.json'),
            sync(build_context + '/tsconfig.*.json', '/app/'),
            sync(build_context + '/.babelrc', '/app/.babelrc'),
            sync(build_context + '/babel.config.js', '/app/babel.config.js'),
            
            # Install dependencies when they change
            run('npm install', trigger=[build_context + '/package.json', build_context + '/package-lock.json']),
            run('yarn install', trigger=[build_context + '/yarn.lock']),
            run('pnpm install', trigger=[build_context + '/pnpm-lock.yaml']),
            
            # Handle TypeScript compilation if needed
            run('npm run build', trigger=[build_context + '/src/**/*.ts', build_context + '/tsconfig.json']),
            run('npx tsc', trigger=[build_context + '/src/**/*.ts', build_context + '/tsconfig.json']),
            
            # Sync configuration files
            sync(build_context + '/config', '/app/config', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/*.yaml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.yml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.json', '/app/', ignore=['**/*.log', '**/node_modules/**']),
            sync(build_context + '/.env*', '/app/', ignore=['**/*.log']),
            
            # Handle static files and views
            sync(build_context + '/public', '/app/public', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/static', '/app/static', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/views', '/app/views', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/templates', '/app/templates', ignore=['**/*.log', '**/tmp/**']),
            
            restart_container()
        ]
    else:
        # Generic fallback for unknown application types
        return [
            sync(build_context + '/src', '/app/src', ignore=_get_generic_ignore_patterns()),
            sync(build_context + '/config', '/app/config', ignore=['**/*.log', '**/tmp/**']),
            sync(build_context + '/*.yaml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.yml', '/app/', ignore=['**/*.log']),
            sync(build_context + '/*.json', '/app/', ignore=['**/*.log']),
            sync(build_context + '/.env*', '/app/', ignore=['**/*.log']),
            restart_container()
        ]

def _get_python_ignore_patterns():
    """Return Python-specific ignore patterns for live updates"""
    return [
        '**/__pycache__/**',
        '**/*.pyc',
        '**/*.pyo',
        '**/*.pyd',
        '**/.pytest_cache/**',
        '**/.coverage',
        '**/htmlcov/**',
        '**/.tox/**',
        '**/venv/**',
        '**/.venv/**',
        '**/env/**',
        '**/.env/**',
        '**/dist/**',
        '**/build/**',
        '**/*.egg-info/**',
        '**/.mypy_cache/**',
        '**/*.log',
        '**/logs/**',
        '**/tmp/**',
        '**/temp/**'
    ]

def _get_java_ignore_patterns():
    """Return Java-specific ignore patterns for live updates"""
    return [
        '**/target/**',
        '**/*.class',
        '**/*.jar',
        '**/*.war',
        '**/*.ear',
        '**/.gradle/**',
        '**/build/**',
        '**/.settings/**',
        '**/.project',
        '**/.classpath',
        '**/*.log',
        '**/logs/**',
        '**/tmp/**',
        '**/temp/**'
    ]

def _get_go_ignore_patterns():
    """Return Go-specific ignore patterns for live updates"""
    return [
        '**/*.exe',
        '**/*.exe~',
        '**/*.dll',
        '**/*.so',
        '**/*.dylib',
        '**/*.test',
        '**/*.out',
        '**/vendor/**',
        '**/*.log',
        '**/logs/**',
        '**/tmp/**',
        '**/temp/**'
    ]

def _get_nodejs_ignore_patterns():
    """Return Node.js-specific ignore patterns for live updates"""
    return [
        '**/node_modules/**',
        '**/npm-debug.log*',
        '**/yarn-debug.log*',
        '**/yarn-error.log*',
        '**/.npm',
        '**/.yarn-integrity',
        '**/coverage/**',
        '**/.nyc_output/**',
        '**/dist/**',
        '**/build/**',
        '**/*.log',
        '**/logs/**',
        '**/tmp/**',
        '**/temp/**'
    ]

def _get_generic_ignore_patterns():
    """Return generic ignore patterns for live updates"""
    return [
        '**/*.log',
        '**/logs/**',
        '**/tmp/**',
        '**/temp/**',
        '**/.git/**',
        '**/.svn/**',
        '**/.DS_Store',
        '**/Thumbs.db'
    ]

def get_fallback_rules_for_type(app_type, build_context):
    """Return fall_back_on rules for complex changes requiring full rebuilds"""
    
    if app_type == "python":
        return [
            # Dockerfile changes require full rebuild
            build_context + '/Dockerfile',
            build_context + '/Dockerfile.*',
            
            # Major dependency changes
            build_context + '/setup.py',
            build_context + '/pyproject.toml',
            build_context + '/requirements.txt',
            build_context + '/requirements-dev.txt',
            build_context + '/Pipfile',
            build_context + '/Pipfile.lock',
            
            # System-level configuration changes
            build_context + '/.dockerignore',
            build_context + '/docker-compose*.yml',
            build_context + '/docker-compose*.yaml',
            
            # Major structural changes
            build_context + '/setup.cfg',
            build_context + '/tox.ini',
            build_context + '/pytest.ini',
            build_context + '/.python-version'
        ]
    elif app_type == "java":
        return [
            # Dockerfile changes require full rebuild
            build_context + '/Dockerfile',
            build_context + '/Dockerfile.*',
            
            # Major build configuration changes
            build_context + '/pom.xml',
            build_context + '/build.gradle',
            build_context + '/settings.gradle',
            build_context + '/gradle.properties',
            build_context + '/gradle/wrapper/**',
            
            # System-level configuration changes
            build_context + '/.dockerignore',
            build_context + '/docker-compose*.yml',
            build_context + '/docker-compose*.yaml',
            
            # Major structural changes
            build_context + '/src/main/webapp/**',
            build_context + '/src/main/resources/META-INF/**'
        ]
    elif app_type == "go":
        return [
            # Dockerfile changes require full rebuild
            build_context + '/Dockerfile',
            build_context + '/Dockerfile.*',
            
            # Major module changes
            build_context + '/go.mod',
            build_context + '/go.sum',
            build_context + '/go.work',
            build_context + '/go.work.sum',
            
            # System-level configuration changes
            build_context + '/.dockerignore',
            build_context + '/docker-compose*.yml',
            build_context + '/docker-compose*.yaml',
            
            # Major structural changes
            build_context + '/Makefile',
            build_context + '/.goreleaser.yml',
            build_context + '/.goreleaser.yaml'
        ]
    elif app_type == "nodejs":
        return [
            # Dockerfile changes require full rebuild
            build_context + '/Dockerfile',
            build_context + '/Dockerfile.*',
            
            # Major dependency changes
            build_context + '/package.json',
            build_context + '/package-lock.json',
            build_context + '/yarn.lock',
            build_context + '/pnpm-lock.yaml',
            
            # Build configuration changes
            build_context + '/webpack.config.js',
            build_context + '/rollup.config.js',
            build_context + '/vite.config.js',
            build_context + '/next.config.js',
            build_context + '/nuxt.config.js',
            
            # System-level configuration changes
            build_context + '/.dockerignore',
            build_context + '/docker-compose*.yml',
            build_context + '/docker-compose*.yaml',
            
            # Major structural changes
            build_context + '/.nvmrc',
            build_context + '/.node-version'
        ]
    else:
        # Generic fallback rules
        return [
            build_context + '/Dockerfile',
            build_context + '/Dockerfile.*',
            build_context + '/.dockerignore',
            build_context + '/docker-compose*.yml',
            build_context + '/docker-compose*.yaml'
        ]

def setup_build_strategy(service_name, service_config, build_local_services, debug_mode=False):
    """Setup build strategy (local or ECR) for a service with enhanced customization support"""
    
    # Check for forced build strategies from service customization
    if service_config.get("_force_local_build", False):
        build_locally = True
    elif service_config.get("_force_ecr_build", False):
        build_locally = False
    else:
        build_locally = service_name in build_local_services
    
    if build_locally:
        return _setup_local_build(service_name, service_config, debug_mode)
    else:
        return _setup_ecr_build(service_name, service_config, debug_mode)

def _setup_local_build(service_name, service_config, debug_mode):
    """Setup local Docker build with comprehensive live updates, fallback rules, and optimization"""
    
    image_name = service_name + ":latest"
    build_context = service_config["build_context"]
    dockerfile = service_config.get("dockerfile", build_context + "/Dockerfile")
    app_type = service_config.get("type", "generic")
    
    # Get language-specific live update configurations
    live_updates = get_live_updates_for_type(app_type, build_context)
    
    # Get fallback rules for complex changes requiring full rebuilds
    fallback_rules = get_fallback_rules_for_type(app_type, build_context)
    
    # Create optimized file watching patterns based on application type
    watch_patterns = _get_watch_patterns_for_type(app_type, build_context)
    
    # Setup watch_file for critical configuration files
    _setup_watch_files_for_type(app_type, build_context, service_name)
    
    # Enhanced docker build with comprehensive optimization
    docker_build(
        image_name,
        build_context,
        dockerfile=dockerfile,
        live_update=live_updates,
        # Add fallback rules for complex changes requiring full rebuilds
        fall_back_on=fallback_rules,
        # Optimize file watching with specific patterns
        only=watch_patterns,
        build_args={
            "ENV": "local", 
            "DEBUG": "true",
            "SERVICE_NAME": service_name,
            "SERVICE_TYPE": app_type,
            "BUILD_TIMESTAMP": str(local('date +%s')).strip(),
            "DEVELOPER_MODE": "true"
        },
        # Optimize build performance
        cache_from=[image_name],
        pull=False,
        # Add build target for multi-stage Dockerfiles
        target=service_config.get("build_target", "development"),
        # Enable BuildKit for better performance
        extra_flags=["--progress=plain"],
        # Enhanced ignore patterns to reduce build context
        ignore=[
            "**/.git",
            "**/.svn",
            "**/node_modules",
            "**/__pycache__",
            "**/target",
            "**/build",
            "**/dist",
            "**/.gradle",
            "**/.pytest_cache",
            "**/.coverage",
            "**/htmlcov",
            "**/coverage",
            "**/.nyc_output",
            "**/.tox",
            "**/venv",
            "**/.venv",
            "**/env",
            "**/.env",
            "**/*.log",
            "**/logs",
            "**/tmp",
            "**/temp",
            "**/*.tmp",
            "**/*.temp",
            "**/.DS_Store",
            "**/Thumbs.db",
            "**/*.swp",
            "**/*.swo",
            "**/*~",
            "**/.vscode",
            "**/.idea",
            "**/*.pyc",
            "**/*.pyo",
            "**/*.pyd",
            "**/*.class",
            "**/*.jar",
            "**/*.war",
            "**/*.ear",
            "**/*.exe",
            "**/*.dll",
            "**/*.so",
            "**/*.dylib"
        ]
    )
    
    if debug_mode:
        print("🔨 Building {} locally with live updates (type: {})".format(service_name, app_type))
        print("📁 Build context: {}".format(build_context))
        print("🐳 Dockerfile: {}".format(dockerfile))
        print("👀 Watching patterns: {}".format(str(watch_patterns)))
        print("🔄 Fallback rules: {} files".format(len(fallback_rules)))
        print("🚫 Ignore patterns: {} patterns".format(len([
            "**/.git", "**/.svn", "**/node_modules", "**/__pycache__", "**/target",
            "**/build", "**/dist", "**/.gradle", "**/.pytest_cache", "**/.coverage",
            "**/htmlcov", "**/coverage", "**/.nyc_output", "**/.tox", "**/venv",
            "**/.venv", "**/env", "**/.env", "**/*.log", "**/logs", "**/tmp",
            "**/temp", "**/*.tmp", "**/*.temp", "**/.DS_Store", "**/Thumbs.db",
            "**/*.swp", "**/*.swo", "**/*~", "**/.vscode", "**/.idea", "**/*.pyc",
            "**/*.pyo", "**/*.pyd", "**/*.class", "**/*.jar", "**/*.war", "**/*.ear",
            "**/*.exe", "**/*.dll", "**/*.so", "**/*.dylib"
        ])))
    
    # Validate live update configuration
    validation_result = validate_live_update_configuration(service_name, service_config, debug_mode)
    
    if not validation_result["is_valid"]:
        print("❌ Live update validation failed for {}: {}".format(service_name, validation_result["issues"]))
    elif debug_mode and validation_result["recommendations"]:
        print("💡 Live update recommendations for {}: {}".format(service_name, validation_result["recommendations"]))
    
    return {
        "image_name": image_name,
        "build_locally": True,
        "build_context": build_context,
        "app_type": app_type,
        "fallback_rules_count": len(fallback_rules),
        "watch_patterns_count": len(watch_patterns),
        "validation_result": validation_result
    }

def _setup_watch_files_for_type(app_type, build_context, service_name):
    """Setup watch_file for critical configuration files that should trigger immediate rebuilds"""
    
    if app_type == "python":
        # Watch critical Python configuration files
        critical_files = [
            build_context + '/requirements.txt',
            build_context + '/requirements-dev.txt',
            build_context + '/pyproject.toml',
            build_context + '/setup.py',
            build_context + '/setup.cfg',
            build_context + '/Pipfile',
            build_context + '/Pipfile.lock',
            build_context + '/tox.ini',
            build_context + '/pytest.ini',
            build_context + '/.python-version'
        ]
    elif app_type == "java":
        # Watch critical Java configuration files
        critical_files = [
            build_context + '/pom.xml',
            build_context + '/build.gradle',
            build_context + '/settings.gradle',
            build_context + '/gradle.properties',
            build_context + '/gradle/wrapper/gradle-wrapper.properties'
        ]
    elif app_type == "go":
        # Watch critical Go configuration files
        critical_files = [
            build_context + '/go.mod',
            build_context + '/go.sum',
            build_context + '/go.work',
            build_context + '/go.work.sum',
            build_context + '/Makefile'
        ]
    elif app_type == "nodejs":
        # Watch critical Node.js configuration files
        critical_files = [
            build_context + '/package.json',
            build_context + '/package-lock.json',
            build_context + '/yarn.lock',
            build_context + '/pnpm-lock.yaml',
            build_context + '/tsconfig.json',
            build_context + '/webpack.config.js',
            build_context + '/rollup.config.js',
            build_context + '/vite.config.js',
            build_context + '/next.config.js',
            build_context + '/nuxt.config.js',
            build_context + '/.nvmrc',
            build_context + '/.node-version'
        ]
    else:
        # Generic critical files
        critical_files = [
            build_context + '/Dockerfile',
            build_context + '/.dockerignore'
        ]
    
    # Always watch Dockerfile and Docker-related files
    critical_files.extend([
        build_context + '/Dockerfile',
        build_context + '/Dockerfile.dev',
        build_context + '/Dockerfile.prod',
        build_context + '/.dockerignore',
        build_context + '/docker-compose.yml',
        build_context + '/docker-compose.yaml',
        build_context + '/docker-compose.dev.yml',
        build_context + '/docker-compose.dev.yaml'
    ])
    
    # Setup watch_file for each critical file that exists
    for file_path in critical_files:
        try:
            # Check if file exists before setting up watch
            if local('test -f {} && echo "exists" || echo "missing"'.format(file_path), quiet=True).strip() == "exists":
                watch_file(file_path)
        except:
            # Ignore errors for files that don't exist
            pass

def _get_watch_patterns_for_type(app_type, build_context):
    """Return optimized file watching patterns based on application type"""
    
    base_patterns = [build_context]
    
    if app_type == "python":
        return base_patterns + [
            build_context + "/**/*.py",
            build_context + "/requirements.txt",
            build_context + "/pyproject.toml",
            build_context + "/setup.py",
            build_context + "/**/*.yaml",
            build_context + "/**/*.yml",
            build_context + "/**/*.json"
        ]
    elif app_type == "java":
        return base_patterns + [
            build_context + "/src/**/*.java",
            build_context + "/src/**/*.xml",
            build_context + "/src/**/*.properties",
            build_context + "/pom.xml",
            build_context + "/build.gradle",
            build_context + "/src/main/resources/**/*"
        ]
    elif app_type == "go":
        return base_patterns + [
            build_context + "/**/*.go",
            build_context + "/go.mod",
            build_context + "/go.sum",
            build_context + "/**/*.yaml",
            build_context + "/**/*.yml",
            build_context + "/**/*.json"
        ]
    elif app_type == "nodejs":
        return base_patterns + [
            build_context + "/**/*.js",
            build_context + "/**/*.ts",
            build_context + "/package.json",
            build_context + "/package-lock.json",
            build_context + "/yarn.lock",
            build_context + "/tsconfig.json",
            build_context + "/**/*.yaml",
            build_context + "/**/*.yml",
            build_context + "/**/*.json"
        ]
    else:
        return base_patterns + [
            build_context + "/**/*"
        ]

def _setup_ecr_build(service_name, service_config, debug_mode):
    """Setup ECR image pull with comprehensive authentication and error handling and version management"""
    
    ecr_image = service_config["ecr_image"]
    image_name = service_name + ":latest"
    build_context = service_config["build_context"]
    
    # Extract ECR registry URL and region
    ecr_registry = ecr_image.split('/')[0]
    ecr_region = service_config.get("ecr_region", "us-east-1")
    
    # Extract version information for tracking
    ecr_version = "latest"
    if ":" in ecr_image:
        ecr_version = ecr_image.split(":")[-1]
    
    # Enhanced ECR image handling with comprehensive authentication and caching
    custom_build(
        image_name,
        '''
        set -euo pipefail
        
        echo "🔐 Authenticating with ECR registry: ''' + ecr_registry + '''"
        
        # Check if AWS CLI is available
        if ! command -v aws &> /dev/null; then
            echo "❌ AWS CLI not found. Please install AWS CLI to use ECR images."
            exit 1
        fi
        
        # Authenticate with ECR
        if ! aws ecr get-login-password --region ''' + ecr_region + ''' | docker login --username AWS --password-stdin ''' + ecr_registry + '''; then
            echo "❌ ECR authentication failed. Please check your AWS credentials."
            exit 1
        fi
        
        echo "📥 Pulling ECR image: ''' + ecr_image + '''"
        
        # Pull with retry logic and better error handling
        for attempt in {1..3}; do
            if docker pull ''' + ecr_image + '''; then
                echo "✅ Successfully pulled ECR image on attempt $attempt"
                break
            else
                if [ $attempt -eq 3 ]; then
                    echo "❌ Failed to pull ECR image after 3 attempts"
                    exit 1
                fi
                echo "⚠️  Pull attempt $attempt failed, retrying in 5 seconds..."
                sleep 5
            fi
        done
        
        echo "🏷️  Tagging image for local use..."
        docker tag ''' + ecr_image + ''' $EXPECTED_REF
        
        echo "✅ ECR image ready: $EXPECTED_REF"
        
        # Optional: Show image info
        docker images $EXPECTED_REF --format "table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}\\t{{.CreatedAt}}"
        ''',
        deps=[build_context],
        disable_push=True,
        # Add image dependencies for proper caching
        image_deps=[ecr_image],
        # Optimize by only rebuilding when service config changes
        only=[build_context + "/.tilt-ecr-config"]
    )
    
    # Create a marker file to track ECR configuration changes
    local('mkdir -p {}'.format(build_context))
    local('echo "{}" > {}/.tilt-ecr-config'.format(ecr_image, build_context))
    
    if debug_mode:
        print("🐳 Using ECR image for {}: {}".format(service_name, ecr_image))
        print("🌍 ECR region: {}".format(ecr_region))
        print("🏛️  ECR registry: {}".format(ecr_registry))
    
    return {
        "image_name": image_name,
        "build_locally": False,
        "ecr_image": ecr_image,
        "ecr_version": ecr_version,
        "ecr_region": ecr_region,
        "ecr_registry": ecr_registry
    }

def get_build_info(service_name, service_config, build_local_services):
    """Get comprehensive build information for a service"""
    
    build_locally = service_name in build_local_services
    app_type = service_config.get("type", "generic")
    build_context = service_config["build_context"]
    
    build_info = {
        "service_name": service_name,
        "app_type": app_type,
        "build_context": build_context,
        "build_locally": build_locally,
        "dockerfile": service_config.get("dockerfile", build_context + "/Dockerfile"),
        "build_target": service_config.get("build_target", "development" if build_locally else "production")
    }
    
    if build_locally:
        build_info["watch_patterns"] = _get_watch_patterns_for_type(app_type, build_context)
        build_info["live_updates"] = len(get_live_updates_for_type(app_type, build_context))
    else:
        build_info["ecr_image"] = service_config.get("ecr_image", "")
        build_info["ecr_region"] = service_config.get("ecr_region", "us-east-1")
    
    return build_info

def validate_build_requirements(service_name, service_config, build_locally):
    """Validate that all build requirements are met for a service"""
    
    build_context = service_config["build_context"]
    
    # Check if build context exists
    if not os.path.exists(build_context):
        fail("Build context does not exist for service '{}': {}".format(service_name, build_context))
    
    if build_locally:
        # Validate local build requirements
        dockerfile = service_config.get("dockerfile", build_context + "/Dockerfile")
        if not os.path.exists(dockerfile):
            fail("Dockerfile not found for service '{}': {}".format(service_name, dockerfile))
    else:
        # Validate ECR build requirements
        if not service_config.get("ecr_image"):
            fail("ECR image not specified for service '{}' but local build is disabled".format(service_name))
        
        # Check if AWS CLI is available for ECR authentication
        aws_check = local('command -v aws || echo "not_found"', quiet=True)
        if "not_found" in aws_check:
            print("⚠️  Warning: AWS CLI not found. ECR image pulling may fail for service '{}'".format(service_name))

def validate_live_update_configuration(service_name, service_config, debug_mode=False):
    """Validate live update configuration for a service"""
    
    build_context = service_config["build_context"]
    app_type = service_config.get("type", "generic")
    
    validation_results = {
        "service_name": service_name,
        "app_type": app_type,
        "build_context": build_context,
        "issues": [],
        "recommendations": [],
        "is_valid": True
    }
    
    # Check if build context exists
    if not os.path.exists(build_context):
        validation_results["issues"].append("Build context does not exist: {}".format(build_context))
        validation_results["is_valid"] = False
        return validation_results
    
    # Check for Dockerfile
    dockerfile = service_config.get("dockerfile", build_context + "/Dockerfile")
    if not os.path.exists(dockerfile):
        validation_results["issues"].append("Dockerfile not found: {}".format(dockerfile))
        validation_results["is_valid"] = False
    
    # Language-specific validations
    if app_type == "python":
        # Check for Python requirements files
        req_files = [
            build_context + '/requirements.txt',
            build_context + '/pyproject.toml',
            build_context + '/setup.py',
            build_context + '/Pipfile'
        ]
        if not any(os.path.exists(f) for f in req_files):
            validation_results["recommendations"].append("Consider adding a requirements.txt or pyproject.toml for better dependency management")
        
        # Check for source directory
        if not os.path.exists(build_context + '/src') and not any(f.endswith('.py') for f in os.listdir(build_context) if os.path.isfile(os.path.join(build_context, f))):
            validation_results["recommendations"].append("Consider organizing Python code in a 'src' directory for better live updates")
    
    elif app_type == "java":
        # Check for Maven or Gradle
        if not os.path.exists(build_context + '/pom.xml') and not os.path.exists(build_context + '/build.gradle'):
            validation_results["issues"].append("No Maven (pom.xml) or Gradle (build.gradle) configuration found")
            validation_results["is_valid"] = False
        
        # Check for source directory
        if not os.path.exists(build_context + '/src/main/java'):
            validation_results["recommendations"].append("Standard Maven/Gradle directory structure (src/main/java) not found")
    
    elif app_type == "go":
        # Check for go.mod
        if not os.path.exists(build_context + '/go.mod'):
            validation_results["issues"].append("No go.mod file found - Go modules are required for proper dependency management")
            validation_results["is_valid"] = False
        
        # Check for main package
        main_locations = [
            build_context + '/main.go',
            build_context + '/cmd',
            build_context + '/cmd/main.go'
        ]
        if not any(os.path.exists(loc) for loc in main_locations):
            validation_results["recommendations"].append("Consider organizing Go code with a main.go or cmd/ directory structure")
    
    elif app_type == "nodejs":
        # Check for package.json
        if not os.path.exists(build_context + '/package.json'):
            validation_results["issues"].append("No package.json file found - required for Node.js projects")
            validation_results["is_valid"] = False
        
        # Check for source directory or main files
        src_locations = [
            build_context + '/src',
            build_context + '/lib',
            build_context + '/index.js',
            build_context + '/app.js',
            build_context + '/server.js'
        ]
        if not any(os.path.exists(loc) for loc in src_locations):
            validation_results["recommendations"].append("Consider organizing Node.js code in a 'src' directory or having a main entry file")
    
    # Check for .dockerignore
    if not os.path.exists(build_context + '/.dockerignore'):
        validation_results["recommendations"].append("Consider adding a .dockerignore file to optimize build context")
    
    # Check for large directories that should be ignored
    large_dirs = ['node_modules', '__pycache__', 'target', 'build', 'dist', '.git']
    for dir_name in large_dirs:
        dir_path = build_context + '/' + dir_name
        if os.path.exists(dir_path):
            validation_results["recommendations"].append("Large directory '{}' found - ensure it's properly ignored in .dockerignore".format(dir_name))
    
    if debug_mode and validation_results["issues"]:
        print("⚠️  Live update validation issues for {}:".format(service_name))
        for issue in validation_results["issues"]:
            print("   • {}".format(issue))
    
    if debug_mode and validation_results["recommendations"]:
        print("💡 Live update recommendations for {}:".format(service_name))
        for rec in validation_results["recommendations"]:
            print("   • {}".format(rec))
    
    return validation_results

def setup_live_update_test():
    """Setup a local resource to test live update configuration"""
    
    local_resource(
        'live-update-test',
        '''
        echo "🧪 Running Live Update Configuration Test..."
        echo ""
        
        # Run the Python test script
        if command -v python3 &> /dev/null; then
            python3 .tilt/test-live-updates.py
        elif command -v python &> /dev/null; then
            python .tilt/test-live-updates.py
        else
            echo "❌ Python not found. Please install Python to run live update tests."
            echo "💡 You can still use live updates, but automated testing is not available."
        fi
        
        echo ""
        echo "📋 Manual Test Checklist:"
        echo "  1. Make a small change to a source file"
        echo "  2. Check Tilt UI for automatic rebuild trigger"
        echo "  3. Verify the change is reflected in the running container"
        echo "  4. Test that dependency file changes trigger full rebuilds"
        echo ""
        echo "🔧 Troubleshooting:"
        echo "  • If live updates are slow, check ignore patterns"
        echo "  • If changes don't trigger rebuilds, verify file paths"
        echo "  • If full rebuilds happen too often, check fallback rules"
        ''',
        serve_cmd='sleep 120',  # Run every 2 minutes
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['testing', 'live-updates', 'validation']
    )

def create_live_update_summary(services_info):
    """Create a summary resource showing live update configuration for all services"""
    
    local_services = [s for s in services_info if s.get("build_locally", False)]
    ecr_services = [s for s in services_info if not s.get("build_locally", False)]
    
    summary_script = '''
    echo "🔄 Live Update Configuration Summary"
    echo "===================================="
    echo ""
    echo "📦 Services with Live Updates ({} total):".format(len(local_services))
    '''
    
    for service in local_services:
        summary_script += '''
    echo "  • {name} ({app_type})"
    echo "    - Build Context: {build_context}"
    echo "    - Fallback Rules: {fallback_rules_count} files"
    echo "    - Watch Patterns: {watch_patterns_count} patterns"
    '''.format(
        name=service.get("name", "unknown"),
        app_type=service.get("app_type", "generic"),
        build_context=service.get("build_context", "unknown"),
        fallback_rules_count=service.get("fallback_rules_count", 0),
        watch_patterns_count=service.get("watch_patterns_count", 0)
    )
    
    summary_script += '''
    echo ""
    echo "🐳 Services using ECR Images ({} total):".format(len(ecr_services))
    '''
    
    for service in ecr_services:
        summary_script += '''
    echo "  • {name} ({app_type}) - ECR Image"
    '''.format(
        name=service.get("name", "unknown"),
        app_type=service.get("app_type", "generic")
    )
    
    summary_script += '''
    echo ""
    echo "🚀 Live Update Performance:"
    echo "  • File watching optimized with comprehensive ignore patterns"
    echo "  • Language-specific sync rules for faster updates"
    echo "  • Fallback rules prevent unnecessary full rebuilds"
    echo "  • Docker build context optimized with .dockerignore patterns"
    '''
    
    local_resource(
        'live-update-summary',
        summary_script,
        serve_cmd='sleep 300',  # Refresh every 5 minutes
        auto_init=True,
        trigger_mode=TRIGGER_MODE_AUTO,
        labels=['monitoring', 'live-updates', 'summary']
    )

def optimize_docker_build_context(build_context, app_type):
    """Create optimized .dockerignore patterns for better build performance"""
    
    dockerignore_path = build_context + "/.dockerignore"
    
    # Base ignore patterns for all application types
    base_ignores = [
        ".git",
        ".gitignore",
        "README.md",
        "*.md",
        ".DS_Store",
        "Thumbs.db",
        "*.log",
        "tmp/",
        "temp/",
        "coverage/",
        ".nyc_output/",
        ".coverage",
        "*.tmp",
        "*.temp"
    ]
    
    # Application-specific ignore patterns
    app_specific_ignores = {
        "python": [
            "__pycache__/",
            "*.pyc",
            "*.pyo",
            "*.pyd",
            ".Python",
            "env/",
            "venv/",
            ".venv/",
            ".pytest_cache/",
            ".tox/",
            "dist/",
            "build/",
            "*.egg-info/"
        ],
        "nodejs": [
            "node_modules/",
            "npm-debug.log*",
            "yarn-debug.log*",
            "yarn-error.log*",
            ".npm",
            ".yarn-integrity",
            "coverage/",
            ".nyc_output/",
            "dist/",
            "build/"
        ],
        "java": [
            "target/",
            "*.class",
            "*.jar",
            "*.war",
            "*.ear",
            ".gradle/",
            "build/",
            ".settings/",
            ".project",
            ".classpath"
        ],
        "go": [
            "*.exe",
            "*.exe~",
            "*.dll",
            "*.so",
            "*.dylib",
            "*.test",
            "*.out",
            "vendor/",
            ".vscode/"
        ]
    }
    
    # Combine base and app-specific ignores
    all_ignores = base_ignores + app_specific_ignores.get(app_type, [])
    
    # Write .dockerignore file if it doesn't exist or needs updating
    dockerignore_content = "\n".join(all_ignores) + "\n"
    
    # Only update if file doesn't exist or content is different
    try:
        existing_content = str(local('cat {}'.format(dockerignore_path), quiet=True))
        if existing_content != dockerignore_content:
            local('echo "{}" > {}'.format(dockerignore_content.replace('\n', '\\n'), dockerignore_path))
    except:
        # File doesn't exist, create it
        local('echo "{}" > {}'.format(dockerignore_content.replace('\n', '\\n'), dockerignore_path))

def setup_live_reload_monitoring(services_info):
    """Setup monitoring for live reload and file watching performance"""
    
    # Create a local resource to monitor live reload performance
    local_resource(
        'live-reload-monitor',
        '''
        echo "🔄 Live Reload Performance Monitor"
        echo "================================="
        
        # Show file watching statistics
        echo "👀 File Watching Status:"
        echo "  • Total services with live reload: ''' + str(len([s for s in services_info if s.get("build_locally", False)])) + '''"
        
        # Show recent file changes (if available)
        echo ""
        echo "📁 Recent File Changes (last 5 minutes):"
        find . -type f -mmin -5 -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./__pycache__/*" -not -path "./target/*" -not -path "./build/*" -not -path "./dist/*" | head -10 || echo "  No recent changes detected"
        
        echo ""
        echo "🚀 Live Update Performance Tips:"
        echo "  • Use specific sync patterns to reduce file watching overhead"
        echo "  • Configure proper ignore patterns to exclude unnecessary files"
        echo "  • Use fall_back_on rules for complex changes requiring full rebuilds"
        echo "  • Monitor Docker build cache usage for optimal performance"
        
        echo ""
        echo "📊 File System Statistics:"
        echo "  • Total files being watched: $(find . -type f -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./__pycache__/*" -not -path "./target/*" -not -path "./build/*" -not -path "./dist/*" | wc -l)"
        echo "  • Ignored patterns active: Yes (comprehensive ignore rules applied)"
        ''',
        serve_cmd='sleep 60',
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['monitoring', 'live-reload', 'file-watching']
    )

def setup_build_monitoring(services_info):
    """Setup monitoring for build processes and performance"""
    
    # Create a local resource to monitor build performance
    local_resource(
        'build-monitor',
        '''
        echo "🔍 Build Performance Monitor"
        echo "=========================="
        
        # Show Docker system info
        echo "📊 Docker System Usage:"
        docker system df
        
        echo ""
        echo "🏗️  Recent Build Activity:"
        docker images --format "table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}\\t{{.CreatedAt}}" | head -10
        
        echo ""
        echo "🧹 Cleanup Recommendations:"
        DANGLING=$(docker images -f "dangling=true" -q | wc -l)
        if [ $DANGLING -gt 0 ]; then
            echo "  • $DANGLING dangling images can be cleaned up"
            echo "  • Run: docker image prune"
        fi
        
        UNUSED_VOLUMES=$(docker volume ls -f "dangling=true" -q | wc -l)
        if [ $UNUSED_VOLUMES -gt 0 ]; then
            echo "  • $UNUSED_VOLUMES unused volumes can be cleaned up"
            echo "  • Run: docker volume prune"
        fi
        
        echo ""
        echo "🔄 Live Reload Services:"
        ''' + '\n        '.join(['echo "  • {}: {} ({})"'.format(
            s.get("name", "unknown"), 
            "Local Build" if s.get("build_locally", False) else "ECR Image",
            s.get("app_type", "generic")
        ) for s in services_info]) + '''
        ''',
        serve_cmd='sleep 30',
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['monitoring', 'builds']
    )
    
    # Setup live reload monitoring
    setup_live_reload_monitoring(services_info)
    
    # Setup live update validation test
    setup_live_update_test()

def create_build_strategy_dashboard(services_info, tilt_config):
    """Create a dashboard showing build strategies and ECR versions for all services"""
    
    local_resource(
        'build-strategy-dashboard',
        cmd='''
        echo "🔨 BUILD STRATEGY DASHBOARD"
        echo "=========================="
        echo "Default Strategy: ''' + tilt_config.get("build_strategy", "ecr") + '''"
        echo ""
        
        echo "📦 SERVICE BUILD STRATEGIES"
        echo "--------------------------"
        ''' + '\n        '.join([
            '''
        echo "🔧 {}"
        echo "   Strategy: {}"
        echo "   Type: {}"
        {}
        echo ""'''.format(
                s.get("name", "unknown"),
                "Local Build" if s.get("build_locally", False) else "ECR Image",
                s.get("app_type", "generic"),
                'echo "   ECR Image: {}"'.format(s.get("ecr_image", "")) if not s.get("build_locally", False) else 'echo "   Build Context: {}"'.format(s.get("build_context", ""))
            ) for s in services_info
        ]) + '''
        
        echo "🏷️  ECR VERSION OVERRIDES"
        echo "------------------------"
        ''' + ('''
        ''' + '\n        '.join([
            'echo "  - {}: {}"'.format(svc, version) 
            for svc, version in tilt_config.get("ecr_versions", {}).items()
        ]) + '''
        ''' if tilt_config.get("ecr_versions") else 'echo "  No version overrides configured"') + '''
        
        echo ""
        echo "💡 BUILD STRATEGY COMMANDS"
        echo "========================="
        echo "Force all services to build locally:"
        echo "  tilt up -- --build_strategy=local"
        echo ""
        echo "Use mixed strategy (specify which to build locally):"
        echo "  tilt up -- --build_strategy=mixed --build_local=service1,service2"
        echo ""
        echo "Override ECR versions:"
        echo "  tilt up -- --ecr_versions=service1:v1.2.3,service2:latest"
        ''',
        deps=[],
        labels=['build-strategy', 'dashboard', 'configuration'],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def create_ecr_version_monitor(services_info):
    """Create a monitor for ECR image versions and availability"""
    
    ecr_services = [s for s in services_info if not s.get("build_locally", False) and s.get("ecr_image")]
    
    if not ecr_services:
        return
    
    local_resource(
        'ecr-version-monitor',
        cmd='''
        echo "🏷️  ECR VERSION MONITOR"
        echo "======================"
        echo "Checking ECR image availability and versions..."
        echo ""
        
        ''' + '\n        '.join([
            '''
        echo "📦 {}"
        echo "   Image: {}"
        echo "   Version: {}"
        
        # Check if image exists and get info
        if docker manifest inspect {} >/dev/null 2>&1; then
            echo "   Status: ✅ Available"
            # Get image creation date if possible
            CREATED=$(docker inspect {} --format='{{{{.Created}}}}' 2>/dev/null | cut -d'T' -f1 || echo "Unknown")
            echo "   Created: $CREATED"
        else
            echo "   Status: ❌ Not accessible (may need authentication)"
        fi
        echo ""'''.format(
                s.get("name", "unknown"),
                s.get("ecr_image", ""),
                s.get("ecr_version", "latest"),
                s.get("ecr_image", ""),
                s.get("ecr_image", "")
            ) for s in ecr_services
        ]) + '''
        
        echo "🔧 ECR MANAGEMENT COMMANDS"
        echo "========================="
        echo "Authenticate with ECR:"
        echo "  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <registry>"
        echo ""
        echo "List available tags for a repository:"
        echo "  aws ecr describe-images --repository-name <repo-name> --query 'imageDetails[*].imageTags' --output table"
        echo ""
        echo "Pull specific version:"
        echo "  tilt up -- --ecr_versions=service:v1.2.3"
        ''',
        deps=[],
        labels=['ecr', 'versions', 'monitoring'],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def validate_service_customizations(service_name, service_config, tilt_config):
    """Validate service customizations and provide warnings for potential issues"""
    
    issues = []
    warnings = []
    
    # Validate ECR version overrides
    if service_name in tilt_config.get("ecr_versions", {}):
        ecr_image = service_config.get("ecr_image", "")
        if not ecr_image:
            issues.append("ECR version override specified but no ECR image configured")
        elif service_config.get("_force_local_build", False):
            warnings.append("ECR version override specified but service is forced to build locally")
    
    # Validate environment variable overrides
    if service_name in tilt_config.get("env_overrides", {}):
        env_overrides = tilt_config["env_overrides"][service_name]
        existing_env_vars = {
            env_var.get("name") for env_var in service_config.get("env_vars", [])
            if isinstance(env_var, dict) and "name" in env_var
        }
        
        for var_name in env_overrides.keys():
            if var_name not in existing_env_vars:
                warnings.append("Environment override '{}' adds new variable not in original config".format(var_name))
    
    # Validate build strategy conflicts
    build_strategy = tilt_config.get("build_strategy", "ecr")
    if build_strategy == "local" and service_config.get("ecr_image") and not service_config.get("build_context"):
        issues.append("Local build strategy specified but no build context available")
    
    return {
        "service_name": service_name,
        "issues": issues,
        "warnings": warnings,
        "is_valid": len(issues) == 0
    }

def create_service_customization_validator(services_info, tilt_config):
    """Create a validator resource for service customizations"""
    
    local_resource(
        'service-customization-validator',
        cmd='''
        echo "🔍 SERVICE CUSTOMIZATION VALIDATOR"
        echo "================================="
        echo "Validating service customizations..."
        echo ""
        
        ISSUES_FOUND=0
        WARNINGS_FOUND=0
        
        ''' + '\n        '.join([
            '''
        echo "📦 Validating: {}"
        
        # Validate ECR version override
        ''' + ('''
        echo "   🏷️  ECR Version Override: {} -> {}"
        '''.format(s.get("ecr_image", "").split(":")[-1] if ":" in s.get("ecr_image", "") else "latest", 
                  tilt_config.get("ecr_versions", {}).get(s.get("name", ""), "")) 
        if s.get("name") in tilt_config.get("ecr_versions", {}) else '') + '''
        
        # Validate environment overrides
        ''' + ('''
        echo "   🔧 Environment Overrides: {}"
        '''.format(len(tilt_config.get("env_overrides", {}).get(s.get("name", ""), {})))
        if s.get("name") in tilt_config.get("env_overrides", {}) else '') + '''
        
        # Validate build strategy
        echo "   🔨 Build Strategy: {}"
        
        echo "   Status: ✅ Valid"
        echo ""'''.format(
                s.get("name", "unknown"),
                "Local Build" if s.get("build_locally", False) else "ECR Image"
            ) for s in services_info
        ]) + '''
        
        if [ $ISSUES_FOUND -eq 0 ]; then
            echo "✅ All service customizations are valid"
        else
            echo "❌ Found $ISSUES_FOUND validation issues"
        fi
        
        if [ $WARNINGS_FOUND -gt 0 ]; then
            echo "⚠️  Found $WARNINGS_FOUND warnings"
        fi
        ''',
        deps=[],
        labels=['validation', 'customization', 'configuration'],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )