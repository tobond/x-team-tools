"""
Build Strategy Registry
Central registry for build strategy plugins with discovery and selection
"""

# Load interface definitions
load('../interfaces/build_strategy.star', 'create_build_strategy_interface')

# Global registry to store registered build strategy plugins
_build_strategy_plugins = {}
_build_strategy_interface = create_build_strategy_interface()


def get_registered_build_strategies():
    """
    Get list of all registered build strategy names.
    
    Returns:
        list: List of registered build strategy names
    """
    return list(_build_strategy_plugins.keys())

def get_build_strategy_plugin(strategy_name):
    """
    Get a registered build strategy plugin by name.
    
    Args:
        strategy_name (str): The build strategy identifier
        
    Returns:
        dict: Plugin information, or None if not found
    """
    return _build_strategy_plugins.get(strategy_name)

def select_build_strategy(service_type, config):
    """
    Select the best build strategy for a given service type and configuration.
    
    Args:
        service_type (str): The service type identifier
        config (dict): Service configuration
        
    Returns:
        dict: Selected build strategy plugin info, or None if none can handle
    """
    
    # Get all strategies that can handle this service
    compatible_strategies = []
    
    for strategy_name, plugin_info in _build_strategy_plugins.items():
        if plugin_info["module"].can_handle_service(service_type, config):
            compatible_strategies.append(plugin_info)
    
    if not compatible_strategies:
        return None
    
    # Sort by priority (highest first)
    compatible_strategies.sort(key=lambda x: x["priority"], reverse=True)
    
    return compatible_strategies[0]

def create_build_config(service_name, service_type, config):
    """
    Create build configuration using the selected build strategy.
    
    Args:
        service_name (str): Name of the service
        service_type (str): The service type identifier
        config (dict): Service configuration
        
    Returns:
        dict: Build configuration from selected strategy
    """
    
    strategy = select_build_strategy(service_type, config)
    if not strategy:
        fail("No build strategy can handle service type '{}' with given configuration".format(service_type))
    
    return strategy["module"].create_build_config(service_name, service_type, config)

def get_live_update_rules(service_type, build_context):
    """
    Get live update rules from compatible build strategies.
    
    Args:
        service_type (str): The service type identifier
        build_context (str): Build context path
        
    Returns:
        list: Live update rules, or empty list if none support live updates
    """
    
    # Find strategies that support live updates for this service type
    for strategy_name, plugin_info in _build_strategy_plugins.items():
        if (plugin_info["module"].supports_live_updates() and 
            plugin_info["module"].can_handle_service(service_type, {})):
            return plugin_info["module"].get_live_update_rules(service_type, build_context)
    
    return []

def get_registry_status():
    """
    Get status information about the build strategy registry.
    
    Returns:
        dict: Registry status information
    """
    return {
        "total_strategies": len(_build_strategy_plugins),
        "registered_strategies": list(_build_strategy_plugins.keys()),
        "interface_version": _build_strategy_interface["version"],
        "strategies": {
            strategy_name: {
                "name": info["info"].get("name", strategy_name),
                "description": info["info"].get("description", "No description"),
                "priority": info["priority"],
                "supported_service_types": info["info"].get("supported_service_types", []),
                "live_updates_supported": info["module"].supports_live_updates()
            }
            for strategy_name, info in _build_strategy_plugins.items()
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
    required_functions = _build_strategy_interface["required_functions"]
    missing_functions = []
    
    for func_name in required_functions:
        if not hasattr(plugin_module, func_name):
            missing_functions.append(func_name)
    
    return {
        "valid": len(missing_functions) == 0,
        "missing_functions": missing_functions
    }

def create_build_strategy_dashboard():
    """
    Create a Tilt dashboard resource showing build strategy registry status.
    """
    status = get_registry_status()
    
    strategy_list = []
    for strategy_name, strategy_info in status["strategies"].items():
        live_updates = "✅" if strategy_info["live_updates_supported"] else "❌"
        service_types = ", ".join(strategy_info["supported_service_types"]) if strategy_info["supported_service_types"] else "All"
        strategy_list.append("  • {} (Priority: {}) - {} (Live Updates: {})\\n    Service Types: {}".format(
            strategy_name,
            strategy_info["priority"],
            strategy_info["name"],
            live_updates,
            service_types
        ))
    
    dashboard_cmd = '''echo "🏗️ BUILD STRATEGY REGISTRY
===========================
Total Strategies: {}
Interface Version: {}

Registered Build Strategies:
{}

💡 Strategies are selected by priority and service compatibility"'''.format(
        status["total_strategies"],
        status["interface_version"],
        "\\n".join(strategy_list) if strategy_list else "  (No strategies registered)"
    )
    
    local_resource(
        'build-strategy-registry-dashboard',
        cmd=dashboard_cmd,
        labels=['framework', 'monitoring']
    )