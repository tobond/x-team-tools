"""
Configuration Schemas
Centralized schema definitions for validation
"""

def get_service_base_schema():
    """
    Get the base schema that all services must follow.
    
    Returns:
        dict: Base service schema
    """
    return {
        "type": "object",
        "required": ["type"],
        "properties": {
            "type": {
                "type": "string",
                "description": "Service type identifier"
            },
            "build_context": {
                "type": "string", 
                "description": "Path to build context directory"
            },
            "dockerfile": {
                "type": "string",
                "description": "Path to Dockerfile"
            },
            "ecr_image": {
                "type": "string",
                "description": "ECR image reference"
            },
            "image": {
                "type": "string",
                "description": "Container image reference"
            },
            "ports": {
                "type": "array",
                "items": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 65535
                },
                "description": "List of ports to expose"
            },
            "dependencies": {
                "type": "array",
                "items": {
                    "type": "string"
                },
                "description": "List of service dependencies"
            },
            "env_vars": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["name", "value"],
                    "properties": {
                        "name": {"type": "string"},
                        "value": {"type": "string"}
                    }
                },
                "description": "Environment variables"
            },
            "health_check": {
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "port": {"type": "integer"},
                    "initial_delay_seconds": {"type": "integer"},
                    "period_seconds": {"type": "integer"}
                },
                "description": "Health check configuration"
            },
            "resources": {
                "type": "object",
                "properties": {
                    "requests": {
                        "type": "object",
                        "properties": {
                            "cpu": {"type": "string"},
                            "memory": {"type": "string"}
                        }
                    },
                    "limits": {
                        "type": "object", 
                        "properties": {
                            "cpu": {"type": "string"},
                            "memory": {"type": "string"}
                        }
                    }
                },
                "description": "Resource requests and limits"
            }
        },
        "not": {
            "allOf": [
                {"required": ["build_context"]},
                {"required": ["ecr_image"]}
            ]
        },
        "description": "Base service configuration schema"
    }

def get_external_service_schema():
    """
    Get the schema for external services (databases, third-party services).
    
    Returns:
        dict: External service schema
    """
    base_schema = get_service_base_schema()
    
    # External services require 'image' instead of build configs
    external_schema = dict(base_schema)
    external_schema["required"] = ["type", "image"]
    external_schema["properties"]["type"]["enum"] = ["external"]
    
    # Remove build-related properties for external services
    build_props = ["build_context", "dockerfile", "ecr_image"]
    for prop in build_props:
        if prop in external_schema["properties"]:
            del external_schema["properties"][prop]
    
    return external_schema

def get_tilt_config_schema():
    """
    Get the schema for Tilt configuration parameters.
    
    Returns:
        dict: Tilt configuration schema
    """
    return {
        "type": "object",
        "properties": {
            "developer_id": {
                "type": "string",
                "description": "Developer identifier for namespace isolation"
            },
            "services_to_deploy": {
                "type": "array",
                "items": {"type": "string"},
                "description": "List of services to deploy"
            },
            "disabled_services": {
                "type": "array", 
                "items": {"type": "string"},
                "description": "List of services to disable"
            },
            "debug_mode": {
                "type": "boolean",
                "description": "Enable debug mode"
            },
            "cluster_type": {
                "type": "string",
                "enum": ["kind", "k3d", "docker-desktop", "minikube"],
                "description": "Local cluster type"
            },
            "ecr_version_overrides": {
                "type": "object",
                "additionalProperties": {"type": "string"},
                "description": "ECR version overrides per service"
            },
            "env_overrides": {
                "type": "object",
                "additionalProperties": {
                    "type": "object",
                    "additionalProperties": {"type": "string"}
                },
                "description": "Environment variable overrides per service"
            }
        }
    }

def get_environment_config_schema():
    """
    Get the schema for environment definitions.
    
    Returns:
        dict: Environment configuration schema  
    """
    return {
        "type": "object",
        "required": ["name", "services"],
        "properties": {
            "name": {
                "type": "string",
                "description": "Environment name"
            },
            "description": {
                "type": "string", 
                "description": "Environment description"
            },
            "services": {
                "type": "array",
                "items": {"type": "string"},
                "description": "List of services in this environment"
            },
            "deployment_order": {
                "type": "array",
                "items": {
                    "oneOf": [
                        {"type": "string"},
                        {
                            "type": "array",
                            "items": {"type": "string"}
                        }
                    ]
                },
                "description": "Service deployment order"
            },
            "environment_variables": {
                "type": "object",
                "additionalProperties": {"type": "string"},
                "description": "Global environment variables"
            },
            "resource_limits": {
                "type": "object",
                "properties": {
                    "default_cpu_limit": {"type": "string"},
                    "default_memory_limit": {"type": "string"},
                    "namespace_quotas": {
                        "type": "object",
                        "additionalProperties": {"type": "string"}
                    }
                }
            }
        }
    }

def validate_against_schema(data, schema):
    """
    Validate data against a JSON schema (simplified validation).
    
    Args:
        data: The data to validate
        schema (dict): JSON schema to validate against
        
    Returns:
        dict: Validation result with 'valid' boolean and 'errors' list
    """
    errors = []
    
    # Basic type validation
    if schema.get("type") == "object" and not type(data) == "dict":
        errors.append("Expected object, got {}".format(type(data)))
        return {"valid": False, "errors": errors}
    
    if schema.get("type") == "array" and not type(data) == "list":
        errors.append("Expected array, got {}".format(type(data)))
        return {"valid": False, "errors": errors}
    
    # Required fields validation
    if "required" in schema and type(data) == "dict":
        for field in schema["required"]:
            if field not in data:
                errors.append("Missing required field: {}".format(field))
    
    # Properties validation
    if "properties" in schema and type(data) == "dict":
        for field, field_schema in schema["properties"].items():
            if field in data:
                field_result = validate_against_schema(data[field], field_schema)
                if not field_result["valid"]:
                    for error in field_result["errors"]:
                        errors.append("Field '{}': {}".format(field, error))
    
    # Array items validation
    if "items" in schema and type(data) == "list":
        for i, item in enumerate(data):
            item_result = validate_against_schema(item, schema["items"])
            if not item_result["valid"]:
                for error in item_result["errors"]:
                    errors.append("Item {}: {}".format(i, error))
    
    # Enum validation
    if "enum" in schema and data not in schema["enum"]:
        errors.append("Value '{}' not in allowed values: {}".format(data, schema["enum"]))
    
    # Minimum/maximum validation for integers
    if schema.get("type") == "integer" and type(data) == "int":
        if "minimum" in schema and data < schema["minimum"]:
            errors.append("Value {} is less than minimum {}".format(data, schema["minimum"]))
        if "maximum" in schema and data > schema["maximum"]:
            errors.append("Value {} is greater than maximum {}".format(data, schema["maximum"]))
    
    return {
        "valid": len(errors) == 0,
        "errors": errors
    }