"""
Service Registry
Central registry for service plugins with discovery and validation
"""

# Load interface definitions
load('../interfaces/service.star', 'create_service_interface')

# Global registry to store registered service plugins
_service_plugins = {}
_service_interface = create_service_interface()

# Flag to track if registry is initialized
_registry_initialized = False

def register_service_plugin(service_type, plugin_module):
    """
    Register a service plugin with the registry.
    
    Args:
        service_type (str): The service type identifier (e.g., 'python', 'java')
        plugin_module (module): The loaded plugin module
    """
    
    # Validate that plugin implements required interface functions
    validation_result = _validate_plugin_interface(plugin_module)
    
    if not validation_result["valid"]:
        fail("Service plugin '{}' does not implement required interface: {}".format(
            service_type, ", ".join(validation_result["missing_functions"])
        ))
    
    # Register the plugin
    _service_plugins[service_type] = {
        "type": service_type,
        "module": plugin_module,
        "info": plugin_module.get_service_info(),
        "registered_at": "startup",
        "interface_version": _service_interface["version"]
    }
    
    print("✅ Registered service plugin: {}".format(service_type))

def get_registered_service_types():
    """
    Get list of all registered service types.
    
    Returns:
        list: List of registered service type names
    """
    return list(_service_plugins.keys())

def get_service_plugin(service_type):
    """
    Get a registered service plugin by type.
    
    Args:
        service_type (str): The service type identifier
        
    Returns:
        dict: Plugin information, or None if not found
    """
    return _service_plugins.get(service_type)

def is_service_type_supported(service_type):
    """
    Check if a service type is supported (registered).
    
    Args:
        service_type (str): The service type identifier
        
    Returns:
        bool: True if service type is supported
    """
    return service_type in _service_plugins

def validate_service_config(service_type, config):
    """
    Validate service configuration using the registered plugin.
    
    Args:
        service_type (str): The service type identifier
        config (dict): Service configuration to validate
        
    Returns:
        dict: Validation result from plugin
    """
    plugin = get_service_plugin(service_type)
    if not plugin:
        return {
            "valid": False,
            "errors": ["Unsupported service type: {}".format(service_type)],
            "warnings": []
        }
    
    return plugin["module"].validate_config(config)

def get_service_default_config(service_type):
    """
    Get default configuration for a service type.
    
    Args:
        service_type (str): The service type identifier
        
    Returns:
        dict: Default configuration, or empty dict if service type not found
    """
    plugin = get_service_plugin(service_type)
    if not plugin:
        return {}
    
    return plugin["module"].get_default_config()

def create_service_deployment(service_name, service_type, config, namespace):
    """
    Create service deployment using the registered plugin.
    
    Args:
        service_name (str): Name of the service
        service_type (str): The service type identifier
        config (dict): Service configuration
        namespace (str): Kubernetes namespace
        
    Returns:
        str: Deployment manifest YAML
    """
    plugin = get_service_plugin(service_type)
    if not plugin:
        fail("Cannot create deployment for unsupported service type: {}".format(service_type))
    
    return plugin["module"].create_deployment_manifest(service_name, config, namespace)

def get_service_health_check(service_type, config):
    """
    Get health check configuration for a service type.
    
    Args:
        service_type (str): The service type identifier
        config (dict): Service configuration
        
    Returns:
        dict: Health check configuration
    """
    plugin = get_service_plugin(service_type)
    if not plugin:
        return {
            "path": "/health",
            "port": 8080,
            "initial_delay_seconds": 30,
            "period_seconds": 10
        }
    
    return plugin["module"].get_health_check_config(config)

def service_supports_live_updates(service_type):
    """
    Check if a service type supports live updates.
    
    Args:
        service_type (str): The service type identifier
        
    Returns:
        bool: True if service type supports live updates
    """
    plugin = get_service_plugin(service_type)
    if not plugin:
        return False
    
    return plugin["module"].supports_live_updates()

def get_registry_status():
    """
    Get status information about the service registry.
    
    Returns:
        dict: Registry status information
    """
    return {
        "total_plugins": len(_service_plugins),
        "registered_types": list(_service_plugins.keys()),
        "interface_version": _service_interface["version"],
        "plugins": {
            service_type: {
                "name": info["info"].get("name", service_type),
                "description": info["info"].get("description", "No description"),
                "supported_platforms": info["info"].get("supported_platforms", []),
                "live_updates_supported": info["module"].supports_live_updates()
            }
            for service_type, info in _service_plugins.items()
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
    required_functions = _service_interface["required_functions"]
    missing_functions = []
    
    for func_name in required_functions:
        if not hasattr(plugin_module, func_name):
            missing_functions.append(func_name)
    
    return {
        "valid": len(missing_functions) == 0,
        "missing_functions": missing_functions
    }

def create_registry_dashboard():
    """
    Create a Tilt dashboard resource showing registry status.
    """
    status = get_registry_status()
    
    plugin_list = []
    for service_type, plugin_info in status["plugins"].items():
        live_updates = "✅" if plugin_info["live_updates_supported"] else "❌"
        plugin_list.append("  • {} - {} (Live Updates: {})".format(
            service_type,
            plugin_info["name"],
            live_updates
        ))
    
    dashboard_cmd = '''echo "🔌 SERVICE PLUGIN REGISTRY
==========================
Total Plugins: {}
Interface Version: {}

Registered Service Types:
{}

💡 Plugins provide extensible service type support"'''.format(
        status["total_plugins"],
        status["interface_version"],
        "\\n".join(plugin_list) if plugin_list else "  (No plugins registered)"
    )
    
    local_resource(
        'service-registry-dashboard',
        cmd=dashboard_cmd,
        labels=['framework', 'monitoring']
    )