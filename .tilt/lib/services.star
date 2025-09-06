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
    """Generate unique local port forwards for a service to avoid conflicts"""
    if not ports:
        return []
    
    # Simple port mapping: service index determines base port
    # ai-agentic-test-app -> 8000, user-service -> 8001, test-service -> 8002, etc.
    service_port_map = {
        "ai-agentic-test-app": 8000,
        "user-service": 8001, 
        "test-service": 8002,
        "database": 5432,
        "redis": 6379,
        "rabbitmq": 5672,
    }
    
    base_local_port = service_port_map.get(service_name, 8000 + hash(service_name) % 100)
    
    port_forwards = []
    for i, container_port in enumerate(ports):
        local_port = base_local_port + i
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

def create_port_mapping_dashboard():
    """Create dashboard showing port mappings to help developers"""
    mapping_cmd = '''echo "🔗 PORT MAPPING DASHBOARD
======================
Service -> localhost:local_port:container_port

  ai-agentic-test-app -> localhost:8000:8000
  user-service -> localhost:8001:8000  
  test-service -> localhost:8002:8000
  database -> localhost:5432:5432
  redis -> localhost:6379:6379
  rabbitmq -> localhost:5672:5672

💡 Access your services at the local ports above"'''
    
    local_resource(
        'port-mapping-dashboard',
        cmd=mapping_cmd,
        labels=['monitoring']
    )
