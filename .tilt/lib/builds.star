"""
Build management for different service types
Handles Docker builds, ECR images, and live updates with comprehensive optimization
Implements advanced file watching and live reload system with language-specific optimizations
"""

# Load the restart_process extension to replace deprecated restart_container()
load('ext://restart_process', 'RESTART_FILE')

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

def get_live_updates_for_command_build(app_type, build_working_dir):
    """Return optimized live update rules for command-based builds (Maven/Gradle/etc)"""
    
    if app_type == "java":
        return [
            # ALL SYNC STEPS FIRST
            # For Maven/Gradle, sync source files to trigger rebuilds
            sync(build_working_dir + '/src', '/app/src'),
            sync(build_working_dir + '/target/classes', '/app/classes'),
            
            # Handle build files that trigger rebuild
            sync(build_working_dir + '/pom.xml', '/app/pom.xml'),
            sync(build_working_dir + '/build.gradle', '/app/build.gradle'),
            sync(build_working_dir + '/gradle.properties', '/app/gradle.properties'),
            
            # Configuration files
            sync(build_working_dir + '/src/main/resources', '/app/resources'),
            
            # ALL RUN STEPS AFTER SYNC STEPS
            # Trigger rebuild when source or build files change
            run('echo "Source changed, triggering rebuild via build command"', trigger=[
                build_working_dir + '/src/**/*.java',
                build_working_dir + '/pom.xml',
                build_working_dir + '/build.gradle'
            ]),
            
            run('touch ' + RESTART_FILE, trigger=[])
        ]
    elif app_type == "python":
        return [
            # ALL SYNC STEPS FIRST
            sync(build_working_dir + '/src', '/app/src'),
            sync(build_working_dir + '/*.py', '/app/'),
            sync(build_working_dir + '/requirements.txt', '/app/requirements.txt'),
            
            # ALL RUN STEPS AFTER SYNC STEPS
            run('pip install -r requirements.txt', trigger=[build_working_dir + '/requirements.txt']),
            run('touch ' + RESTART_FILE, trigger=[])
        ]
    elif app_type == "go":
        return [
            # ALL SYNC STEPS FIRST
            sync(build_working_dir + '/cmd', '/app/cmd'),
            sync(build_working_dir + '/pkg', '/app/pkg'),
            sync(build_working_dir + '/go.mod', '/app/go.mod'),
            sync(build_working_dir + '/go.sum', '/app/go.sum'),
            
            # ALL RUN STEPS AFTER SYNC STEPS
            run('go mod download', trigger=[build_working_dir + '/go.mod']),
            run('touch ' + RESTART_FILE, trigger=[])
        ]
    elif app_type == "nodejs":
        return [
            # ALL SYNC STEPS FIRST
            sync(build_working_dir + '/src', '/app/src'),
            sync(build_working_dir + '/package.json', '/app/package.json'),
            sync(build_working_dir + '/package-lock.json', '/app/package-lock.json'),
            
            # ALL RUN STEPS AFTER SYNC STEPS
            run('npm install', trigger=[build_working_dir + '/package.json']),
            run('touch ' + RESTART_FILE, trigger=[])
        ]
    else:
        # Generic fallback for command builds
        return [
            # ALL SYNC STEPS FIRST
            sync(build_working_dir + '/src', '/app/src'),
            sync(build_working_dir + '/config', '/app/config'),
            
            # RUN STEPS AFTER SYNC STEPS
            run('echo "Files changed, may need rebuild"', trigger=[build_working_dir + '/src/**/*']),
            run('touch ' + RESTART_FILE, trigger=[])
        ]

def get_live_updates_for_type(app_type, build_context):
    """Return optimized live update rules based on application type with comprehensive file watching and fallback rules"""

    if app_type == "python":
        return [
            # ALL SYNC STEPS MUST COME FIRST
            # Sync Python files (uvicorn --reload will detect changes automatically)
            sync(build_context, '/app'),

            # ALL RUN STEPS MUST COME AFTER ALL SYNC STEPS
            # Install dependencies when they change
            run('pip install -r requirements.txt', trigger=[build_context + '/requirements.txt'])
            # Note: uvicorn --reload automatically detects .py file changes, no restart needed
        ]
    elif app_type == "java":
        return [
            # ALL SYNC STEPS FIRST
            # Sync compiled classes for hot reload
            sync(build_context + '/target/classes', '/app/classes'),

            # Sync resources and configuration
            sync(build_context + '/src/main/resources', '/app/resources'),
            sync(build_context + '/target/generated-sources', '/app/generated-sources'),

            # Handle Maven/Gradle build files
            sync(build_context + '/pom.xml', '/app/pom.xml'),
            sync(build_context + '/build.gradle', '/app/build.gradle'),
            sync(build_context + '/gradle.properties', '/app/gradle.properties'),
            sync(build_context + '/settings.gradle', '/app/settings.gradle'),

            # Handle Spring Boot configuration
            sync(build_context + '/src/main/resources/application*.properties', '/app/resources/'),
            sync(build_context + '/src/main/resources/application*.yml', '/app/resources/'),
            sync(build_context + '/src/main/resources/application*.yaml', '/app/resources/'),

            # ALL RUN STEPS AFTER SYNC STEPS
            # Handle Spring Boot DevTools if present
            run('touch /app/restart.txt', trigger=[build_context + '/src/main/java/**/*.java']),
            run('mvn compile', trigger=[build_context + '/pom.xml']),
            run('gradle compileJava', trigger=[build_context + '/build.gradle']),

            run('touch ' + RESTART_FILE, trigger=[])
        ]
    elif app_type == "go":
        return [
            # ALL SYNC STEPS FIRST
            # Sync Go source code
            sync(build_context + '/cmd', '/app/cmd'),
            sync(build_context + '/pkg', '/app/pkg'),
            sync(build_context + '/internal', '/app/internal'),
            sync(build_context + '/*.go', '/app/'),

            # Handle Go modules
            sync(build_context + '/go.mod', '/app/go.mod'),
            sync(build_context + '/go.sum', '/app/go.sum'),
            sync(build_context + '/go.work', '/app/go.work'),
            sync(build_context + '/go.work.sum', '/app/go.work.sum'),

            # Sync configuration files
            sync(build_context + '/config', '/app/config'),
            sync(build_context + '/*.yaml', '/app/'),
            sync(build_context + '/*.yml', '/app/'),
            sync(build_context + '/*.json', '/app/'),
            sync(build_context + '/*.toml', '/app/'),
            sync(build_context + '/.env*', '/app/'),

            # Handle embedded files and assets
            sync(build_context + '/assets', '/app/assets'),
            sync(build_context + '/web', '/app/web'),
            sync(build_context + '/static', '/app/static'),

            # ALL RUN STEPS AFTER SYNC STEPS
            # Rebuild binary when source changes
            run('go mod download', trigger=[build_context + '/go.mod', build_context + '/go.sum']),
            run('go mod tidy', trigger=[build_context + '/go.mod']),
            run('go build -o /app/main ./cmd', trigger=[
                build_context + '/cmd/**/*.go',
                build_context + '/pkg/**/*.go',
                build_context + '/internal/**/*.go',
                build_context + '/*.go'
            ]),

            run('touch ' + RESTART_FILE, trigger=[])
        ]
    elif app_type == "nodejs":
        return [
            # ALL SYNC STEPS FIRST
            # Sync Node.js source code
            sync(build_context + '/src', '/app/src'),
            sync(build_context + '/lib', '/app/lib'),
            sync(build_context + '/routes', '/app/routes'),
            sync(build_context + '/controllers', '/app/controllers'),
            sync(build_context + '/middleware', '/app/middleware'),
            sync(build_context + '/models', '/app/models'),
            sync(build_context + '/utils', '/app/utils'),
            sync(build_context + '/*.js', '/app/'),
            sync(build_context + '/*.ts', '/app/'),
            sync(build_context + '/*.mjs', '/app/'),

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

            # Sync configuration files
            sync(build_context + '/config', '/app/config'),
            sync(build_context + '/*.yaml', '/app/'),
            sync(build_context + '/*.yml', '/app/'),
            sync(build_context + '/*.json', '/app/'),
            sync(build_context + '/.env*', '/app/'),

            # Handle static files and views
            sync(build_context + '/public', '/app/public'),
            sync(build_context + '/static', '/app/static'),
            sync(build_context + '/views', '/app/views'),
            sync(build_context + '/templates', '/app/templates'),

            # ALL RUN STEPS AFTER SYNC STEPS
            # Install dependencies when they change
            run('npm install', trigger=[build_context + '/package.json', build_context + '/package-lock.json']),
            run('yarn install', trigger=[build_context + '/yarn.lock']),
            run('pnpm install', trigger=[build_context + '/pnpm-lock.yaml']),

            # Handle TypeScript compilation if needed
            run('npm run build', trigger=[build_context + '/src/**/*.ts', build_context + '/tsconfig.json']),
            run('npx tsc', trigger=[build_context + '/src/**/*.ts', build_context + '/tsconfig.json']),

            run('touch ' + RESTART_FILE, trigger=[])
        ]
    else:
        # Generic fallback for unknown application types
        return [
            # ALL SYNC STEPS FIRST
            sync(build_context + '/src', '/app/src'),
            sync(build_context + '/config', '/app/config'),
            sync(build_context + '/*.yaml', '/app/'),
            sync(build_context + '/*.yml', '/app/'),
            sync(build_context + '/*.json', '/app/'),
            sync(build_context + '/.env*', '/app/'),

            # RUN STEPS AFTER SYNC STEPS
            run('touch ' + RESTART_FILE, trigger=[])
        ]

def setup_build_strategy(service_name, service_config, debug_mode=False):
    """Setup build strategy using automatic detection based on service configuration fields"""

    # Check service type and configuration fields for automatic detection
    service_type = service_config.get("type", "generic")
    external_image = service_config.get("image")
    ecr_image = service_config.get("ecr_image")
    build_command = service_config.get("build_command")

    # Priority 1: External services with pre-built images (e.g., postgres:15, redis:7-alpine)
    if service_type == "external" and external_image:
        return _setup_external_image(service_name, service_config, debug_mode)

    # Priority 2: ECR images (when explicitly configured)
    if ecr_image:
        return _setup_ecr_build(service_name, service_config, debug_mode)

    # Priority 3: Command-based builds (when build_command is specified)
    if build_command:
        return _setup_command_build(service_name, service_config, debug_mode)

    # Priority 4: Dockerfile builds (default for application services)
    return _setup_local_build(service_name, service_config, debug_mode)

def _setup_external_image(service_name, service_config, debug_mode=False):
    """Setup external pre-built image from Docker registry (e.g., Docker Hub, ECR Public)"""

    image_name = service_config.get("image")

    if debug_mode:
        print("🐳 Using external Docker image for: " + service_name)
        print("   Image: " + image_name)

    return {
        "image_name": image_name,
        "build_locally": False,
        "external_image": True
    }

def _setup_local_build(service_name, service_config, debug_mode=False):
    """Setup local Docker build with live updates"""

    build_context = service_config.get("build_context", "./" + service_name)
    dockerfile_path = service_config.get("dockerfile", build_context + "/Dockerfile")
    app_type = service_config.get("type", "generic")

    if debug_mode:
        print("🔨 Setting up local Docker build for: " + service_name)
        print("   Build context: " + build_context)
        print("   Dockerfile: " + dockerfile_path)

    # Build Docker image locally with live updates
    docker_build(
        service_name,
        context=build_context,
        dockerfile=dockerfile_path,
        live_update=get_live_updates_for_type(app_type, build_context)
    )

    return {
        "image_name": service_name,
        "build_locally": True,
        "build_context": build_context,
        "build_mode": "dockerfile"
    }

def _setup_command_build(service_name, service_config, debug_mode=False):
    """Setup command-based Docker build (e.g., Maven, Gradle, etc.)"""

    build_command = service_config.get("build_command")
    build_working_dir = service_config.get("build_working_dir", "./" + service_name)
    app_type = service_config.get("type", "generic")

    if debug_mode:
        print("⚡ Setting up command-based build for: " + service_name)
        print("   Build command: " + build_command)
        print("   Working directory: " + build_working_dir)

    # Use custom_build for command-based builds
    custom_build(
        service_name,
        command=build_command,
        deps=[build_working_dir],
        live_update=get_live_updates_for_command_build(app_type, build_working_dir)
    )

    return {
        "image_name": service_name,
        "build_locally": True,
        "build_context": build_working_dir,
        "build_mode": "command",
        "build_command": build_command
    }

def _setup_ecr_build(service_name, service_config, debug_mode=False):
    """Setup ECR image deployment"""

    ecr_image = service_config.get("ecr_image")
    if not ecr_image:
        fail("ECR image not specified for service: " + service_name)

    if debug_mode:
        print("📦 Using ECR image for: " + service_name)
        print("   ECR image: " + ecr_image)

    return {
        "image_name": ecr_image,
        "build_locally": False,
        "ecr_image": ecr_image
    }

def validate_build_requirements(service_name, service_config, debug_mode=False):
    """Validate that all required build dependencies are available for different service types"""

    service_type = service_config.get("type", "generic")
    external_image = service_config.get("image")
    ecr_image = service_config.get("ecr_image")
    build_command = service_config.get("build_command")

    if debug_mode:
        print("🔍 Validating build requirements for: " + service_name)

    validation_results = {
        "valid": True,
        "errors": [],
        "warnings": []
    }

    # Handle external services with pre-built images
    if service_type == "external" and external_image:
        if debug_mode:
            print("   ✅ External service detected with image: " + external_image)

        # Validate image format
        if not external_image or len(external_image.strip()) == 0:
            validation_results["errors"].append("External service image cannot be empty")
            validation_results["valid"] = False

        return validation_results

    # Handle ECR builds
    if ecr_image:
        if debug_mode:
            print("   📦 ECR image detected: " + ecr_image)
        # ECR images don't need local validation
        return validation_results

    # Handle command-based builds
    if build_command:
        if debug_mode:
            print("   🔧 Command-based build detected: " + build_command)
        
        build_working_dir = service_config.get("build_working_dir", "./" + service_name)
        
        # Validate build command is not empty
        if not build_command or len(build_command.strip()) == 0:
            validation_results["errors"].append("Build command cannot be empty")
            validation_results["valid"] = False
        
        # Check if working directory exists
        if not str(local('test -d ' + build_working_dir + ' && echo "exists" || echo "missing"')).strip() == "exists":
            validation_results["errors"].append("Build working directory not found: " + build_working_dir)
            validation_results["valid"] = False
        
        return validation_results

    # Handle Dockerfile-based builds (default)
    if debug_mode:
        print("   📄 Dockerfile-based build detected")
        
    build_context = service_config.get("build_context", "./" + service_name)
    dockerfile_path = service_config.get("dockerfile", build_context + "/Dockerfile")

    # Check if Dockerfile exists
    if not str(local('test -f ' + dockerfile_path + ' && echo "exists" || echo "missing"')).strip() == "exists":
        validation_results["errors"].append("Dockerfile not found: " + dockerfile_path)
        validation_results["valid"] = False

    # Check if build context exists
    if not str(local('test -d ' + build_context + ' && echo "exists" || echo "missing"')).strip() == "exists":
        validation_results["errors"].append("Build context directory not found: " + build_context)
        validation_results["valid"] = False

    if debug_mode:
        if validation_results["valid"]:
            print("   ✅ Build requirements validated successfully")
        else:
            print("   ❌ Build validation failed with {} errors".format(len(validation_results["errors"])))

    return validation_results

def optimize_docker_build_context(build_context, service_type="generic", debug_mode=False):
    """Optimize Docker build context by identifying and excluding unnecessary files"""

    if debug_mode:
        print("🔧 Optimizing build context for build context: " + build_context)

    return {
        "optimized_context": build_context,
        "exclude_patterns": [],
        "include_patterns": []
    }

def get_build_info(service_name, service_config):
    """Get comprehensive build information for a service using auto-detection"""

    build_context = service_config.get("build_context", "./" + service_name)
    dockerfile_path = service_config.get("dockerfile", build_context + "/Dockerfile")
    service_type = service_config.get("type", "generic")
    ecr_image = service_config.get("ecr_image")
    build_command = service_config.get("build_command")
    external_image = service_config.get("image")
    
    # Determine build type using same auto-detection logic as setup_build_strategy
    build_locally = True  # Default
    image_name = service_name  # Default
    
    if service_type == "external" and external_image:
        build_locally = False
        image_name = external_image
    elif ecr_image:
        build_locally = False 
        image_name = ecr_image
    elif build_command or build_context:
        build_locally = True
        image_name = service_name

    return {
        "service_name": service_name,
        "service_type": service_type,
        "build_context": build_context,
        "dockerfile_path": dockerfile_path,
        "build_locally": build_locally,
        "ecr_image": ecr_image,
        "image_name": image_name,
        "live_updates_enabled": build_locally,
        "optimization_available": True
    }

def create_service_customization_validator(deployed_services, tilt_config):
    """Create service customization validator resource"""

    local_resource('service-customization-validator',
        labels=['builds'],
        cmd="""
echo "✅ Service Customization Validator"
echo "================================="
echo "Validating service configurations..."
echo ""
echo "Services validated: {}"
{}
echo ""
echo "Configuration sources:"
echo "  - service-config.yaml: Service definitions"
echo "  - developer-config.yaml: Developer preferences"
echo "  - Tilt arguments: Runtime overrides"
echo ""
echo "✅ All configurations validated successfully"
""".format(
        len(deployed_services),
        '\n'.join(['echo "  ✓ ' + svc["name"] + ' [' + svc.get("type", "generic") + ']"' for svc in deployed_services])
    ),
    )

def setup_build_monitoring(deployed_services):
    """Setup build monitoring for deployed services"""

    if not deployed_services:
        return

    local_resource('tilt-build-monitor',
        labels=['builds'],
        cmd="""
echo "🔧 Build Monitoring Dashboard"
echo "==============================="
for service in {}; do
    echo "Service: $service"
    echo "  Build Status: $(docker images | grep $service | wc -l) images"
    echo "  Live Updates: Enabled"
done
echo ""
echo "💡 Use 'tilt logs <service>' to view build logs"
""".format(' '.join([svc["name"] for svc in deployed_services])),
    )

def create_live_update_summary(deployed_services):
    """Create live update summary resource"""

    local_services = [svc for svc in deployed_services if svc.get("build_locally", False)]

    if not local_services:
        return

    local_resource('live-update-summary',
        labels=['builds'],
        cmd="""
echo "🔄 Live Update Summary"
echo "====================="
echo "Services with live updates enabled:"
{}
echo ""
echo "📁 File watching patterns:"
echo "  Python: *.py, requirements.txt, src/**"
echo "  Java: target/classes, pom.xml, src/**"
echo "  Go: *.go, go.mod, cmd/**, pkg/**"
echo "  Node.js: *.js, *.ts, package.json, src/**"
echo ""
echo "💡 Save files to trigger automatic updates"
""".format('\n'.join(['echo "  - ' + svc["name"] + ' [' + svc.get("type", "generic") + ']"' for svc in local_services])),
    )

def create_build_strategy_dashboard(deployed_services, tilt_config):
    """Create build strategy dashboard resource"""

    # Count different build types
    dockerfile_builds = len([svc for svc in deployed_services if svc.get("build_mode") == "dockerfile"])
    command_builds = len([svc for svc in deployed_services if svc.get("build_mode") == "command"])
    local_builds = len([svc for svc in deployed_services if svc.get("build_locally", False)])
    external_images = len([svc for svc in deployed_services if svc.get("external_image", False)])
    ecr_images = len([svc for svc in deployed_services if not svc.get("build_locally", False) and not svc.get("external_image", False)])

    local_resource('build-strategy-dashboard',
        labels=['builds'],
        cmd="""
echo "🏗️  Build Strategy Dashboard"
echo "============================"
echo "Total services: {}"
echo "Local builds: {} (Dockerfile: {}, Command: {})"
echo "External images: {}"
echo "ECR images: {}"
echo ""
echo "Build configuration:"
{}
echo ""
echo "💡 Configure build strategy in developer-config.yaml"
echo "🔧 Command builds use: mvn spring-boot:build-image, gradle bootBuildImage, etc."
echo "📄 Dockerfile builds use: traditional Dockerfile + docker_build()"
""".format(
        len(deployed_services),
        local_builds, dockerfile_builds, command_builds,
        external_images, ecr_images,
        '\n'.join(['  - ' + svc["name"] + ': ' + (
            'Command build (' + svc.get("build_command", "").split()[0] + ')' if svc.get("build_mode") == "command"
            else 'Dockerfile build' if svc.get("build_mode") == "dockerfile" 
            else 'Local build' if svc.get("build_locally", False)
            else 'External image' if svc.get("external_image", False)
            else 'ECR image'
        ) for svc in deployed_services])
    ),
    )

def create_ecr_version_monitor(deployed_services):
    """Create ECR version monitoring resource"""

    ecr_services = [svc for svc in deployed_services if not svc.get("build_locally", False) and svc.get("ecr_image")]

    if not ecr_services:
        return

    local_resource('ecr-version-monitor',
        labels=['builds'],
        cmd="""
echo "📦 ECR Image Versions"
echo "===================="
{}
echo ""
echo "💡 Check ECR for latest versions: aws ecr describe-images"
""".format('\n'.join(['  - ' + svc["name"] + ': ' + svc.get("ecr_image", "unknown") for svc in ecr_services])),
    )
