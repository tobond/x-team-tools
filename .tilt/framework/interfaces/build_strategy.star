"""
Build Strategy Interface Contract
Defines the standard interface that all build strategy plugins must implement
"""

def create_build_strategy_interface():
    """
    Returns the build strategy interface contract that all build strategy plugins must implement.
    This is a documentation/validation interface - Starlark doesn't have formal interfaces.
    """
    return {
        "interface": "BuildStrategyPlugin",
        "version": "1.0.0",
        "required_functions": [
            "get_strategy_info",
            "can_handle_service",
            "create_build_config",
            "supports_live_updates",
            "get_live_update_rules"
        ],
        "optional_functions": [
            "get_build_dependencies",
            "customize_build_config",
            "get_optimization_hints"
        ]
    }

def get_strategy_info():
    """
    Build strategy plugins must implement this function to return strategy metadata.
    
    Returns:
        dict: Strategy information with keys:
            - name: Human-readable strategy name
            - description: Brief description of the build strategy
            - priority: Integer priority for strategy selection (higher = preferred)
            - supported_service_types: List of service types this strategy can handle
    """
    fail("Build strategy plugin must implement get_strategy_info()")

def can_handle_service(service_type, config):
    """
    Build strategy plugins must implement this function to determine if they can handle a service.
    
    Args:
        service_type (str): Type of service
        config (dict): Service configuration
        
    Returns:
        bool: True if this strategy can handle the service
    """
    fail("Build strategy plugin must implement can_handle_service(service_type, config)")

def create_build_config(service_name, service_type, config):
    """
    Build strategy plugins must implement this function to create build configuration.
    
    Args:
        service_name (str): Name of the service
        service_type (str): Type of service
        config (dict): Service configuration
        
    Returns:
        dict: Build configuration with keys:
            - build_method: Method used for building (docker_build, custom_build, etc.)
            - build_context: Build context path
            - dockerfile: Dockerfile path (if applicable)
            - image_name: Target image name
            - build_args: Build arguments
    """
    fail("Build strategy plugin must implement create_build_config(service_name, service_type, config)")

def supports_live_updates():
    """
    Build strategy plugins must implement this function to indicate live update support.
    
    Returns:
        bool: True if strategy supports live updates
    """
    fail("Build strategy plugin must implement supports_live_updates()")

def get_live_update_rules(service_type, build_context):
    """
    Build strategy plugins must implement this function to return live update rules.
    
    Args:
        service_type (str): Type of service
        build_context (str): Build context path
        
    Returns:
        list: List of live update rules for Tilt
    """
    fail("Build strategy plugin must implement get_live_update_rules(service_type, build_context)")

# Optional interface functions (plugins may implement these)

def get_build_dependencies(service_type, config):
    """
    Optional: Build strategy plugins may implement this to specify build dependencies.
    
    Args:
        service_type (str): Type of service
        config (dict): Service configuration
        
    Returns:
        list: List of build dependencies
    """
    return []

def customize_build_config(build_config, service_type, config):
    """
    Optional: Build strategy plugins may implement this to customize build configuration.
    
    Args:
        build_config (dict): Base build configuration
        service_type (str): Type of service
        config (dict): Service configuration
        
    Returns:
        dict: Customized build configuration
    """
    return build_config

def get_optimization_hints(service_type, config):
    """
    Optional: Build strategy plugins may implement this to provide optimization hints.
    
    Args:
        service_type (str): Type of service
        config (dict): Service configuration
        
    Returns:
        dict: Optimization hints with keys:
            - cache_hints: Caching optimization suggestions
            - build_hints: Build optimization suggestions
            - performance_hints: Performance optimization suggestions
    """
    return {
        "cache_hints": [],
        "build_hints": [],
        "performance_hints": []
    }