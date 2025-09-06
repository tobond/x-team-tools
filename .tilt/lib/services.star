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

    k8s_resource(
        service_name,
        port_forwards=service_config.get("ports", []),
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
