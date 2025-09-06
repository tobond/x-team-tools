"""
Configuration management for Tilt development environment
Handles configuration parsing, validation, and defaults
"""

# Load required modules at top level (required by Starlark)
load('error_handling.star', 'warn_configuration_issue')

def parse_tilt_config():
    """Parse and validate Tilt configuration with sensible defaults and service customization support"""
    
    # Define configuration schema with proper Tilt config syntax
    # Only enable_services should be positional (args=True), all others are named flags
    config.define_string_list("enable_services", args=True, usage="List of services to deploy")
    config.define_string("developer_id", args=False, usage="Developer identifier for namespace isolation")
    config.define_string("cluster_type", args=False, usage="Local cluster type: kind|k3d|docker-desktop")
    config.define_bool("enable_debug", args=False, usage="Enable debug mode with verbose logging")
    config.define_string_list("build_local", args=False, usage="List of services to build locally instead of using ECR")
    config.define_string_list("disable_services", args=False, usage="List of services to disable (exclude from deployment)")
    config.define_string_list("ecr_versions", args=False, usage="ECR image versions in format service:version")
    config.define_string_list("env_overrides", args=False, usage="Environment variable overrides in format service:VAR=value")
    config.define_string("build_strategy", args=False, usage="Default build strategy: local|ecr|mixed")

    # Parse configuration
    cfg = config.parse()
    
    # Load developer configuration if available
    developer_config = _load_developer_config()
    
    # Parse ECR version specifications
    ecr_version_map = {}
    for version_spec in cfg.get("ecr_versions", []):
        if ":" in version_spec:
            service, version = version_spec.split(":", 1)
            ecr_version_map[service] = version
    
    # Parse environment variable overrides
    env_override_map = {}
    for env_spec in cfg.get("env_overrides", []):
        if ":" in env_spec and "=" in env_spec:
            service_part, env_part = env_spec.split(":", 1)
            if "=" in env_part:
                var_name, var_value = env_part.split("=", 1)
                if service_part not in env_override_map:
                    env_override_map[service_part] = {}
                env_override_map[service_part][var_name] = var_value
    
    # Build configuration object with defaults, merging developer config
    tilt_config = {
        "developer_id": cfg.get("developer_id", developer_config.get("developer_id", os.environ.get("USER", "dev"))),
        "services_to_deploy": cfg.get("enable_services", developer_config.get("services_to_deploy", [])),
        "debug_mode": cfg.get("enable_debug", developer_config.get("debug_mode", False)),
        "build_local_services": cfg.get("build_local", developer_config.get("build_local_services", [])),
        "disabled_services": cfg.get("disable_services", []),
        "ecr_versions": ecr_version_map,
        "env_overrides": env_override_map,
        "build_strategy": cfg.get("build_strategy", developer_config.get("build_strategy", "ecr")),
        "cluster_type": cfg.get("cluster_type", developer_config.get("cluster_type", "kind")),
    }
    
    # Add computed values
    tilt_config["developer_namespace"] = "dev-" + tilt_config["developer_id"]
    
    # Filter out disabled services from deployment list
    if tilt_config["disabled_services"]:
        original_services = tilt_config["services_to_deploy"]
        tilt_config["services_to_deploy"] = [
            svc for svc in original_services 
            if svc not in tilt_config["disabled_services"]
        ]
        if tilt_config["debug_mode"] and original_services != tilt_config["services_to_deploy"]:
            print("🚫 Disabled services: {}".format(tilt_config["disabled_services"]))
            print("📦 Filtered services: {} -> {}".format(original_services, tilt_config["services_to_deploy"]))
    
    return tilt_config

def load_service_config():
    """Load and validate service configuration from YAML with comprehensive error handling"""
    
    config_path = '.tilt/service-config.yaml'
    
    # Check if config file exists
    if not os.path.exists(config_path):
        fail("""
🚨 CONFIGURATION ERROR: Service configuration file not found

Missing file: {}

SETUP REQUIRED:
1. Create the service configuration file:
   cp .tilt/service-config.yaml.example .tilt/service-config.yaml

2. Or create a minimal configuration:
   mkdir -p .tilt
   echo 'services: {}' > .tilt/service-config.yaml
   echo 'global:' >> .tilt/service-config.yaml
   echo '  default_resources:' >> .tilt/service-config.yaml
   echo '    cpu: "100m"' >> .tilt/service-config.yaml
   echo '    memory: "128Mi"' >> .tilt/service-config.yaml

3. Add your services to the configuration file

DOCUMENTATION:
• See SERVICE_CONFIGURATION_GUIDE.md for detailed setup instructions
• Check existing service examples in the configuration file
• Refer to Tilt documentation for advanced configuration options

Cannot proceed without valid service configuration.
        """.format(config_path))
    
    # Read YAML configuration (Tilt will handle errors automatically)
    service_configs = read_yaml(config_path)
    
    # Validate required structure with detailed error messages
    if not type(service_configs) == "dict":
        fail("""
🚨 CONFIGURATION ERROR: Service configuration must be a YAML object

File: {}
Issue: Root level must be a dictionary/object, not {}

EXPECTED STRUCTURE:
services:
  service-name:
    type: "python"
    # ... service configuration
global:
  default_resources:
    cpu: "100m"
    memory: "128Mi"

FIX: Ensure the root level of your YAML file is a dictionary.
        """.format(config_path, type(service_configs)))

    if 'services' not in service_configs:
        fail("""
🚨 CONFIGURATION ERROR: Missing 'services' section

File: {}
Issue: Required 'services' section not found

REQUIRED STRUCTURE:
services:
  your-service-name:
    type: "python"
    build_context: "./your-service"
    ecr_image: "your-ecr-repo/your-service"
    ports: [8080]
global:
  # global configuration

FIX: Add a 'services' section to your configuration file.
        """.format(config_path))
    
    if 'global' not in service_configs:
        fail("""
🚨 CONFIGURATION ERROR: Missing 'global' section

File: {}
Issue: Required 'global' section not found

REQUIRED STRUCTURE:
services:
  # your services
global:
  default_resources:
    cpu: "100m"
    memory: "128Mi"
  default_health_check:
    initial_delay_seconds: 30
    period_seconds: 10

FIX: Add a 'global' section with default configuration values.
        """.format(config_path))
    
    # Validate services structure
    if not type(service_configs['services']) == "dict":
        fail("""
🚨 CONFIGURATION ERROR: Invalid 'services' section format

File: {}
Issue: 'services' must be a dictionary of service configurations

EXPECTED FORMAT:
services:
  service-1:
    type: "python"
    # configuration
  service-2:
    type: "java"
    # configuration

FIX: Ensure 'services' contains a dictionary of service configurations.
        """.format(config_path))
    
    return service_configs

def validate_services(services_to_deploy, service_configs):
    """Validate that all requested services exist in configuration and are properly configured"""
    
    available_services = set(service_configs.get('services', {}).keys())
    missing_services = [svc for svc in services_to_deploy if svc not in available_services]
    
    if missing_services:
        fail("""
🚨 SERVICE CONFIGURATION ERROR: Requested services not found

Missing services: {}
Available services: {}

RESOLUTION STEPS:
1. Check service names for typos in your command:
   tilt up -- --services={}

2. Add missing services to .tilt/service-config.yaml:
   services:
     {}:
       type: "python"  # or java, go, nodejs
       build_context: "./path-to-service"
       ecr_image: "your-ecr-repo/service-name"
       ports: [8080]

3. Or deploy only available services:
   tilt up -- --services={}

AVAILABLE SERVICES: {}
        """.format(
            missing_services,
            list(available_services),
            ','.join(services_to_deploy),
            missing_services[0] if missing_services else 'service-name',
            ','.join(available_services),
            ', '.join(available_services)
        ))
    
    # Validate service configurations (Tilt will handle errors automatically)
    for service_name in services_to_deploy:
        _validate_service_config(service_name, service_configs['services'][service_name])
    
    return True

def _validate_service_config(service_name, service_config):
    """Validate individual service configuration with comprehensive error reporting"""
    
    if not type(service_config) == "dict":
        fail("Configuration must be a dictionary, got {}".format(type(service_config)))

    # Check required fields based on service type
    service_type = service_config.get('type', '')

    if service_type == 'external':
        # External services (databases, etc.) require 'image' instead of 'build_context' and 'ecr_image'
        required_fields = ['type', 'image']
        missing_fields = [field for field in required_fields if field not in service_config]

        if missing_fields:
            fail("""Missing required fields for external service: {}

REQUIRED CONFIGURATION FOR EXTERNAL SERVICE:
{}:
  type: "external"         # Service type
  image: "postgres:15"     # Docker image reference
  ports: [5432]           # Optional: service ports
  dependencies: []        # Optional: service dependencies
  env_vars:               # Optional: environment variables
    - name: "VAR_NAME"
      value: "value"
            """.format(missing_fields, service_name))
    else:
        # Application services require 'build_context' and optionally 'ecr_image'
        # ECR image is only required if not building locally
        required_fields = ['type', 'build_context']
        missing_fields = [field for field in required_fields if field not in service_config]

        if missing_fields:
            fail("""Missing required fields for application service: {}

REQUIRED CONFIGURATION FOR APPLICATION SERVICE:
{}:
  type: "python"           # Service type
  build_context: "./path"  # Path to service code
  # ecr_image: "repo/name" # Optional: ECR image reference (required only if not building locally)
  ports: [8080]           # Optional: service ports
  dependencies: []        # Optional: service dependencies
            """.format(missing_fields, service_name))

    # Validate service type
    valid_types = ['python', 'java', 'go', 'nodejs', 'external', 'postgres', 'redis', 'mongodb', 'mysql', 'generic']
    if service_type not in valid_types:
        fail("""Invalid service type: '{}'

VALID TYPES:
• Application types: python, java, go, nodejs, generic
• External service type: external
• Legacy database types: postgres, redis, mongodb, mysql (use 'external' instead)

EXAMPLE:
{}:
  type: "python"  # Choose appropriate type
  # ... rest of configuration
        """.format(service_type, service_name))
    
    # Validate build_context exists (only for non-external services)
    if service_type != 'external' and 'build_context' in service_config:
        build_context = service_config['build_context']
        if not os.path.exists(build_context):
            # This is a warning, not a fatal error, as the path might be created later
            warn_configuration_issue(
                service_name,
                "Build context path '{}' does not exist".format(build_context),
                "Ensure the service code directory exists or will be created before deployment"
            )

    # Validate ports if specified
    if 'ports' in service_config:
        ports = service_config['ports']
        if not type(ports) == "list":
            fail("Ports must be a list, got {}. Example: ports: [8080, 8081]".format(type(ports)))

        # Check if all ports are integers
        invalid_ports = []
        for p in ports:
            if not type(p) == "int":
                invalid_ports.append(p)
        if invalid_ports:
            fail("All ports must be integers. Invalid ports: {}".format(invalid_ports))
        
        # Check for valid port ranges
        invalid_range_ports = []
        for p in ports:
            if p < 1 or p > 65535:
                invalid_range_ports.append(p)
        if invalid_range_ports:
            fail("Ports must be between 1 and 65535. Invalid ports: {}".format(invalid_range_ports))
        
        # Check for port conflicts within the service
        seen_ports = {}
        duplicate_ports = []
        for p in ports:
            if p in seen_ports:
                if p not in duplicate_ports:
                    duplicate_ports.append(p)
            else:
                seen_ports[p] = True
        if duplicate_ports:
            fail("Duplicate ports not allowed: {}".format(duplicate_ports))
    
    # Validate dependencies if specified
    if 'dependencies' in service_config:
        dependencies = service_config['dependencies']
        if not type(dependencies) == "list":
            fail("Dependencies must be a list, got {}. Example: dependencies: ['database', 'redis']".format(type(dependencies)))

        # Check if all dependencies are strings
        invalid_deps = []
        for dep in dependencies:
            if not type(dep) == "string":
                invalid_deps.append(dep)
        if invalid_deps:
            fail("All dependencies must be strings. Invalid dependencies: {}".format(invalid_deps))
    
    # Validate resources if specified
    if 'resources' in service_config:
        resources = service_config['resources']
        if not type(resources) == "dict":
            fail("Resources must be a dictionary. Example: resources: {cpu: '100m', memory: '128Mi'}")
        
        # Check for valid resource keys
        valid_resource_keys = ['cpu', 'memory', 'storage']
        invalid_keys = []
        for key in resources.keys():
            if key not in valid_resource_keys:
                invalid_keys.append(key)
        if invalid_keys:
            fail("Invalid resource keys: {}. Valid keys: {}".format(invalid_keys, valid_resource_keys))

def get_service_selection_info(service_configs):
    """Get information about available services for selection"""
    
    services = service_configs.get('services', {})
    service_info = {}
    
    for name, config in services.items():
        service_info[name] = {
            'type': config.get('type', 'unknown'),
            'ports': config.get('ports', []),
            'dependencies': config.get('dependencies', []),
            'has_ecr_image': bool(config.get('ecr_image')),
            'build_context': config.get('build_context', ''),
            'description': _generate_service_description(name, config)
        }
    
    return service_info

def _generate_service_description(name, config):
    """Generate a human-readable description of the service"""
    
    service_type = config.get('type', 'generic')
    ports = config.get('ports', [])
    deps = config.get('dependencies', [])
    
    desc = "{} service".format(service_type.title())
    
    if ports:
        desc += " (ports: {})".format(', '.join([str(p) for p in ports]))

    if deps:
        desc += " - depends on: {}".format(', '.join(deps))
    
    return desc

def create_service_selection_guide(service_configs):
    """Create a resource showing available services and selection options"""
    
    service_info = get_service_selection_info(service_configs)
    
    # Group services by type
    services_by_type = {}
    for name, info in service_info.items():
        svc_type = info['type']
        if svc_type not in services_by_type:
            services_by_type[svc_type] = []
        services_by_type[svc_type].append((name, info))
    
    local_resource(
        'service-selection-guide',
        cmd='''
        echo "=== SERVICE SELECTION GUIDE ==="
        echo "Available services in this repository:"
        echo ""
        
        ''' + '\n'.join([
            '''
        echo "=== {} Services ==="
        {}
        echo ""'''.format(
                svc_type.upper(),
                '\n        '.join([
                    'echo "  - {}: {}"'.format(name, info['description'])
                    for name, info in services
                ])
            ) for svc_type, services in services_by_type.items()
        ]) + '''
        
        echo "=== USAGE EXAMPLES ==="
        echo "Deploy specific services:"
        echo "  tilt up -- --services=database,redis,ai-agentic-mdr-oscar"
        echo ""
        echo "Build services locally:"
        echo "  tilt up -- --services=ai-agentic-mdr-oscar --build_local=ai-agentic-mdr-oscar"
        echo ""
        echo "Deploy with debug mode:"
        echo "  tilt up -- --services=database,ai-agentic-mdr-oscar --enable_debug=true"
        echo ""
        echo "=== SERVICE CUSTOMIZATION ==="
        echo "Disable specific services:"
        echo "  tilt up -- --services=database,redis,app1,app2 --disable_services=app2"
        echo ""
        echo "Use specific ECR versions:"
        echo "  tilt up -- --services=app1,app2 --ecr_versions=app1:v1.2.3,app2:latest"
        echo ""
        echo "Override environment variables:"
        echo "  tilt up -- --services=app1 --env_overrides=app1:LOG_LEVEL=DEBUG,app1:PORT=9000"
        echo ""
        echo "Set build strategy:"
        echo "  tilt up -- --services=app1,app2 --build_strategy=local"
        echo "  tilt up -- --services=app1,app2 --build_strategy=mixed --build_local=app1"
        echo ""
        echo "=== SERVICE DEPENDENCIES ==="
        ''' + '\n'.join([
            'echo "{}: {}"'.format(name, ', '.join(info['dependencies']) if info['dependencies'] else 'No dependencies')
            for name, info in service_info.items()
        ]) + '''
        ''',
        deps=[],
        labels=['guide', 'service-selection'],
        auto_init=True
    )

def apply_service_customizations(service_name, service_config, tilt_config):
    """Apply service-specific customizations from Tilt configuration"""
    
    customized_config = dict(service_config)  # Create a copy
    
    # Apply ECR version overrides
    if service_name in tilt_config.get("ecr_versions", {}):
        ecr_base = customized_config.get("ecr_image", "")
        if ":" in ecr_base:
            ecr_base = ecr_base.split(":")[0]  # Remove existing tag
        new_version = tilt_config["ecr_versions"][service_name]
        customized_config["ecr_image"] = "{}:{}".format(ecr_base, new_version)
        
        if tilt_config.get("debug_mode", False):
            print("🏷️  Applied ECR version override for {}: {}".format(service_name, new_version))
    
    # Apply environment variable overrides
    if service_name in tilt_config.get("env_overrides", {}):
        env_vars = list(customized_config.get("env_vars", []))
        overrides = tilt_config["env_overrides"][service_name]
        
        # Create a map of existing env vars for easy lookup
        env_var_map = {}
        for i, env_var in enumerate(env_vars):
            if type(env_var) == "dict" and "name" in env_var:
                env_var_map[env_var["name"]] = i
        
        # Apply overrides
        for var_name, var_value in overrides.items():
            if var_name in env_var_map:
                # Update existing variable
                env_vars[env_var_map[var_name]]["value"] = var_value
            else:
                # Add new variable
                env_vars.append({"name": var_name, "value": var_value})
        
        customized_config["env_vars"] = env_vars
        
        if tilt_config.get("debug_mode", False):
            print("🔧 Applied env overrides for {}: {}".format(service_name, list(overrides.keys())))
    
    # Apply build strategy customizations
    build_strategy = tilt_config.get("build_strategy", "ecr")
    if build_strategy == "local":
        # Force all services to build locally
        customized_config["_force_local_build"] = True
    elif build_strategy == "ecr":
        # Force all services to use ECR (default behavior)
        customized_config["_force_ecr_build"] = True
    # "mixed" strategy uses the existing build_local_services list
    
    return customized_config

def get_effective_build_strategy(service_name, service_config, tilt_config):
    """Determine the effective build strategy for a service"""
    
    # Check for forced strategies from build_strategy setting
    if service_config.get("_force_local_build", False):
        return "local"
    elif service_config.get("_force_ecr_build", False):
        return "ecr"
    
    # Check explicit build_local list
    if service_name in tilt_config.get("build_local_services", []):
        return "local"
    
    # Default to ECR
    return "ecr"

def _load_developer_config():
    """Load developer configuration from YAML file with fallback to defaults"""
    
    config_path = '.tilt/developer-config.yaml'
    
    # Return empty config if file doesn't exist
    if not os.path.exists(config_path):
        return {}
    
    # Read developer configuration (return empty dict if file has issues)
    dev_config = read_yaml(config_path)
    
    # Extract and flatten configuration
    result = {}
    
    if 'developer' in dev_config and 'id' in dev_config['developer']:
        result['developer_id'] = dev_config['developer']['id']
    
    if 'cluster' in dev_config and 'type' in dev_config['cluster']:
        result['cluster_type'] = dev_config['cluster']['type']
    
    if 'services' in dev_config:
        services_config = dev_config['services']
        if 'enabled' in services_config:
            result['services_to_deploy'] = services_config['enabled']
        if 'build_locally' in services_config:
            result['build_local_services'] = services_config['build_locally']
    
    if 'preferences' in dev_config:
        prefs = dev_config['preferences']
        if 'debug_mode' in prefs:
            result['debug_mode'] = prefs['debug_mode']
    
    return result

def create_service_customization_dashboard(tilt_config, service_configs):
    """Create a dashboard showing current service customizations"""
    
    local_resource(
        'service-customization-dashboard',
        cmd='''
        echo "🎛️  SERVICE CUSTOMIZATION DASHBOARD"
        echo "=================================="
        echo "Developer: ''' + tilt_config.get("developer_id", "unknown") + '''"
        echo "Build Strategy: ''' + tilt_config.get("build_strategy", "ecr") + '''"
        echo ""
        
        ''' + ('''
        echo "🚫 DISABLED SERVICES"
        echo "-------------------"
        ''' + '\n        '.join([
            'echo "  - {}"'.format(svc) for svc in tilt_config.get("disabled_services", [])
        ]) + '''
        echo ""
        ''' if tilt_config.get("disabled_services") else '') + '''
        
        ''' + ('''
        echo "🏷️  ECR VERSION OVERRIDES"
        echo "------------------------"
        ''' + '\n        '.join([
            'echo "  - {}: {}"'.format(svc, version) 
            for svc, version in tilt_config.get("ecr_versions", {}).items()
        ]) + '''
        echo ""
        ''' if tilt_config.get("ecr_versions") else '') + '''
        
        ''' + ('''
        echo "🔧 ENVIRONMENT OVERRIDES"
        echo "-----------------------"
        ''' + '\n        '.join([
            'echo "  - {}:"'.format(svc) + '\n        ' + '\n        '.join([
                'echo "    {}: {}"'.format(var, value) 
                for var, value in overrides.items()
            ]) for svc, overrides in tilt_config.get("env_overrides", {}).items()
        ]) + '''
        echo ""
        ''' if tilt_config.get("env_overrides") else '') + '''
        
        ''' + ('''
        echo "🔨 LOCAL BUILD SERVICES"
        echo "----------------------"
        ''' + '\n        '.join([
            'echo "  - {}"'.format(svc) for svc in tilt_config.get("build_local_services", [])
        ]) + '''
        echo ""
        ''' if tilt_config.get("build_local_services") else '') + '''
        
        echo "💡 CUSTOMIZATION COMMANDS"
        echo "========================"
        echo "Disable services:"
        echo "  tilt up -- --services=app1,app2,app3 --disable_services=app3"
        echo ""
        echo "Override ECR versions:"
        echo "  tilt up -- --ecr_versions=app1:v1.2.3,app2:latest"
        echo ""
        echo "Override environment variables:"
        echo "  tilt up -- --env_overrides=app1:LOG_LEVEL=DEBUG,app1:PORT=9000"
        echo ""
        echo "Set build strategy:"
        echo "  tilt up -- --build_strategy=local  # Build all locally"
        echo "  tilt up -- --build_strategy=mixed --build_local=app1  # Mixed strategy"
        ''',
        deps=[],
        labels=['customization', 'dashboard', 'configuration'],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL
    )
