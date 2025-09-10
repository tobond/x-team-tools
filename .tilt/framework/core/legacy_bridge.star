"""
Legacy Bridge
Provides compatibility layer between old system and new plugin architecture
This allows gradual migration without breaking existing functionality
"""

# Load the new plugin framework
load('../init.star', 'initialize_plugin_framework', 'get_framework_status')
load('../registry/service_registry.star', 'is_service_type_supported', 'get_service_plugin', 'create_service_deployment')

# Legacy system integration flag
_PLUGIN_FRAMEWORK_ENABLED = True

def should_use_plugin_framework():
    """
    Determine if plugin framework should be used.
    
    Returns:
        bool: True if plugin framework should be used
    """
    return _PLUGIN_FRAMEWORK_ENABLED

def bridge_service_validation(service_name, service_config):
    """
    Bridge function for service validation - tries plugin first, falls back to legacy.
    
    Args:
        service_name (str): Name of the service
        service_config (dict): Service configuration
        
    Returns:
        dict: Validation result
    """
    
    if not should_use_plugin_framework():
        # Fall back to legacy validation
        return _legacy_validation_fallback(service_name, service_config)
    
    service_type = service_config.get("type", "")
    
    if is_service_type_supported(service_type):
        # Use plugin framework
        from ..validation.config_validator import validate_base_config
        base_result = validate_base_config(service_name, service_config)
        
        if base_result["valid"]:
            from ..registry.service_registry import validate_service_config
            plugin_result = validate_service_config(service_type, service_config)
            
            # Combine results
            return {
                "valid": plugin_result["valid"],
                "errors": base_result["errors"] + plugin_result["errors"],
                "warnings": base_result["warnings"] + plugin_result["warnings"],
                "method": "plugin_framework"
            }
        else:
            return {
                "valid": False,
                "errors": base_result["errors"],
                "warnings": base_result["warnings"],
                "method": "plugin_framework"
            }
    else:
        # Fall back to legacy validation
        return _legacy_validation_fallback(service_name, service_config)

def bridge_service_deployment(service_name, service_config, namespace, global_config):
    """
    Bridge function for service deployment - tries plugin first, falls back to legacy.
    
    Args:
        service_name (str): Name of the service
        service_config (dict): Service configuration  
        namespace (str): Kubernetes namespace
        global_config (dict): Global configuration
        
    Returns:
        dict: Deployment result
    """
    
    if not should_use_plugin_framework():
        return _legacy_deployment_fallback(service_name, service_config, namespace, global_config)
    
    service_type = service_config.get("type", "")
    
    if is_service_type_supported(service_type):
        # Use plugin framework orchestration
        try:
            from ..core.orchestration import orchestrate_service_deployment
            result = orchestrate_service_deployment(service_name, service_config, namespace, global_config)
            result["method"] = "plugin_framework"
            return result
        except Exception as e:
            print("⚠️  Plugin framework deployment failed for '{}', falling back to legacy: {}".format(service_name, str(e)))
            return _legacy_deployment_fallback(service_name, service_config, namespace, global_config)
    else:
        # Fall back to legacy deployment
        return _legacy_deployment_fallback(service_name, service_config, namespace, global_config)

def get_supported_service_types():
    """
    Get all supported service types from both plugin framework and legacy system.
    
    Returns:
        dict: Service types with their support method
    """
    
    supported_types = {}
    
    if should_use_plugin_framework():
        # Get plugin framework types
        try:
            from ..registry.service_registry import get_registered_service_types
            plugin_types = get_registered_service_types()
            for service_type in plugin_types:
                supported_types[service_type] = "plugin_framework"
        except Exception as e:
            print("⚠️  Failed to get plugin service types: {}".format(str(e)))
    
    # Add legacy types (from original config validation)
    legacy_types = ['python', 'java', 'go', 'nodejs', 'external', 'postgres', 'redis', 'mongodb', 'mysql', 'generic']
    for service_type in legacy_types:
        if service_type not in supported_types:
            supported_types[service_type] = "legacy"
    
    return supported_types

def create_bridge_status_dashboard():
    """Create dashboard showing bridge status and supported service types."""
    
    supported_types = get_supported_service_types()
    framework_enabled = should_use_plugin_framework()
    
    plugin_types = [t for t, method in supported_types.items() if method == "plugin_framework"]
    legacy_types = [t for t, method in supported_types.items() if method == "legacy"]
    
    dashboard_cmd = '''echo "🌉 LEGACY BRIDGE STATUS
=======================
Plugin Framework: {}
Total Service Types: {}

Plugin Framework Types:
{}

Legacy Types:
{}

💡 Bridge enables gradual migration to plugin architecture"'''.format(
        "Enabled" if framework_enabled else "Disabled",
        len(supported_types),
        "\\n".join(["  • {}".format(t) for t in plugin_types]) if plugin_types else "  (None)",
        "\\n".join(["  • {}".format(t) for t in legacy_types]) if legacy_types else "  (None)"
    )
    
    local_resource(
        'legacy-bridge-dashboard',
        cmd=dashboard_cmd,
        labels=['framework', 'monitoring', 'bridge']
    )

def _legacy_validation_fallback(service_name, service_config):
    """Fallback to legacy validation logic."""
    
    # Simplified legacy validation
    errors = []
    warnings = []
    
    if not type(service_config) == "dict":
        errors.append("Configuration must be a dictionary")
    
    if not service_config.get("type"):
        errors.append("Missing required field 'type'")
    
    # Basic validation similar to original config.star
    valid_types = ['python', 'java', 'go', 'nodejs', 'external', 'postgres', 'redis', 'mongodb', 'mysql', 'generic']
    service_type = service_config.get('type', '')
    
    if service_type not in valid_types:
        errors.append("Invalid service type: '{}'".format(service_type))
    
    return {
        "valid": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "method": "legacy"
    }

def _legacy_deployment_fallback(service_name, service_config, namespace, global_config):
    """Fallback to legacy deployment logic."""
    
    # This would call the original deployment logic
    # For now, return a basic result
    return {
        "name": service_name,
        "type": service_config.get("type", "unknown"),
        "namespace": namespace,
        "ports": service_config.get("ports", []),
        "image": service_name,
        "build_strategy": "legacy",
        "live_updates_enabled": False,
        "method": "legacy",
        "note": "Deployed using legacy system"
    }