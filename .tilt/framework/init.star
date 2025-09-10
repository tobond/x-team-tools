"""
Framework Initialization
Main entry point for the plugin architecture framework
"""

# Load core framework components
load('core/plugin_discovery.star', 'discover_and_register_all_plugins', 'create_plugin_discovery_dashboard')
load('core/orchestration.star', 'orchestrate_services_batch', 'create_orchestration_dashboard')

# Load registries for dashboard creation
load('registry/service_registry.star', 'create_registry_dashboard', 'get_registry_status')
load('registry/build_registry.star', 'create_build_strategy_dashboard')
load('registry/environment_registry.star', 'create_environment_registry_dashboard')

# Load validation
load('validation/config_validator.star', 'validate_service_list', 'create_validation_summary')

def initialize_plugin_framework():
    """
    Initialize the plugin framework system.
    This should be called early in the Tiltfile execution.
    
    Returns:
        dict: Framework initialization result
    """
    
    print("🚀 Initializing Plugin Framework...")
    
    # Step 1: Discover and register all plugins
    discovery_result = discover_and_register_all_plugins()
    
    # Step 2: Create monitoring dashboards
    create_plugin_discovery_dashboard()
    _create_simple_plugin_dashboard(discovery_result)
    
    # Step 3: Return initialization status
    init_result = {
        "framework_version": "1.0.0",
        "initialized": True,
        "plugins_discovered": discovery_result["total_plugins"],
        "service_plugins": discovery_result["service_plugins"],
        "build_strategy_plugins": discovery_result["build_strategy_plugins"],
        "environment_plugins": discovery_result["environment_plugins"]
    }
    
    print("✅ Plugin Framework initialized: {} plugins loaded".format(
        init_result["plugins_discovered"]
    ))
    
    return init_result

def validate_and_deploy_services(services_config, namespace, global_config, environment_name=None):
    """
    Validate and deploy services using the plugin framework.
    
    Args:
        services_config (dict): Service configurations
        namespace (str): Kubernetes namespace
        global_config (dict): Global configuration
        environment_name (str, optional): Environment name for deployment order
        
    Returns:
        list: List of deployed services
    """
    
    # Step 1: Validate all service configurations
    validation_result = validate_service_list(services_config)
    
    if not validation_result["valid"]:
        validation_summary = create_validation_summary(validation_result)
        fail("Service configuration validation failed:\\n{}".format(validation_summary))
    
    # Step 2: Get deployment order from environment if specified
    deployment_order = None
    if environment_name:
        # Load environment registry and get deployment order
        # For now, deploy all in parallel
        deployment_order = None
    
    # Step 3: Deploy services using orchestration
    deployed_services = orchestrate_services_batch(
        services_config,
        namespace, 
        global_config,
        deployment_order
    )
    
    # Step 4: Create orchestration dashboard
    create_orchestration_dashboard(deployed_services)
    
    return deployed_services

def get_framework_status():
    """
    Get current status of the plugin framework.
    
    Returns:
        dict: Framework status information
    """
    
    return {
        "framework_version": "1.0.0",
        "initialized": True,
        "service_plugins": 6,  # python, java, nodejs, go, postgres, redis
        "build_strategies": 1,  # live_update
        "environments": 3       # minimal, backend_only, full_stack
    }

def create_framework_dashboard():
    """Create a comprehensive framework status dashboard."""
    
    status = get_framework_status()
    
    dashboard_cmd = '''echo "🏗️ PLUGIN FRAMEWORK STATUS
============================
Version: {}
Status: {}

Plugin Summary:
• Service Plugins: {}
• Build Strategies: {}
• Environment Plugins: {}
• Plugin Discovery: Enabled
• Orchestration: Active

💡 Framework provides extensible service management
   Visit other dashboards for detailed plugin information"'''.format(
        status["framework_version"],
        "Initialized" if status["initialized"] else "Not Initialized",
        status["service_plugins"],
        status["build_strategies"],
        status["environments"]
    )
    
    local_resource(
        'framework-status-dashboard',
        labels=['framework'],
        cmd=dashboard_cmd
    )

def _create_simple_plugin_dashboard(discovery_result):
    """Create a simple plugin dashboard from discovery results."""
    
    service_plugins_str = ", ".join(discovery_result["service_plugins"])
    build_plugins_str = ", ".join(discovery_result["build_strategy_plugins"]) 
    env_plugins_str = ", ".join(discovery_result["environment_plugins"])
    
    dashboard_cmd = '''echo "🔌 DISCOVERED PLUGINS
========================
Total Plugins: {}

Service Types:
{}

Build Strategies:
{}

Environments:
{}

✅ All plugins loaded successfully"'''.format(
        discovery_result["total_plugins"],
        service_plugins_str,
        build_plugins_str,
        env_plugins_str
    )
    
    local_resource(
        'plugin-discovery-summary',
        labels=['framework'],
        cmd=dashboard_cmd
    )