"""
Service deployment and management
Handles complete service deployment with k8s resources, monitoring, and configuration
"""

# Load all required modules at top level (required by Starlark)
load('k8s_manifests.star', 'generate_k8s_manifests')
load('config_secrets.star', 'create_service_configmap', 'create_service_secret')
load('builds.star', 'setup_build_strategy', 'validate_build_requirements', 'get_build_info', 'optimize_docker_build_context')
load('config.star', 'apply_service_customizations', 'get_effective_build_strategy')
load('error_handling.star', 'handle_service_deployment_error')

def generate_unique_port_forwards(service_name, ports):
    """Generate unique local port forwards for a service to avoid conflicts
    
    Uses a dynamic port allocation strategy based on:
    1. Standard ports (5432 for postgres, 6379 for redis, etc.) get preserved when possible
    2. Hash-based port allocation to avoid conflicts between services
    3. Sequential allocation for services with multiple ports
    """
    if not ports:
        return []
    
    # Standard service ports that should be preserved to maintain developer familiarity
    standard_ports = {
        5432: 5432,  # PostgreSQL
        6379: 6379,  # Redis
        3306: 3306,  # MySQL
        27017: 27017,  # MongoDB
        9200: 9200,  # Elasticsearch
    }
    
    port_forwards = []
    for i, container_port in enumerate(ports):
        # Use standard port if it matches and this is the first port
        if i == 0 and container_port in standard_ports:
            local_port = standard_ports[container_port]
        else:
            # Generate deterministic but unique port based on service name and port number
            # Base range: 8000-9999 for application services
            hash_input = service_name + str(container_port) + str(i)
            port_hash = abs(hash(hash_input)) % 2000  # 0-1999
            local_port = 8000 + port_hash
            
            # Avoid conflicts with standard ports
            while local_port in standard_ports.values():
                local_port = local_port + 1 if local_port < 9999 else 8000
        
        port_forwards.append("{}:{}".format(local_port, container_port))
    
    return port_forwards

def deploy_service(service_name, service_config, namespace, global_config, build_local_services, developer_id, debug_mode=False, tilt_config=None):
    """Deploy a service using Tilt best practices"""

    if tilt_config:
        service_config = apply_service_customizations(service_name, service_config, tilt_config)
        build_strategy = get_effective_build_strategy(service_name, service_config, tilt_config)
        build_locally = build_strategy == "local"
    else:
        build_locally = service_name in build_local_services

    app_type = service_config.get("type", "generic")

    if debug_mode:
        print("🚀 Deploying service: " + service_name)

    validate_build_requirements(service_name, service_config, build_locally)

    if build_locally:
        optimize_docker_build_context(".", app_type)

    build_info = get_build_info(service_name, service_config, build_local_services)
    create_service_configmap(service_name, service_config, namespace, debug_mode)
    create_service_secret(service_name, service_config, namespace, debug_mode)

    build_result = setup_build_strategy(service_name, service_config, build_local_services, debug_mode)
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
        "build_locally": build_result["build_locally"]
    }

def deploy_services_orchestrated(services_to_deploy, service_configs, namespace, global_config, build_local_services, developer_id, debug_mode=False, tilt_config=None):
    """Deploy multiple services"""
    deployed_services = []

    for service_name in services_to_deploy:
        if service_name in service_configs['services']:
            service_config = service_configs['services'][service_name]
            deployment_result = deploy_service(
                service_name, service_config, namespace, global_config,
                build_local_services, developer_id, debug_mode, tilt_config
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
