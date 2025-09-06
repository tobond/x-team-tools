"""
Minimal builds.star for debugging
"""

def get_live_updates_for_type(app_type, build_context):
    """Return minimal live update rules for testing"""

    if app_type == "python":
        return [
            sync(build_context + '/main.py', '/app/main.py'),
            sync(build_context + '/requirements.txt', '/app/requirements.txt'),
            run('pip install -r requirements.txt', trigger=[build_context + '/requirements.txt']),
        ]
    else:
        return [
            sync(build_context + '/src', '/app/src'),
        ]

def setup_build_strategy(service_name, service_config, build_local_services, debug_mode=False):
    """Minimal build strategy setup"""

    # Check if this is an external service with a pre-built image
    service_type = service_config.get("type", "generic")
    external_image = service_config.get("image")

    # Handle external services (like postgres, redis)
    if service_type == "external" and external_image:
        if debug_mode:
            print("🐳 Using external Docker image for: " + service_name)
            print("   Image: " + external_image)

        return {
            "image_name": external_image,  # Use the specified image, not the service name
            "build_locally": False,
            "external_image": True
        }

    build_locally = service_name in build_local_services
    if build_locally:
        return _setup_local_build(service_name, service_config, debug_mode)
    else:
        return {"image_name": service_name, "build_locally": False}

def _setup_local_build(service_name, service_config, debug_mode=False):
    """Setup local Docker build"""

    build_context = service_config.get("build_context", "./" + service_name)
    dockerfile_path = service_config.get("dockerfile", build_context + "/Dockerfile")
    app_type = service_config.get("type", "generic")

    docker_build(
        service_name,
        context=build_context,
        dockerfile=dockerfile_path,
        live_update=get_live_updates_for_type(app_type, build_context)
    )

    return {
        "image_name": service_name,
        "build_locally": True,
        "build_context": build_context
    }

def validate_build_requirements(service_name, service_config, build_locally, debug_mode=False):
    """Minimal validation"""
    return {"valid": True, "errors": [], "warnings": []}

def optimize_docker_build_context(build_context, service_type="generic", debug_mode=False):
    """Minimal optimization"""
    return {"optimized_context": build_context, "exclude_patterns": [], "include_patterns": []}

def get_build_info(service_name, service_config, build_local_services):
    """Minimal build info"""
    return {
        "service_name": service_name,
        "service_type": service_config.get("type", "generic"),
        "build_locally": service_name in build_local_services,
        "image_name": service_name
    }

# Minimal monitoring functions
def create_service_customization_validator(deployed_services, tilt_config):
    pass

def setup_build_monitoring(deployed_services):
    pass

def create_live_update_summary(deployed_services):
    pass

def create_build_strategy_dashboard(deployed_services, tilt_config):
    pass

def create_ecr_version_monitor(deployed_services):
    pass
