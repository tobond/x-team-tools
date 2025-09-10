"""
Service Lifecycle Orchestration
Framework-level service lifecycle management using plugins
"""

# Load registries and validation
load('../registry/service_registry.star', 
     'get_service_plugin', 'validate_service_config', 'create_service_deployment',
     'get_service_health_check', 'service_supports_live_updates')
load('../registry/build_registry.star', 
     'select_build_strategy', 'create_build_config', 'get_live_update_rules')
load('../validation/config_validator.star', 'validate_base_config')

def orchestrate_service_deployment(service_name, service_config, namespace, global_config):
    """
    Orchestrate the complete deployment of a service using the plugin architecture.
    
    Args:
        service_name (str): Name of the service
        service_config (dict): Service configuration
        namespace (str): Kubernetes namespace
        global_config (dict): Global configuration
        
    Returns:
        dict: Deployment result with service information
    """
    
    # Step 1: Validate base configuration
    base_validation = validate_base_config(service_name, service_config)
    if not base_validation["valid"]:
        fail("Service '{}' failed base validation: {}".format(
            service_name, "; ".join(base_validation["errors"])
        ))
    
    # Step 2: Get service type and plugin
    service_type = service_config.get("type", "generic")
    service_plugin = get_service_plugin(service_type)
    
    if not service_plugin:
        fail("Unsupported service type '{}' for service '{}'".format(service_type, service_name))
    
    # Step 3: Validate service-specific configuration
    plugin_validation = validate_service_config(service_type, service_config)
    if not plugin_validation["valid"]:
        fail("Service '{}' failed plugin validation: {}".format(
            service_name, "; ".join(plugin_validation["errors"])
        ))
    
    # Step 4: Select and configure build strategy
    build_result = _orchestrate_build_strategy(service_name, service_type, service_config)
    
    # Step 5: Create deployment manifest
    deployment_manifest = create_service_deployment(service_name, service_type, service_config, namespace)
    
    # Step 6: Deploy to Kubernetes
    k8s_yaml(blob(deployment_manifest))
    
    # Step 7: Configure service resource with ports and health checks
    _configure_service_resource(service_name, service_config, service_type)
    
    # Step 8: Return deployment information
    return {
        "name": service_name,
        "type": service_type,
        "namespace": namespace,
        "ports": service_config.get("ports", []),
        "image": build_result.get("image_name", "unknown"),
        "build_strategy": build_result.get("strategy_name", "unknown"),
        "live_updates_enabled": build_result.get("live_updates_enabled", False),
        "health_check": get_service_health_check(service_type, service_config),
        "plugin_info": {
            "service_plugin": service_plugin["info"]["name"],
            "build_strategy": build_result.get("strategy_info", {}).get("name", "unknown")
        }
    }

def orchestrate_services_batch(services_config, namespace, global_config, deployment_order=None):
    """
    Orchestrate deployment of multiple services with dependency management.
    
    Args:
        services_config (dict): Dictionary of service configurations
        namespace (str): Kubernetes namespace
        global_config (dict): Global configuration
        deployment_order (list, optional): Deployment order, if None will deploy all in parallel
        
    Returns:
        list: List of deployment results
    """
    
    deployed_services = []
    
    if deployment_order:
        # Deploy in specified order
        for deployment_step in deployment_order:
            if type(deployment_step) == "list":
                # Parallel deployment group
                step_results = []
                for service_name in deployment_step:
                    if service_name in services_config:
                        result = orchestrate_service_deployment(
                            service_name, 
                            services_config[service_name], 
                            namespace, 
                            global_config
                        )
                        step_results.append(result)
                deployed_services.extend(step_results)
            else:
                # Single service deployment
                service_name = deployment_step
                if service_name in services_config:
                    result = orchestrate_service_deployment(
                        service_name,
                        services_config[service_name],
                        namespace,
                        global_config
                    )
                    deployed_services.append(result)
    else:
        # Deploy all services in parallel
        for service_name, service_config in services_config.items():
            result = orchestrate_service_deployment(
                service_name,
                service_config, 
                namespace,
                global_config
            )
            deployed_services.append(result)
    
    return deployed_services

def _orchestrate_build_strategy(service_name, service_type, service_config):
    """
    Orchestrate build strategy selection and configuration.
    
    Args:
        service_name (str): Name of the service
        service_type (str): Service type
        service_config (dict): Service configuration
        
    Returns:
        dict: Build result information
    """
    
    # Select best build strategy
    build_strategy = select_build_strategy(service_type, service_config)
    
    if not build_strategy:
        # Fallback to basic build configuration
        return {
            "strategy_name": "fallback",
            "image_name": service_name,
            "live_updates_enabled": False,
            "strategy_info": {"name": "Fallback Strategy"}
        }
    
    # Create build configuration using selected strategy
    build_config = create_build_config(service_name, service_type, service_config)
    
    # Apply build configuration based on method
    build_method = build_config.get("build_method", "docker_build")
    
    if build_method == "docker_build":
        _apply_docker_build(service_name, build_config, service_type, service_config)
    elif build_method == "custom_build":
        _apply_custom_build(service_name, build_config)
    elif build_method == "external_image":
        _apply_external_image(service_name, build_config)
    
    # Check for live updates support
    live_updates_enabled = False
    if (build_strategy["module"].supports_live_updates() and 
        service_supports_live_updates(service_type)):
        live_updates_enabled = True
    
    return {
        "strategy_name": build_strategy["name"],
        "image_name": build_config.get("image_name", service_name),
        "live_updates_enabled": live_updates_enabled,
        "strategy_info": build_strategy["info"],
        "build_config": build_config
    }

def _apply_docker_build(service_name, build_config, service_type, service_config):
    """Apply Docker build configuration."""
    
    build_context = build_config.get("build_context", "./{}".format(service_name))
    dockerfile = build_config.get("dockerfile", "Dockerfile")
    
    # Get live update rules if supported
    live_update_rules = []
    if service_supports_live_updates(service_type):
        live_update_rules = get_live_update_rules(service_type, build_context)
    
    docker_build(
        service_name,
        context=build_context,
        dockerfile=dockerfile,
        build_args=build_config.get("build_args", {}),
        live_update=live_update_rules
    )

def _apply_custom_build(service_name, build_config):
    """Apply custom build configuration."""
    
    custom_build(
        service_name,
        command=build_config.get("build_command", ""),
        deps=build_config.get("deps", []),
        live_update=build_config.get("live_update", [])
    )

def _apply_external_image(service_name, build_config):
    """Apply external image configuration."""
    
    # For external images, just set the image reference
    # The k8s manifest should reference this image
    pass

def _configure_service_resource(service_name, service_config, service_type):
    """Configure Tilt service resource with ports and labels."""
    
    # Generate port forwards
    port_forwards = []
    ports = service_config.get("ports", [])
    
    for port in ports:
        port_forwards.append("{}:{}".format(port, port))
    
    # Configure k8s resource
    k8s_resource(
        service_name,
        port_forwards=port_forwards,
        labels=[service_name, service_type, 'plugin-managed']
    )

def create_orchestration_dashboard(deployed_services):
    """
    Create a dashboard showing orchestration status.
    
    Args:
        deployed_services (list): List of deployed service info
    """
    
    if not deployed_services:
        return
    
    service_lines = []
    for service in deployed_services:
        live_updates = "✅" if service["live_updates_enabled"] else "❌"
        service_lines.append("  • {} ({}) - {} (Live Updates: {})".format(
            service["name"],
            service["type"], 
            service["plugin_info"]["service_plugin"],
            live_updates
        ))
    
    dashboard_cmd = '''echo "🎭 SERVICE ORCHESTRATION
========================
Deployed Services: {}

Service Details:
{}

Build Strategies Used:
{}

💡 All services deployed using plugin architecture"'''.format(
        len(deployed_services),
        "\\n".join(service_lines),
        "\\n".join(["  • {}: {}".format(s["name"], s["plugin_info"]["build_strategy"]) for s in deployed_services])
    )
    
    local_resource(
        'orchestration-dashboard',
        cmd=dashboard_cmd,
        labels=['framework', 'monitoring']
    )