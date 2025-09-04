"""
Main Tiltfile for x-team-tools development environment
Modular architecture supporting multiple application types: Python, Java, Go, Node.js, CrewAI services

This Tiltfile follows Tilt best practices:
- Modular Starlark files for separation of concerns
- Configuration-driven approach
- Reusable functions and utilities
- Clear error handling and validation
- Comprehensive safety checks
"""

# Load Tilt extensions
load('ext://namespace', 'namespace_create')
load('ext://configmap', 'configmap_create')
load('ext://secret', 'secret_create_generic')

# Load our modular libraries
load('.tilt/lib/config.star', 'parse_tilt_config', 'load_service_config', 'validate_services')
load('.tilt/lib/cluster.star', 'validate_cluster_safety', 'detect_cluster_environment', 'setup_cluster_monitoring')
load('.tilt/lib/namespace.star', 'setup_namespace')
load('.tilt/lib/services.star', 'deploy_service', 'create_deployment_summary')
load('.tilt/lib/dependencies.star', 'setup_service_dependencies')
load('.tilt/lib/monitoring.star', 'setup_monitoring_resources', 'setup_safety_monitoring', 'setup_cleanup_resources')
load('.tilt/lib/builds.star', 'setup_build_monitoring', 'create_live_update_summary')
load('.tilt/lib/error_handling.star', 'setup_error_handling_system', 'validate_environment_safety', 'create_error_recovery_dashboard')

def main():
    """Main Tiltfile execution flow with comprehensive error handling"""
    
    # 0. Setup error handling system first
    try:
        # 1. Parse and validate configuration
        tilt_config = parse_tilt_config()
        service_configs = load_service_config()
        
        # Early environment safety validation
        validate_environment_safety(tilt_config)
        
    except Exception as e:
        fail("""
🚨 CRITICAL STARTUP ERROR

Failed to initialize Tilt environment safely.

Error: {}

IMMEDIATE ACTIONS:
1. Check your cluster context: kubectl config current-context
2. Verify service-config.yaml exists and is valid
3. Ensure you're using a local development cluster
4. Check Tilt configuration parameters

SAFETY FIRST: Cannot proceed without valid configuration and safe environment.
        """.format(str(e)))
    
    # Extract configuration values
    developer_id = tilt_config["developer_id"]
    services_to_deploy = tilt_config["services_to_deploy"]
    debug_mode = tilt_config["debug_mode"]
    build_local_services = tilt_config["build_local_services"]
    cluster_type = tilt_config["cluster_type"]
    
    if debug_mode:
        print("🐛 Debug mode enabled")
        print("Developer ID: " + developer_id)
        print("Services to deploy: " + str(services_to_deploy))
        print("Build locally: " + str(build_local_services))
        print("Cluster type: " + cluster_type)
    
    # 2. Validate cluster safety and setup monitoring
    current_context = validate_cluster_safety(cluster_type, debug_mode)
    cluster_info = detect_cluster_environment(current_context, debug_mode)
    setup_cluster_monitoring(current_context, cluster_info)
    
    # 3. Setup isolated namespace
    namespace = setup_namespace(developer_id, current_context, debug_mode)
    
    # 4. Setup comprehensive error handling and monitoring
    setup_error_handling_system(namespace, services_to_deploy, tilt_config)
    setup_monitoring_resources(namespace, services_to_deploy)
    setup_safety_monitoring()
    setup_cleanup_resources(namespace)
    create_error_recovery_dashboard(namespace, services_to_deploy)
    
    # Import and setup debugging resources
    load('.tilt/lib/monitoring.star', 'setup_debugging_resources')
    setup_debugging_resources(namespace, services_to_deploy)
    
    # 5. Deploy services if specified
    if not services_to_deploy:
        _show_available_services(service_configs)
        return
    
    # Validate requested services exist
    validate_services(services_to_deploy, service_configs)
    
    # Deploy all services using orchestrated deployment
    global_config = service_configs.get('global', {})
    
    # Import the new orchestrated deployment function
    load('.tilt/lib/services.star', 'deploy_services_orchestrated')
    
    deployed_services = deploy_services_orchestrated(
        services_to_deploy,
        service_configs,
        namespace,
        global_config,
        build_local_services,
        developer_id,
        debug_mode,
        tilt_config
    )
    
    # Deploy external services (databases, queues, mock services)
    load('.tilt/lib/external_services.star', 'deploy_external_services')
    
    # Filter external services from the requested services
    external_service_types = ["postgres", "redis", "rabbitmq", "mock"]
    external_services = {}
    
    for service_name in services_to_deploy:
        if service_name in service_configs['services']:
            service_config = service_configs['services'][service_name]
            service_type = service_config.get("type", "generic")
            
            if service_type in external_service_types:
                external_services[service_name] = service_config
    
    # Deploy external services if any are requested
    deployed_externals = []
    if external_services:
        if debug_mode:
            print("🔧 Deploying {} external services: {}".format(len(external_services), list(external_services.keys())))
        
        deployed_externals = deploy_external_services(
            external_services,
            namespace,
            global_config,
            developer_id,
            debug_mode
        )
        
        # Remove external services from regular deployed_services to avoid duplication
        deployed_services = [svc for svc in deployed_services if svc["name"] not in external_services]
    
    # 6. Setup comprehensive service dependencies
    if len(services_to_deploy) > 1:
        deployment_order = setup_service_dependencies(services_to_deploy, service_configs, debug_mode)
        if debug_mode:
            print("✅ Applied comprehensive dependency management for {} services".format(len(services_to_deploy)))
    
    # 7. Setup build monitoring and live update summary
    setup_build_monitoring(deployed_services)
    create_live_update_summary(deployed_services)
    
    # Setup service customization dashboards
    load('.tilt/lib/builds.star', 'create_build_strategy_dashboard', 'create_ecr_version_monitor', 'create_service_customization_validator')
    load('.tilt/lib/config.star', 'create_service_customization_dashboard')
    
    create_build_strategy_dashboard(deployed_services + deployed_externals, tilt_config)
    create_ecr_version_monitor(deployed_services + deployed_externals)
    create_service_customization_validator(deployed_services + deployed_externals, tilt_config)
    create_service_customization_dashboard(tilt_config, service_configs)
    
    # 8. Create deployment summary and service dashboard
    all_deployed_services = deployed_services + deployed_externals
    create_deployment_summary(all_deployed_services, namespace, developer_id)
    
    # Setup comprehensive service dashboard
    load('.tilt/lib/monitoring.star', 'setup_service_dashboard')
    setup_service_dashboard(all_deployed_services, namespace)
    
    # Setup endpoint dashboard
    load('.tilt/lib/services.star', 'create_endpoint_dashboard')
    create_endpoint_dashboard(all_deployed_services, namespace)
    
    # 9. Print success message
    _print_success_message(current_context, cluster_info, namespace, deployed_services)

def _show_available_services(service_configs):
    """Show available services when none are specified"""
    
    # Import and create service selection guide
    load('.tilt/lib/config.star', 'create_service_selection_guide')
    create_service_selection_guide(service_configs)
    
    available_services = list(service_configs.get('services', {}).keys())
    print("ℹ️  No services specified. Use --services flag to specify which services to deploy.")
    print("📦 Available services: " + str(available_services))
    print("")
    print("💡 Example usage:")
    print("  tilt up -- --services=database,redis,ai-agentic-mdr-oscar")
    print("  tilt up -- --services=ai-agentic-mdr-oscar --build_local=ai-agentic-mdr-oscar")
    print("")
    print("📋 Check the 'service-selection-guide' resource in Tilt UI for detailed information")

def _print_success_message(current_context, cluster_info, namespace, deployed_services):
    """Print success message with environment details"""
    
    print("")
    print("🛡️  SAFETY-FIRST TILT DEVELOPMENT ENVIRONMENT 🛡️")
    print("=" * 60)
    print("✅ Cluster Context: " + current_context)
    print("✅ Cluster Type: " + cluster_info['type'])
    print("✅ API Server: " + cluster_info['api_server'])
    print("✅ Safety Validated: " + str(cluster_info['is_safe']))
    print("✅ Namespace: " + namespace)
    print("=" * 60)
    print("🔒 SAFETY MEASURES ACTIVE:")
    print("   • Staging/Production contexts are BLOCKED")
    print("   • Only local development clusters allowed")
    print("   • API server locality verified")
    print("   • Dangerous context patterns detected and prevented")
    print("=" * 60)
    total_services = len(deployed_services) + len(deployed_externals)
    print("📦 Deployed {} services successfully ({} application services, {} external services)".format(
        total_services, len(deployed_services), len(deployed_externals)
    ))
    print("")
    print("🚀 Ready for safe local development!")

# Execute main function
main()