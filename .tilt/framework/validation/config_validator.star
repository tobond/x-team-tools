"""
Generic Configuration Validator
Framework-level validation logic separated from implementation-specific rules
"""

def create_base_validation_schema():
    """
    Return the base configuration schema that all services must conform to.
    Service-specific validation is handled by plugins.
    
    Returns:
        dict: Base validation schema
    """
    return {
        "required_fields": ["type"],
        "optional_fields": [
            "build_context",
            "dockerfile", 
            "ecr_image",
            "image",
            "ports",
            "dependencies",
            "env_vars",
            "health_check",
            "resources"
        ],
        "field_types": {
            "type": "string",
            "build_context": "string",
            "dockerfile": "string",
            "ecr_image": "string", 
            "image": "string",
            "ports": "list",
            "dependencies": "list",
            "env_vars": "list",
            "health_check": "dict",
            "resources": "dict"
        }
    }

def validate_base_config(service_name, config):
    """
    Validate base configuration structure before delegating to service plugins.
    
    Args:
        service_name (str): Name of the service
        config (dict): Service configuration to validate
        
    Returns:
        dict: Validation result with keys:
            - valid: boolean indicating if config is valid
            - errors: list of error messages
            - warnings: list of warning messages
    """
    
    errors = []
    warnings = []
    
    # Check if config is a dictionary
    if not type(config) == "dict":
        return {
            "valid": False,
            "errors": ["Configuration for '{}' must be a dictionary, got {}".format(
                service_name, type(config)
            )],
            "warnings": []
        }
    
    schema = create_base_validation_schema()
    
    # Check required fields
    for field in schema["required_fields"]:
        if field not in config:
            errors.append("Missing required field '{}' for service '{}'".format(field, service_name))
    
    # Check field types
    for field, expected_type in schema["field_types"].items():
        if field in config:
            actual_value = config[field]
            if not _is_valid_type(actual_value, expected_type):
                errors.append("Field '{}' for service '{}' must be of type {}, got {}".format(
                    field, service_name, expected_type, type(actual_value)
                ))
    
    # Validate ports if present
    if "ports" in config:
        port_errors = _validate_ports(service_name, config["ports"])
        errors.extend(port_errors)
    
    # Validate dependencies if present  
    if "dependencies" in config:
        dep_errors = _validate_dependencies(service_name, config["dependencies"])
        errors.extend(dep_errors)
    
    # Validate mutually exclusive build configurations
    build_config_errors = _validate_build_config_exclusivity(service_name, config)
    errors.extend(build_config_errors)
    
    # Check for deprecated fields
    deprecated_warnings = _check_deprecated_fields(service_name, config)
    warnings.extend(deprecated_warnings)
    
    return {
        "valid": len(errors) == 0,
        "errors": errors,
        "warnings": warnings
    }

def validate_service_list(services_config):
    """
    Validate the entire services configuration structure.
    
    Args:
        services_config (dict): Dictionary of service configurations
        
    Returns:
        dict: Validation result with service-level details
    """
    
    if not type(services_config) == "dict":
        return {
            "valid": False,
            "errors": ["Services configuration must be a dictionary"],
            "warnings": [],
            "service_results": {}
        }
    
    all_errors = []
    all_warnings = []
    service_results = {}
    
    for service_name, service_config in services_config.items():
        result = validate_base_config(service_name, service_config)
        service_results[service_name] = result
        
        all_errors.extend(result["errors"])
        all_warnings.extend(result["warnings"])
    
    return {
        "valid": len(all_errors) == 0,
        "errors": all_errors,
        "warnings": all_warnings,
        "service_results": service_results
    }

def _is_valid_type(value, expected_type):
    """
    Check if a value matches the expected type.
    
    Args:
        value: The value to check
        expected_type (str): Expected type name
        
    Returns:
        bool: True if value matches expected type
    """
    if expected_type == "string":
        return type(value) == "string"
    elif expected_type == "list":
        return type(value) == "list"
    elif expected_type == "dict":
        return type(value) == "dict"
    elif expected_type == "int":
        return type(value) == "int"
    elif expected_type == "bool":
        return type(value) == "bool"
    else:
        return True  # Unknown type, assume valid

def _validate_ports(service_name, ports):
    """
    Validate port configuration.
    
    Args:
        service_name (str): Name of the service
        ports (list): List of ports
        
    Returns:
        list: List of error messages
    """
    errors = []
    
    if not type(ports) == "list":
        errors.append("Ports for service '{}' must be a list".format(service_name))
        return errors
    
    for port in ports:
        if not type(port) == "int":
            errors.append("Port '{}' for service '{}' must be an integer".format(port, service_name))
        elif port < 1 or port > 65535:
            errors.append("Port '{}' for service '{}' must be between 1 and 65535".format(port, service_name))
    
    return errors

def _validate_dependencies(service_name, dependencies):
    """
    Validate dependencies configuration.
    
    Args:
        service_name (str): Name of the service
        dependencies (list): List of dependencies
        
    Returns:
        list: List of error messages
    """
    errors = []
    
    if not type(dependencies) == "list":
        errors.append("Dependencies for service '{}' must be a list".format(service_name))
        return errors
    
    for dep in dependencies:
        if not type(dep) == "string":
            errors.append("Dependency '{}' for service '{}' must be a string".format(dep, service_name))
    
    return errors

def _validate_build_config_exclusivity(service_name, config):
    """
    Validate that mutually exclusive build configurations are not used together.
    
    Args:
        service_name (str): Name of the service
        config (dict): Service configuration
        
    Returns:
        list: List of error messages
    """
    errors = []
    
    # Skip validation for external services
    if config.get("type") == "external":
        return errors
    
    build_options = []
    if "build_context" in config:
        build_options.append("build_context")
    if "ecr_image" in config:
        build_options.append("ecr_image")
    if "image" in config:
        build_options.append("image")
    
    if len(build_options) > 1:
        errors.append("Service '{}' has conflicting build configurations: {}. Use only one.".format(
            service_name, ", ".join(build_options)
        ))
    
    return errors

def _check_deprecated_fields(service_name, config):
    """
    Check for deprecated configuration fields and return warnings.
    
    Args:
        service_name (str): Name of the service
        config (dict): Service configuration
        
    Returns:
        list: List of warning messages
    """
    warnings = []
    
    deprecated_types = {
        "postgres": "Use type: 'external' with image: 'postgres:13' instead",
        "redis": "Use type: 'external' with image: 'redis:6' instead",
        "mongodb": "Use type: 'external' with image: 'mongo:4.4' instead",
        "mysql": "Use type: 'external' with image: 'mysql:8' instead"
    }
    
    service_type = config.get("type", "")
    if service_type in deprecated_types:
        warnings.append("Service '{}' uses deprecated type '{}'. {}".format(
            service_name, service_type, deprecated_types[service_type]
        ))
    
    return warnings

def create_validation_summary(validation_result):
    """
    Create a human-readable validation summary.
    
    Args:
        validation_result (dict): Result from validate_service_list
        
    Returns:
        str: Human-readable validation summary
    """
    
    if validation_result["valid"]:
        return "✅ All service configurations are valid"
    
    summary_lines = ["❌ Configuration validation failed:"]
    
    # Group errors by service
    service_errors = {}
    for service_name, result in validation_result["service_results"].items():
        if result["errors"]:
            service_errors[service_name] = result["errors"]
    
    for service_name, errors in service_errors.items():
        summary_lines.append("  • {}:".format(service_name))
        for error in errors:
            summary_lines.append("    - {}".format(error))
    
    return "\\n".join(summary_lines)