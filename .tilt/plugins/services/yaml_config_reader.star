"""
YAML Configuration Reader Plugin
Reads service configurations from service-config.yaml and dynamically implements
the service interface based on the service type.

This replaces ALL hardcoded service-specific .star files with a single
configuration-driven approach that maps service types to Tilt patterns.
"""

def read_service_config_yaml():
    """Read service-config.yaml to get all service configurations."""
    service_config_file = ".tilt/service-config.yaml"
    
    # Check if file exists
    file_check = str(local("test -f " + service_config_file + " && echo 'exists' || echo 'missing'", quiet=True))
    if file_check.strip() != "exists":
        print("Warning: service-config.yaml not found")
        return {}
    
    # Read the file content
    file_content = str(local("cat " + service_config_file, quiet=True))
    if not file_content or file_content.strip() == "":
        print("Warning: service-config.yaml is empty")
        return {}
    
    # Parse YAML - simplified for service structure
    return _parse_service_config_simple(file_content)

def _parse_service_config_simple(content):
    """Simple YAML parser for service-config.yaml structure."""
    services = {}
    lines = content.split('\n')
    current_service = None
    current_section = None
    in_services_section = False
    
    for line_raw in lines:
        line = line_raw.rstrip()
        if not line.strip() or line.strip().startswith('#'):
            continue
        
        # Check if we're entering the services section
        if line.startswith('services:'):
            in_services_section = True
            continue
            
        # Check if we're leaving the services section
        if line.startswith('global:') or (line and not line.startswith(' ') and line != 'services:'):
            in_services_section = False
            continue
            
        # Only process lines inside the services section
        if not in_services_section:
            continue
            
        # Check if this is a service definition (2 spaces, ends with colon)
        if line.startswith('  ') and line.endswith(':') and not line.startswith('    '):
            current_service = line[2:].replace(':', '').strip()
            services[current_service] = {}
            current_section = None
            continue
            
        # Parse service properties (4 spaces)
        if current_service and line.startswith('    ') and ':' in line:
            key_value = line[4:].split(':', 1)
            if len(key_value) == 2:
                key = key_value[0].strip()
                value = key_value[1].strip()
                
                # Handle different value types
                if key == "type":
                    services[current_service]["type"] = value.strip('"\'')
                elif key == "image":
                    services[current_service]["image"] = value.strip('"\'')
                elif key == "ports":
                    # Parse ports array [8000] or [5432, 5433]
                    if value.startswith('[') and value.endswith(']'):
                        ports_str = value[1:-1]
                        ports = [int(p.strip()) for p in ports_str.split(',') if p.strip()]
                        services[current_service]["ports"] = ports
                elif key == "dependencies":
                    # Parse dependencies array ["database", "redis"]
                    if value.startswith('[') and value.endswith(']'):
                        deps_str = value[1:-1]
                        deps = [d.strip().strip('"\'') for d in deps_str.split(',') if d.strip()]
                        services[current_service]["dependencies"] = deps
    
    return {"services": services}

def get_all_services():
    """Get all services from service-config.yaml."""
    config = read_service_config_yaml()
    return config.get("services", {})

def create_service_plugin(service_name):
    """
    Create a dynamic service plugin for the specified service.
    This reads service-config.yaml and creates appropriate interface based on service type.
    """
    all_services = get_all_services()
    service_config = all_services.get(service_name, {})
    
    if not service_config:
        fail("Service '{}' not found in service-config.yaml. Available: {}".format(
            service_name, ", ".join(all_services.keys())
        ))
    
    service_type = service_config.get("type", "unknown")
    
    return struct(
        get_service_info=lambda: _get_service_info_impl(service_name, service_config),
        validate_config=lambda config: _validate_config_impl(service_config, config),
        get_default_config=lambda: _get_default_config_impl(service_config),
        create_deployment_manifest=lambda name, config, ns: _create_deployment_manifest_impl(service_config, name, config, ns),
        get_health_check_config=lambda config: _get_health_check_config_impl(service_config, config),
        supports_live_updates=lambda: _supports_live_updates_impl(service_config)
    )

def _get_service_info_impl(service_name, service_config):
    """Generic service info based on configuration."""
    service_type = service_config.get("type", "unknown")
    ports = service_config.get("ports", [])
    image = service_config.get("image", "")
    
    return {
        "name": service_name.title() + " Service",
        "description": "{} service of type '{}'".format(service_name, service_type),
        "supported_platforms": ["linux", "darwin", "windows"],
        "default_port": ports[0] if ports else 8080,
        "file_extensions": _get_file_extensions_for_type(service_type)
    }

def _get_file_extensions_for_type(service_type):
    """Map service type to relevant file extensions."""
    type_extensions = {
        "python": [".py", ".pyx", ".pyi"],
        "java": [".java", ".jar", ".war"],
        "nodejs": [".js", ".ts", ".json"],
        "go": [".go", ".mod", ".sum"],
        "external": []  # External services don't have source files
    }
    return type_extensions.get(service_type, [])

def _validate_config_impl(service_config, config):
    """Generic validation based on service configuration."""
    errors = []
    warnings = []
    
    service_type = service_config.get("type", "")
    expected_image = service_config.get("image", "")
    expected_ports = service_config.get("ports", [])
    
    # Validate type consistency
    if config.get("type") != service_type:
        errors.append("Service type mismatch: expected '{}', got '{}'".format(
            service_type, config.get("type", "unknown")
        ))
    
    # For external services, validate image is specified
    if service_type == "external" and not expected_image:
        errors.append("External services require 'image' field in service-config.yaml")
    
    # Validate ports if specified
    if expected_ports and config.get("ports") != expected_ports:
        warnings.append("Port configuration differs from service-config.yaml")
    
    return {
        "valid": len(errors) == 0,
        "errors": errors,
        "warnings": warnings
    }

def _get_default_config_impl(service_config):
    """Generate default config from service-config.yaml."""
    return {
        "type": service_config.get("type", "unknown"),
        "image": service_config.get("image", ""),
        "ports": service_config.get("ports", [8080]),
        "dependencies": service_config.get("dependencies", [])
    }

def _create_deployment_manifest_impl(service_config, name, config, namespace):
    """Generate deployment manifest based on service type and config."""
    service_type = service_config.get("type", "unknown")
    
    # Use config overrides if provided
    effective_image = config.get("image") if config else service_config.get("image", "")
    effective_ports = config.get("ports") if config else service_config.get("ports", [])
    
    base_manifest = ""
    if service_type == "external":
        base_manifest = "# External service deployment for {} in namespace {}".format(name, namespace)
    elif service_type == "python":
        base_manifest = "# Python service deployment for {} in namespace {}".format(name, namespace)
    elif service_type == "java":
        base_manifest = "# Java service deployment for {} in namespace {}".format(name, namespace)
    elif service_type == "nodejs":
        base_manifest = "# Node.js service deployment for {} in namespace {}".format(name, namespace)
    elif service_type == "go":
        base_manifest = "# Go service deployment for {} in namespace {}".format(name, namespace)
    else:
        base_manifest = "# Generic service deployment for {} in namespace {}".format(name, namespace)
    
    # Add config details if provided
    if effective_image:
        base_manifest += "\n# Image: {}".format(effective_image)
    if effective_ports:
        base_manifest += "\n# Ports: {}".format(effective_ports)
    
    return base_manifest

def _get_health_check_config_impl(service_config, config):
    """Generate health check config from service configuration."""
    ports = service_config.get("ports", [8080])
    service_type = service_config.get("type", "unknown")
    
    # Allow config overrides if provided
    config_port = config.get("port") if config else None
    config_path = config.get("path") if config else None
    
    # Default health check patterns by service type
    if service_type == "python":
        return {"path": config_path or "/health", "port": config_port or ports[0]}
    elif service_type == "java":
        return {"path": config_path or "/actuator/health", "port": config_port or ports[0]}
    elif service_type == "nodejs":
        return {"path": config_path or "/health", "port": config_port or ports[0]}
    elif service_type == "go":
        return {"path": config_path or "/health", "port": config_port or ports[0]}
    elif service_type == "external":
        # External services use custom health checks defined in config
        return {"port": config_port or ports[0]}
    else:
        return {"path": config_path or "/health", "port": config_port or ports[0]}

def _supports_live_updates_impl(service_config):
    """Determine if service supports live updates based on type."""
    service_type = service_config.get("type", "unknown")
    
    # Live updates are supported for services with source code
    live_update_types = ["python", "nodejs", "go", "java"]
    return service_type in live_update_types

# Export the factory function for dynamic service creation
def get_service_plugin(service_name):
    """
    Public API: Get a service plugin for any service defined in service-config.yaml
    This is the main entry point for creating service plugins dynamically.
    """
    return create_service_plugin(service_name)

def get_available_services():
    """Get list of all available service names from service-config.yaml."""
    all_services = get_all_services()
    return list(all_services.keys())

def get_services_by_type(service_type):
    """Get all services of a specific type."""
    all_services = get_all_services()
    services_of_type = []
    for service_name, service_config in all_services.items():
        if service_config.get("type") == service_type:
            services_of_type.append(service_name)
    return services_of_type