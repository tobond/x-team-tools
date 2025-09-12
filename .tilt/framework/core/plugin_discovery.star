"""
Plugin Discovery System
Automatically discovers and loads plugins from the plugins directory
"""


# Load YAML-driven service plugin that reads service-config.yaml
load('../../plugins/services/yaml_config_reader.star', 
     get_service_plugin='get_service_plugin',
     get_available_services='get_available_services',
     get_services_by_type='get_services_by_type')

# Environment plugins - load YAML-driven environment plugin that reads environments.yaml
load('../../plugins/environments/yaml_environment_loader.star', 
     get_environment_plugin='get_environment_plugin',
     get_available_environments='get_available_environments')

# Build strategy plugins - load all required interface functions
load('../../plugins/build_strategies/live_update.star', 
     live_update_get_strategy_info='get_strategy_info',
     live_update_can_handle_service='can_handle_service',
     live_update_create_build_config='create_build_config',
     live_update_supports_live_updates='supports_live_updates',
     live_update_get_live_update_rules='get_live_update_rules')

def discover_and_register_all_plugins():
    """
    Discover and return information about all plugins.
    Due to Starlark constraints, this returns plugin info rather than registering in global state.
    """
    print("🔍 Discovering plugins...")
    
    # Build static plugin registry at discovery time
    service_plugins = _build_service_plugins()
    print("Found {} service plugins".format(len(service_plugins)))
    
    build_strategy_plugins = _build_build_strategy_plugins()
    print("Found {} build strategy plugins".format(len(build_strategy_plugins)))
    
    environment_plugins = _build_environment_plugins()
    print("Found {} environment plugins".format(len(environment_plugins)))
    
    # All services are now handled by the generic service plugin
    all_service_plugins = list(service_plugins.keys())
    total_plugins = len(all_service_plugins) + len(build_strategy_plugins) + len(environment_plugins)
    print("✅ Plugin discovery complete: {} plugins available".format(total_plugins))
    
    return {
        "service_plugins": all_service_plugins,
        "build_strategy_plugins": list(build_strategy_plugins.keys()),
        "environment_plugins": list(environment_plugins.keys()),
        "total_plugins": total_plugins,
        "plugin_registry": {
            "services": service_plugins,
            "build_strategies": build_strategy_plugins,
            "environments": environment_plugins
        }
    }

def _build_service_plugins():
    """
    Build service plugin registry using generic configuration-driven approach.
    Reads all services from service-config.yaml and creates plugins dynamically.
    
    Returns:
        dict: Dictionary of service plugins dynamically created from YAML config
    """
    service_plugins = {}
    
    # Get all available services from service-config.yaml
    available_services = get_available_services()
    
    # Create a plugin instance for each service defined in YAML
    for service_name in available_services:
        service_plugins[service_name] = get_service_plugin(service_name)
    
    return service_plugins

def _build_build_strategy_plugins():
    """
    Build build strategy plugin registry (Starlark-compatible static approach)
    
    Returns:
        dict: Dictionary of build strategy plugins
    """
    return {
        "live_update": struct(
            get_strategy_info=live_update_get_strategy_info,
            can_handle_service=live_update_can_handle_service,
            create_build_config=live_update_create_build_config,
            supports_live_updates=live_update_supports_live_updates,
            get_live_update_rules=live_update_get_live_update_rules
        )
    }

def _build_environment_plugins():
    """
    Build environment plugin registry using generic YAML-driven approach.
    This maintains clean separation of concerns:
    - Configuration (what to deploy) in environments.yaml
    - Implementation (how to deploy) in generic plugin
    
    Returns:
        dict: Dictionary of environment plugins dynamically created from YAML config
    """
    environment_plugins = {}
    
    # Get all available environments from the YAML configuration
    available_environments = get_available_environments()
    
    # Create a plugin instance for each environment defined in YAML
    for env_name in available_environments:
        environment_plugins[env_name] = get_environment_plugin(env_name)
    
    return environment_plugins


def get_plugin_discovery_status():
    """
    Get the current status of plugin discovery.
    
    Returns:
        dict: Plugin discovery status
    """
    # This would normally track discovery state
    # For now, return basic status
    return {
        "discovery_enabled": True,
        "plugins_directory": ".tilt/plugins",
        "last_discovery": "on_startup",
        "auto_discovery": True
    }

def create_plugin_discovery_dashboard():
    """
    Create a Tilt dashboard resource showing plugin discovery status.
    """
    status = get_plugin_discovery_status()
    
    dashboard_cmd = '''echo "🔍 PLUGIN DISCOVERY SYSTEM
===========================
Status: Active
Plugins Directory: {}
Auto Discovery: {}

Discovery Log:
• Service plugins: Checking .tilt/plugins/services/
• Build strategies: Checking .tilt/plugins/build_strategies/  
• Environments: Checking .tilt/plugins/environments/
• External services: Checking .tilt/plugins/external/

💡 Plugins are automatically discovered and registered at startup"'''.format(
        status["plugins_directory"],
        "Enabled" if status["auto_discovery"] else "Disabled"
    )
    
    local_resource(
        'plugin-discovery-dashboard',
        cmd=dashboard_cmd,
        labels=['framework', 'monitoring']
    )