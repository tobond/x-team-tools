"""
Service Interface Contract
Defines the standard interface that all service plugins must implement
"""

def create_service_interface():
    """
    Returns the service interface contract that all service plugins must implement.
    This is a documentation/validation interface - Starlark doesn't have formal interfaces.
    """
    return {
        "interface": "ServicePlugin",
        "version": "1.0.0",
        "required_functions": [
            "get_service_info",
            "validate_config", 
            "get_default_config",
            "create_deployment_manifest",
            "get_health_check_config",
            "supports_live_updates"
        ],
        "optional_functions": [
            "get_build_dependencies",
            "get_runtime_dependencies", 
            "get_environment_variables",
            "customize_deployment"
        ]
    }

def get_service_info():
    """
    Service plugins must implement this function to return service metadata.
    
    Returns:
        dict: Service information with keys:
            - name: Human-readable service type name
            - description: Brief description of the service type
            - supported_platforms: List of supported platforms
            - default_port: Default port for the service type
            - file_extensions: File extensions associated with this service type
    """
    fail("Service plugin must implement get_service_info()")

def validate_config(config):
    """
    Service plugins must implement this function to validate service-specific configuration.
    
    Args:
        config (dict): Service configuration to validate
        
    Returns:
        dict: Validation result with keys:
            - valid: boolean indicating if config is valid
            - errors: list of error messages (empty if valid)
            - warnings: list of warning messages
    """
    fail("Service plugin must implement validate_config(config)")

def get_default_config():
    """
    Service plugins must implement this function to return default configuration.
    
    Returns:
        dict: Default configuration for this service type
    """
    fail("Service plugin must implement get_default_config()")

def create_deployment_manifest(service_name, config, namespace):
    """
    Service plugins must implement this function to create Kubernetes deployment manifests.
    
    Args:
        service_name (str): Name of the service
        config (dict): Service configuration
        namespace (str): Kubernetes namespace
        
    Returns:
        str: YAML manifest for Kubernetes deployment
    """
    fail("Service plugin must implement create_deployment_manifest(service_name, config, namespace)")

def get_health_check_config(config):
    """
    Service plugins must implement this function to return health check configuration.
    
    Args:
        config (dict): Service configuration
        
    Returns:
        dict: Health check configuration with keys:
            - path: Health check endpoint path
            - port: Port for health checks
            - initial_delay_seconds: Initial delay before health checks
            - period_seconds: Period between health checks
    """
    fail("Service plugin must implement get_health_check_config(config)")

def supports_live_updates():
    """
    Service plugins must implement this function to indicate live update support.
    
    Returns:
        bool: True if service type supports live updates
    """
    fail("Service plugin must implement supports_live_updates()")

# Optional interface functions (plugins may implement these)

def get_build_dependencies(config):
    """
    Optional: Service plugins may implement this to specify build dependencies.
    
    Args:
        config (dict): Service configuration
        
    Returns:
        list: List of build dependencies
    """
    return []

def get_runtime_dependencies(config):
    """
    Optional: Service plugins may implement this to specify runtime dependencies.
    
    Args:
        config (dict): Service configuration
        
    Returns:
        list: List of runtime service dependencies
    """
    return []

def get_environment_variables(config):
    """
    Optional: Service plugins may implement this to specify environment variables.
    
    Args:
        config (dict): Service configuration
        
    Returns:
        dict: Environment variables for the service
    """
    return {}

def customize_deployment(manifest, config):
    """
    Optional: Service plugins may implement this to customize deployment manifest.
    
    Args:
        manifest (str): Base deployment manifest
        config (dict): Service configuration
        
    Returns:
        str: Customized deployment manifest
    """
    return manifest