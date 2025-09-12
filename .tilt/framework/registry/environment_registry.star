"""
Environment Registry
Central registry for environment plugins with discovery and validation
"""

# Load interface definitions
load('../interfaces/environment.star', 'create_environment_interface')

# Global registry to store registered environment plugins
_environment_plugins = {}
_environment_interface = create_environment_interface()


def get_registered_environments():
    """
    Get list of all registered environment names.
    
    Returns:
        list: List of registered environment names
    """
    return list(_environment_plugins.keys())

def get_environment_plugin(environment_name):
    """
    Get a registered environment plugin by name.
    
    Args:
        environment_name (str): The environment identifier
        
    Returns:
        dict: Plugin information, or None if not found
    """
    return _environment_plugins.get(environment_name)

def is_environment_supported(environment_name):
    """
    Check if an environment is supported (registered).
    
    Args:
        environment_name (str): The environment identifier
        
    Returns:
        bool: True if environment is supported
    """
    return environment_name in _environment_plugins

def get_environment_services(environment_name):
    """
    Get the list of services for an environment.
    
    Args:
        environment_name (str): The environment identifier
        
    Returns:
        list: List of service names, or empty list if environment not found
    """
    plugin = get_environment_plugin(environment_name)
    if not plugin:
        return []
    
    return plugin["module"].get_service_list()

def validate_environment(environment_name, available_services):
    """
    Validate an environment against available services.
    
    Args:
        environment_name (str): The environment identifier
        available_services (list): List of available service names
        
    Returns:
        dict: Validation result from plugin
    """
    plugin = get_environment_plugin(environment_name)
    if not plugin:
        return {
            "valid": False,
            "errors": ["Unsupported environment: {}".format(environment_name)],
            "warnings": [],
            "missing_services": []
        }
    
    return plugin["module"].validate_environment_config(available_services)

def get_deployment_order(environment_name):
    """
    Get service deployment order for an environment.
    
    Args:
        environment_name (str): The environment identifier
        
    Returns:
        list: Deployment order, or empty list if environment not found
    """
    plugin = get_environment_plugin(environment_name)
    if not plugin:
        return []
    
    return plugin["module"].get_deployment_order()

def get_environment_variables(environment_name):
    """
    Get global environment variables for an environment.
    
    Args:
        environment_name (str): The environment identifier
        
    Returns:
        dict: Environment variables, or empty dict if environment not found
    """
    plugin = get_environment_plugin(environment_name)
    if not plugin:
        return {}
    
    # Check if plugin implements optional function
    if hasattr(plugin["module"], "get_environment_variables"):
        return plugin["module"].get_environment_variables()
    
    return {}

def get_registry_status():
    """
    Get status information about the environment registry.
    
    Returns:
        dict: Registry status information
    """
    return {
        "total_environments": len(_environment_plugins),
        "registered_environments": list(_environment_plugins.keys()),
        "interface_version": _environment_interface["version"],
        "environments": {
            env_name: {
                "name": info["info"].get("name", env_name),
                "description": info["info"].get("description", "No description"),
                "use_cases": info["info"].get("use_cases", []),
                "estimated_resources": info["info"].get("estimated_resources", "Unknown"),
                "service_count": len(info["module"].get_service_list())
            }
            for env_name, info in _environment_plugins.items()
        }
    }

def _validate_plugin_interface(plugin_module):
    """
    Validate that a plugin module implements the required interface functions.
    
    Args:
        plugin_module (module): The plugin module to validate
        
    Returns:
        dict: Validation result with 'valid' boolean and 'missing_functions' list
    """
    required_functions = _environment_interface["required_functions"]
    missing_functions = []
    
    for func_name in required_functions:
        if not hasattr(plugin_module, func_name):
            missing_functions.append(func_name)
    
    return {
        "valid": len(missing_functions) == 0,
        "missing_functions": missing_functions
    }

def create_environment_registry_dashboard():
    """
    Create a Tilt dashboard resource showing environment registry status.
    """
    status = get_registry_status()
    
    env_list = []
    for env_name, env_info in status["environments"].items():
        use_cases = ", ".join(env_info["use_cases"]) if env_info["use_cases"] else "General"
        env_list.append("  • {} - {} ({} services)\\n    Use Cases: {}\\n    Resources: {}".format(
            env_name,
            env_info["name"],
            env_info["service_count"],
            use_cases,
            env_info["estimated_resources"]
        ))
    
    dashboard_cmd = '''echo "🌍 ENVIRONMENT REGISTRY
======================
Total Environments: {}
Interface Version: {}

Registered Environments:
{}

💡 Environments define service groupings and deployment strategies"'''.format(
        status["total_environments"],
        status["interface_version"],
        "\\n".join(env_list) if env_list else "  (No environments registered)"
    )
    
    local_resource(
        'environment-registry-dashboard',
        cmd=dashboard_cmd,
        labels=['framework', 'monitoring']
    )