"""
YAML Environment Loader Plugin
Minimal YAML-to-Tilt mapper that reads configurations and uses Tilt's native capabilities.

YAML Files:
- environments.yaml: defines which services to deploy for each environment
- service-config.yaml: defines service configurations (types, dependencies, ports)

This plugin reads YAML and maps to Tilt's built-in patterns - no reimplementation.
"""

def read_environments_yaml():
    """
    Dynamically read and parse .tilt/environments.yaml using external tools.
    Returns the environments configuration or empty dict if not found.
    """
    environments_file = ".tilt/environments.yaml"
    
    # Check if file exists first
    file_check = str(local("test -f " + environments_file + " && echo 'exists' || echo 'missing'", quiet=True))
    if file_check.strip() != "exists":
        print("Warning: environments.yaml not found")
        return {}
    
    # Read the file content
    file_content = str(local("cat " + environments_file, quiet=True))
    if not file_content or file_content.strip() == "":
        print("Warning: environments.yaml is empty")
        return {}
    
    # Try to parse using yq if available
    yq_check = str(local("command -v yq >/dev/null 2>&1 && echo 'available' || echo 'missing'", quiet=True))
    if yq_check.strip() == "available":
        yq_result = str(local("yq eval '.environments' " + environments_file, quiet=True))
        if yq_result and yq_result.strip() != "null" and yq_result.strip() != "":
            # For now, fall back to simple parsing since yq output parsing is complex
            pass
    
    # Use simple YAML parsing for basic structure
    return _parse_environments_simple(file_content)


def _parse_environments_simple(content):
    """
    Simple YAML parser for environments.yaml structure.
    Only handles the basic structure we need.
    """
    environments = {}
    lines = content.split('\n')
    current_env = None
    current_section = None
    in_environments_section = False
    
    for line_raw in lines:
        line = line_raw.rstrip()  # Keep leading spaces for indentation detection
        if not line.strip() or line.strip().startswith('#'):
            continue
        
        # Check if we're entering the environments section
        if line.startswith('environments:'):
            in_environments_section = True
            continue
            
        # Check if we're leaving the environments section
        if line.startswith('global:') or (line and not line.startswith(' ') and line != 'environments:'):
            in_environments_section = False
            continue
            
        # Only process lines inside the environments section
        if not in_environments_section:
            continue
            
        # Check if this is an environment definition (2 spaces, ends with colon)
        if line.startswith('  ') and line.endswith(':') and not line.startswith('    '):
            # This is an environment name
            current_env = line[2:].replace(':', '').strip()  # Remove indentation and colon
            environments[current_env] = {"services": []}
            current_section = None
            continue
            
        # Check for description (4 spaces)
        if current_env and line.startswith('    description:'):
            desc = line.split('description:')[1].strip().strip('"\'')
            environments[current_env]["description"] = desc
            continue
            
        # Check for services section (4 spaces)
        if current_env and line.startswith('    services:'):
            current_section = "services"
            continue
            
        # Parse services array on same line (4 spaces + services: ["item1", "item2"])
        if current_env and line.startswith('    services:') and '[' in line:
            services_text = line.split('services:')[1].strip()
            # Simple array parsing - remove brackets and quotes, split by comma
            if services_text.startswith('[') and services_text.endswith(']'):
                services_text = services_text[1:-1]  # Remove brackets
                services_raw = services_text.split(',')
                services = []
                for s in services_raw:
                    stripped = s.strip().strip('"\'')
                    if stripped:
                        services.append(stripped)
                environments[current_env]["services"] = services
            continue
    
    return {"environments": environments}

def get_available_environments():
    """
    Dynamically get list of all available environment names from environments.yaml
    """
    config = read_environments_yaml()
    return list(config.get("environments", {}).keys())

def get_environment_config(environment_name):
    """
    Dynamically get configuration for a specific environment from environments.yaml
    """
    config = read_environments_yaml()
    environments = config.get("environments", {})
    return environments.get(environment_name, {})

def create_environment_plugin(environment_name):
    """
    Create a dynamic environment plugin for the specified environment.
    This reads from environments.yaml and returns an object implementing the environment interface.
    """
    env_config = get_environment_config(environment_name)
    
    if not env_config:
        available_envs = get_available_environments()
        fail("Environment '{}' not found in environments.yaml. Available: {}".format(
            environment_name, ", ".join(available_envs)
        ))
    
    return struct(
        get_environment_info=lambda: _get_environment_info_impl(environment_name, env_config),
        get_service_list=lambda: _get_service_list_impl(env_config),
        validate_environment_config=lambda available_services: _validate_environment_config_impl(env_config, available_services),
        get_deployment_order=lambda: _get_deployment_order_impl(env_config)
    )

def _get_environment_info_impl(environment_name, env_config):
    """Implementation of get_environment_info - minimal generic metadata."""
    description = env_config.get("description", environment_name.title() + " Environment")
    services = env_config.get("services", [])
    
    # Generic metadata based only on configuration data
    use_cases = ["Environment with {} services: {}".format(len(services), ", ".join(services))]
    
    # Simple resource estimation based on service count only
    service_count = len(services)
    if service_count <= 1:
        estimated_resources = "Low (1-2 GB RAM, 0.5-1 CPU core)"
    elif service_count <= 3:
        estimated_resources = "Medium (2-4 GB RAM, 1-2 CPU cores)"
    else:
        estimated_resources = "High (4+ GB RAM, 2+ CPU cores)"
    
    return {
        "name": description,
        "description": description,
        "use_cases": use_cases,
        "estimated_resources": estimated_resources
    }

def _get_service_list_impl(env_config):
    """Implementation of get_service_list for any environment - reads from YAML."""
    return env_config.get("services", [])

def _validate_environment_config_impl(env_config, available_services):
    """Implementation of validate_environment_config for any environment - generic logic."""
    required_services = env_config.get("services", [])
    missing_services = []
    warnings = []
    
    # Check for missing services
    for service in required_services:
        if service not in available_services:
            missing_services.append(service)
    
    # Check for unused available services (informational)
    unused_services = []
    for svc in available_services:
        if svc not in required_services:
            unused_services.append(svc)
    if len(unused_services) > 0 and len(unused_services) <= 5:
        warnings.append("Available services not used in this environment: {}".format(
            ", ".join(unused_services)
        ))
    elif len(unused_services) > 5:
        warnings.append("Many available services not used in this environment ({} total)".format(
            len(unused_services)
        ))
    
    errors = []
    if len(missing_services) > 0:
        errors.append("Missing required services for environment")
    
    return {
        "valid": len(missing_services) == 0,
        "errors": errors,
        "warnings": warnings,
        "missing_services": missing_services
    }

def read_service_config_yaml():
    """Read service-config.yaml to get service configurations and dependencies."""
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
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
            
        # Check if this is a service definition
        if line.startswith('  ') and line.endswith(':') and not line.startswith('    '):
            current_service = line.replace(':', '').strip()
            services[current_service] = {"dependencies": []}
            current_section = None
            continue
            
        # Parse dependencies section
        if current_service and line.startswith('    dependencies:'):
            current_section = "dependencies"
            continue
            
        # Parse dependency list items
        if current_service and current_section == "dependencies" and line.startswith('      - '):
            dep = line.replace('- ', '').strip().strip('"\'[]')
            if dep:
                services[current_service]["dependencies"].append(dep)
            continue
    
    return {"services": services}

def _get_deployment_order_impl(env_config):
    """Implementation using Tilt's native dependency system - read from service-config.yaml."""
    services = env_config.get("services", [])
    service_config = read_service_config_yaml()
    service_deps = service_config.get("services", {})
    
    # Use topological sort based on actual dependencies from service-config.yaml
    # This respects Tilt's resource_deps pattern
    deployment_phases = []
    remaining_services = list(services)
    deployed_services = []
    
    # Iteratively build deployment phases (Starlark doesn't support while loops)
    max_iterations = len(services) + 1  # Prevent infinite loops
    for iteration in range(max_iterations):
        if not remaining_services:
            break
            
        # Find services with no undeployed dependencies
        ready_services = []
        for service in remaining_services:
            service_config_entry = service_deps.get(service, {})
            dependencies = service_config_entry.get("dependencies", [])
            
            # Check if all dependencies are already deployed
            unmet_deps = []
            for dep in dependencies:
                if dep in services and dep not in deployed_services:
                    unmet_deps.append(dep)
            if not unmet_deps:
                ready_services.append(service)
        
        # If no services are ready but we still have remaining services, there might be a cycle
        # Deploy them anyway (Tilt will handle the dependencies)
        if not ready_services and remaining_services:
            ready_services = list(remaining_services)
        
        if ready_services:
            deployment_phases.append(ready_services)
            for service in ready_services:
                remaining_services.remove(service)
                deployed_services.append(service)
        else:
            # No progress possible, break to prevent infinite loop
            break
    
    return deployment_phases

# Export the factory function for dynamic environment creation
def get_environment_plugin(environment_name):
    """
    Public API: Get an environment plugin for any environment defined in environments.yaml
    This is the main entry point for creating environment plugins dynamically.
    """
    return create_environment_plugin(environment_name)