"""
Environment Interface Contract
Defines the standard interface that all environment plugins must implement
"""

def create_environment_interface():
    """
    Returns the environment interface contract that all environment plugins must implement.
    This is a documentation/validation interface - Starlark doesn't have formal interfaces.
    """
    return {
        "interface": "EnvironmentPlugin",
        "version": "1.0.0",
        "required_functions": [
            "get_environment_info",
            "get_service_list",
            "validate_environment_config",
            "get_deployment_order"
        ],
        "optional_functions": [
            "get_environment_variables",
            "get_network_config",
            "get_resource_limits",
            "customize_environment"
        ]
    }

def get_environment_info():
    """
    Environment plugins must implement this function to return environment metadata.
    
    Returns:
        dict: Environment information with keys:
            - name: Human-readable environment name
            - description: Brief description of the environment
            - use_cases: List of use cases for this environment
            - estimated_resources: Resource requirements estimation
    """
    fail("Environment plugin must implement get_environment_info()")

def get_service_list():
    """
    Environment plugins must implement this function to return list of services in environment.
    
    Returns:
        list: List of service names that should be deployed in this environment
    """
    fail("Environment plugin must implement get_service_list()")

def validate_environment_config(available_services):
    """
    Environment plugins must implement this function to validate environment configuration.
    
    Args:
        available_services (list): List of available service names
        
    Returns:
        dict: Validation result with keys:
            - valid: boolean indicating if environment config is valid
            - errors: list of error messages (empty if valid)
            - warnings: list of warning messages
            - missing_services: list of required services that are not available
    """
    fail("Environment plugin must implement validate_environment_config(available_services)")

def get_deployment_order():
    """
    Environment plugins must implement this function to specify service deployment order.
    
    Returns:
        list: List of service names in deployment order, or list of lists for parallel deployment groups
        Example: ["database", ["api", "worker"], "frontend"] means:
                 1. Deploy database first
                 2. Deploy api and worker in parallel
                 3. Deploy frontend last
    """
    fail("Environment plugin must implement get_deployment_order()")

# Optional interface functions (plugins may implement these)

def get_environment_variables():
    """
    Optional: Environment plugins may implement this to specify global environment variables.
    
    Returns:
        dict: Global environment variables for all services in this environment
    """
    return {}

def get_network_config():
    """
    Optional: Environment plugins may implement this to specify network configuration.
    
    Returns:
        dict: Network configuration with keys:
            - network_policies: List of network policies
            - ingress_rules: List of ingress rules
            - service_mesh_config: Service mesh configuration
    """
    return {
        "network_policies": [],
        "ingress_rules": [],
        "service_mesh_config": {}
    }

def get_resource_limits():
    """
    Optional: Environment plugins may implement this to specify resource limits.
    
    Returns:
        dict: Resource limits with keys:
            - default_cpu_limit: Default CPU limit for services
            - default_memory_limit: Default memory limit for services
            - namespace_quotas: Namespace resource quotas
    """
    return {
        "default_cpu_limit": None,
        "default_memory_limit": None,
        "namespace_quotas": {}
    }

def customize_environment(base_config, service_configs):
    """
    Optional: Environment plugins may implement this to customize the environment.
    
    Args:
        base_config (dict): Base environment configuration
        service_configs (dict): Dictionary of service configurations
        
    Returns:
        dict: Customized environment configuration
    """
    return base_config