"""
Simplified Tiltfile for x-team-tools
Following Tilt best practices: simple, direct, and focused on fast feedback loops
"""

# Load minimal required extensions
load('ext://namespace', 'namespace_create')

# Load our simplified modules
load('.tilt/config.star', 'parse_config', 'load_service_config', 'load_environments')
load('.tilt/services.star', 'deploy_service')

# Safety check - MUST be first
def validate_cluster_safety():
    """Simple safety check to prevent production deployment"""
    context = str(local("kubectl config current-context", quiet=True)).strip()
    
    # Block production contexts
    blocked_patterns = ["prod", "production", "aws", "eks", "gcp", "gke", "azure", "aks"]
    for pattern in blocked_patterns:
        if pattern in context.lower():
            fail("🚨 SAFETY: Blocked context '{}'. Tilt is for local development only!".format(context))
    
    # Verify local contexts
    allowed = ["docker-desktop", "minikube", "kind", "k3s", "rancher", "colima", "orbstack"]
    is_allowed = False
    for a in allowed:
        if a in context.lower():
            is_allowed = True
            break
    if not is_allowed:
        print("⚠️  Warning: Unrecognized context '{}'. Proceeding with caution.".format(context))
    
    print("✅ Cluster context validated: {}".format(context))
    return context

# Main execution
def main():
    """Main Tiltfile execution - simple and direct"""
    
    # 1. Safety check
    context = validate_cluster_safety()
    
    # 2. Parse configuration
    config = parse_config()
    service_configs = load_service_config()
    environments = load_environments()
    
    developer_id = config.get("developer_id", os.getenv("USER", "developer"))
    services_to_deploy = config.get("services", [])
    environment = config.get("environment", "")
    debug = config.get("debug", False)
    
    # 3. Setup namespace
    namespace = "dev-" + developer_id
    namespace_create(namespace)
    print("📦 Using namespace: {}".format(namespace))
    
    # 4. Determine services to deploy
    if environment and environment in environments:
        # Deploy environment
        services_to_deploy = environments[environment].get("services", [])
        print("🚀 Deploying environment '{}': {}".format(environment, services_to_deploy))
    elif not services_to_deploy:
        # Show available options
        print("\n📋 Available services:")
        for name in service_configs.get("services", {}).keys():
            print("  - {}".format(name))
        print("\n📋 Available environments:")
        for name, env in environments.items():
            if name != "global":
                print("  - {}: {}".format(name, env.get("description", "")))
        print("\n💡 Usage:")
        print("  tilt up -- --services=database,redis")
        print("  tilt up -- --environment=backend-only")
        return
    
    # 5. Deploy services
    print("\n🚀 Deploying {} services...".format(len(services_to_deploy)))
    
    for service_name in services_to_deploy:
        if service_name not in service_configs["services"]:
            fail("❌ Service '{}' not found in configuration".format(service_name))
        
        service_config = service_configs["services"][service_name]
        # Pass the list of services being deployed for dependency filtering
        deploy_service(service_name, service_config, namespace, developer_id, debug, services_to_deploy)
    
    # 6. Print summary
    print("\n✅ Deployment complete!")
    print("📍 Namespace: {}".format(namespace))
    print("🔧 Services: {}".format(", ".join(services_to_deploy)))
    print("🌐 Access Tilt UI at: http://localhost:10350")

# Execute
main()