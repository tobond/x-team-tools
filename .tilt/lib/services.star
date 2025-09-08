"""
Service deployment and management
Handles complete service deployment with k8s resources, monitoring, and configuration
"""

# Load all required modules at top level (required by Starlark)
load('k8s_manifests.star', 'generate_k8s_manifests')
load('config_secrets.star', 'create_service_configmap', 'create_service_secret')
load('builds.star', 'setup_build_strategy', 'validate_build_requirements', 'get_build_info', 'optimize_docker_build_context')
load('config.star', 'apply_service_customizations')
load('error_handling.star', 'handle_service_deployment_error')

def generate_unique_port_forwards(service_name, ports):
    """Generate port forwards using exactly the ports specified by developer configuration
    
    No dynamic allocation, no hashing - simply use the ports as configured by the developer.
    """
    if not ports:
        return []
    
    port_forwards = []
    for container_port in ports:
        # Use the exact port specified by the developer configuration
        port_forwards.append("{}:{}".format(container_port, container_port))
    
    return port_forwards

def deploy_service(service_name, service_config, namespace, global_config, developer_id, debug_mode=False, tilt_config=None):
    """Deploy a service using Tilt best practices with automatic build detection"""

    if tilt_config:
        service_config = apply_service_customizations(service_name, service_config, tilt_config)

    app_type = service_config.get("type", "generic")

    if debug_mode:
        print("🚀 Deploying service: " + service_name)

    validate_build_requirements(service_name, service_config, debug_mode)

    # Use auto-detection for build optimization
    if service_config.get("build_context") or service_config.get("build_command"):
        optimize_docker_build_context(".", app_type)

    build_info = get_build_info(service_name, service_config)
    create_service_configmap(service_name, service_config, namespace, debug_mode)
    create_service_secret(service_name, service_config, namespace, debug_mode)

    build_result = setup_build_strategy(service_name, service_config, debug_mode)
    image_name = build_result["image_name"]

    manifests = generate_k8s_manifests(
        service_name, service_config, namespace, image_name, global_config, developer_id
    )

    k8s_yaml(blob(manifests))

    # Generate unique port forwards to avoid local port conflicts
    port_forwards = generate_unique_port_forwards(service_name, service_config.get("ports", []))
    
    k8s_resource(
        service_name,
        port_forwards=port_forwards,
        labels=[service_name]
    )

    return {
        "name": service_name,
        "type": service_config.get("type", "generic"),
        "ports": service_config.get("ports", []),
        "image": image_name,
        "build_locally": build_result.get("build_locally", True)
    }

def deploy_services_orchestrated(services_to_deploy, service_configs, namespace, global_config, developer_id, debug_mode=False, tilt_config=None):
    """Deploy multiple services using automatic build detection"""
    deployed_services = []

    for service_name in services_to_deploy:
        if service_name in service_configs['services']:
            service_config = service_configs['services'][service_name]
            deployment_result = deploy_service(
                service_name, service_config, namespace, global_config,
                developer_id, debug_mode, tilt_config
            )
            deployed_services.append(deployment_result)

    return deployed_services

def create_deployment_summary(deployed_services, namespace, developer_id):
    """Create deployment summary"""
    local_resource(
        'deployment-summary',
        cmd='echo "Deployed {} services in namespace {}"'.format(len(deployed_services), namespace),
        labels=['summary']
    )

def create_endpoint_dashboard(deployed_services, namespace):
    """Create endpoint dashboard"""
    if deployed_services:
        local_resource(
            'endpoint-dashboard',
            cmd='echo "Service endpoints available"',
            labels=['endpoints']
        )

def create_port_mapping_dashboard(deployed_services):
    """Create dynamic dashboard showing actual port mappings for deployed services"""
    
    if not deployed_services:
        return
    
    # Generate dynamic port mappings for each deployed service
    mapping_lines = []
    for service in deployed_services:
        service_name = service["name"]
        service_ports = service.get("ports", [])
        
        if service_ports:
            # Generate the same port forwards that were actually created
            port_forwards = generate_unique_port_forwards(service_name, service_ports)
            for port_forward in port_forwards:
                local_port, container_port = port_forward.split(":")
                mapping_lines.append("  {} -> localhost:{}:{}".format(
                    service_name, local_port, container_port
                ))
        else:
            mapping_lines.append("  {} -> (no ports exposed)".format(service_name))
    
    # Build dynamic command with actual service mappings
    mappings_text = "\\n".join(mapping_lines)
    mapping_cmd = '''echo "🔗 PORT MAPPING DASHBOARD
======================
Service -> localhost:local_port:container_port

{}

💡 Access your services at the local ports above"'''.format(mappings_text)
    
    local_resource(
        'port-mapping-dashboard',
        cmd=mapping_cmd,
        labels=['monitoring']
    )
