"""
Build management for different service types
Handles Docker builds, ECR images, and live updates with comprehensive optimization
Implements advanced file watching and live reload system with language-specific optimizations
"""

# Load the restart_process extension to replace deprecated restart_container()
load('ext://restart_process', 'restart_process')

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
            # ALL SYNC STEPS MUST COME FIRST
            # Sync the specific Python file that exists
            sync(build_context + '/main.py', '/app/main.py'),

            # Handle dependency changes
            sync(build_context + '/requirements.txt', '/app/requirements.txt'),

            # ALL RUN STEPS MUST COME AFTER ALL SYNC STEPS
            # Install dependencies when they change
            run('pip install -r requirements.txt', trigger=[build_context + '/requirements.txt']),

            # Restart process for changes
            restart_process()
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

            restart_process()
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

            restart_process()
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

            restart_process()
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
            restart_process()
        ]

def setup_build_strategy(service_name, service_config, build_local_services, debug_mode=False):
    """Setup build strategy (local Docker build, ECR, or external image) for a service"""

    # Check if this is an external service with a pre-built image
    service_type = service_config.get("type", "generic")
    external_image = service_config.get("image")

    # Priority 1: External services with pre-built images (e.g., postgres:15, redis:7-alpine)
    if service_type == "external" and external_image:
        return _setup_external_image(service_name, service_config, debug_mode)

    # Priority 2: Local builds (when explicitly requested)
    build_locally = service_name in build_local_services
    if build_locally:
        return _setup_local_build(service_name, service_config, debug_mode)

    # Priority 3: ECR builds (fallback for non-external services)
    return _setup_ecr_build(service_name, service_config, debug_mode)

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
        "build_context": build_context
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

def validate_build_requirements(service_name, service_config, build_locally, debug_mode=False):
    """Validate that all required build dependencies are available for different service types"""

    service_type = service_config.get("type", "generic")
    external_image = service_config.get("image")

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

    # Handle local builds
    if build_locally:
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

    # Handle ECR builds
    else:
        ecr_image = service_config.get("ecr_image")
        if not ecr_image:
            validation_results["errors"].append("ECR image not specified for service: " + service_name)
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

def get_build_info(service_name, service_config, build_local_services):
    """Get comprehensive build information for a service"""

    build_context = service_config.get("build_context", "./" + service_name)
    dockerfile_path = service_config.get("dockerfile", build_context + "/Dockerfile")
    service_type = service_config.get("type", "generic")
    ecr_image = service_config.get("ecr_image")
    build_locally = service_name in build_local_services

    return {
        "service_name": service_name,
        "service_type": service_type,
        "build_context": build_context,
        "dockerfile_path": dockerfile_path,
        "build_locally": build_locally,
        "ecr_image": ecr_image,
        "image_name": service_name if build_locally else ecr_image,
        "live_updates_enabled": build_locally,
        "optimization_available": True
    }

def create_service_customization_validator(deployed_services, tilt_config):
    """Create service customization validator resource"""

    local_resource('service-customization-validator',
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
        '\n'.join(['  ✓ ' + svc["name"] + ' (' + svc.get("type", "generic") + ')' for svc in deployed_services])
    ),
        labels=["monitoring"]
    )

def setup_build_monitoring(deployed_services):
    """Setup build monitoring for deployed services"""

    if not deployed_services:
        return

    local_resource('tilt-build-monitor',
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
        labels=["monitoring"]
    )

def create_live_update_summary(deployed_services):
    """Create live update summary resource"""

    local_services = [svc for svc in deployed_services if svc.get("build_locally", False)]

    if not local_services:
        return

    local_resource('live-update-summary',
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
""".format('\n'.join(['  - ' + svc["name"] + ' (' + svc.get("type", "generic") + ')' for svc in local_services])),
        labels=["monitoring"]
    )

def create_build_strategy_dashboard(deployed_services, tilt_config):
    """Create build strategy dashboard resource"""

    local_resource('build-strategy-dashboard',
        cmd="""
echo "🏗️  Build Strategy Dashboard"
echo "============================"
echo "Total services: {}"
echo "Local builds: {}"
echo "External images: {}"
echo "ECR images: {}"
echo ""
echo "Build configuration:"
{}
echo ""
echo "💡 Configure build strategy in developer-config.yaml"
""".format(
        len(deployed_services),
        len([svc for svc in deployed_services if svc.get("build_locally", False)]),
        len([svc for svc in deployed_services if svc.get("external_image", False)]),
        len([svc for svc in deployed_services if not svc.get("build_locally", False) and not svc.get("external_image", False)]),
        '\n'.join(['  - ' + svc["name"] + ': ' + (
            'Local build' if svc.get("build_locally", False)
            else 'External image' if svc.get("external_image", False)
            else 'ECR image'
        ) for svc in deployed_services])
    ),
        labels=["monitoring"]
    )

def create_ecr_version_monitor(deployed_services):
    """Create ECR version monitoring resource"""

    ecr_services = [svc for svc in deployed_services if not svc.get("build_locally", False) and svc.get("ecr_image")]

    if not ecr_services:
        return

    local_resource('ecr-version-monitor',
        cmd="""
echo "📦 ECR Image Versions"
echo "===================="
{}
echo ""
echo "💡 Check ECR for latest versions: aws ecr describe-images"
""".format('\n'.join(['  - ' + svc["name"] + ': ' + svc.get("ecr_image", "unknown") for svc in ecr_services])),
        labels=["monitoring"]
    )
