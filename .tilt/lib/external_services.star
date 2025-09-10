"""
External service and dependency management - FULLY SERVICE-AGNOSTIC

This module uses a completely configuration-driven approach. Adding new external services 
requires NO code changes - everything is configured in .tilt/service-config.yaml.

ADDING NEW EXTERNAL SERVICES:
To add any external service (MySQL, MongoDB, Kafka, Elasticsearch, etc.), simply add it to 
.tilt/service-config.yaml:

  my-new-service:
    type: "external"
    image: "mysql:8.0"     # Any Docker image
    ports: [3306]          # Exposed ports  
    env_vars:              # Environment variables
      - name: "MYSQL_ROOT_PASSWORD"
        value: "mypassword"
    resources:             # Resource limits
      cpu: "500m"
      memory: "1Gi"
    health_check:          # Health check command
      command: ["mysqladmin", "ping", "-h", "localhost"]

No code changes required - everything is configuration-driven and service-agnostic.
"""

# Import the port forwarding function from services.star
load('services.star', 'generate_unique_port_forwards')

def generate_k8s_manifests(service_name, service_config, namespace, image_name, global_config, developer_id):
    """Generate basic Kubernetes manifests - simplified version for external services"""

    ports = service_config.get("ports", [8080])
    env_vars = service_config.get("env_vars", [])
    resources = service_config.get("resources", {"cpu": "100m", "memory": "128Mi"})

    # Generate basic deployment and service manifests
    deployment_yaml = """apiVersion: apps/v1
kind: Deployment
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
    app: {service_name}
    developer: {developer_id}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {service_name}
  template:
    metadata:
      labels:
        app: {service_name}
        developer: {developer_id}
    spec:
      containers:
      - name: {service_name}
        image: {image_name}
        imagePullPolicy: IfNotPresent
        ports:
{port_config}
        resources:
          requests:
            cpu: {cpu}
            memory: {memory}
          limits:
            cpu: {cpu}
            memory: {memory}
---
apiVersion: v1
kind: Service
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
    app: {service_name}
    developer: {developer_id}
spec:
  selector:
    app: {service_name}
  ports:
{service_ports}
  type: ClusterIP
""".format(
        service_name=service_name,
        namespace=namespace,
        developer_id=developer_id,
        image_name=image_name,
        port_config='\n'.join(['        - containerPort: {}'.format(port) for port in ports]),
        service_ports='\n'.join(['  - port: {}\n    targetPort: {}'.format(port, port) for port in ports]),
        cpu=resources.get("cpu", "100m"),
        memory=resources.get("memory", "128Mi")
    )

    return deployment_yaml

def create_service_configmap(service_name, service_config, namespace, debug_mode):
    """Create ConfigMap for service configuration"""

    env_vars = service_config.get("env_vars", [])
    configmap_data = {}

    for env_var in env_vars:
        if env_var.get("from_configmap", False):
            key = env_var["name"].lower().replace("_", "_")
            configmap_data[key] = env_var["value"]

    if configmap_data:
        configmap_yaml = """apiVersion: v1
kind: ConfigMap
metadata:
  name: {service_name}-config
  namespace: {namespace}
  labels:
    app: {service_name}
data:
{data}
""".format(
            service_name=service_name,
            namespace=namespace,
            data='\n'.join(['  {}: "{}"'.format(k, v) for k, v in configmap_data.items()])
        )

        k8s_yaml(configmap_yaml)

def create_service_secret(service_name, service_config, namespace, debug_mode):
    """Create Secret for sensitive service configuration"""

    env_vars = service_config.get("env_vars", [])
    secret_data = {}

    for env_var in env_vars:
        if env_var.get("from_secret", False):
            key = env_var["name"].lower().replace("_", "_")
            secret_data[key] = env_var["value"]

    if secret_data:
        secret_yaml = """apiVersion: v1
kind: Secret
metadata:
  name: {service_name}-secret
  namespace: {namespace}
  labels:
    app: {service_name}
type: Opaque
stringData:
{data}
""".format(
            service_name=service_name,
            namespace=namespace,
            data='\n'.join(['  {}: "{}"'.format(k, v) for k, v in secret_data.items()])
        )

        k8s_yaml(secret_yaml)

def deploy_external_services(external_services, namespace, global_config, developer_id, debug_mode=False):
    """Deploy external services using fully generic, configuration-driven approach"""
    
    deployed_externals = []
    
    for service_name, service_config in external_services.items():
        if debug_mode:
            print("🔧 Deploying external service: {} (image: {})".format(
                service_name, 
                service_config.get("image", "not specified")
            ))
        
        # Use single generic deployment function for all external services
        result = deploy_generic_external_service(
            service_name, service_config, namespace, global_config, developer_id, debug_mode
        )
        deployed_externals.append(result)
    
    # Setup external service monitoring
    setup_external_service_monitoring(deployed_externals, namespace, developer_id, debug_mode)
    
    return deployed_externals

def deploy_generic_external_service(service_name, service_config, namespace, global_config, developer_id, debug_mode=False):
    """Deploy generic external service using configuration-driven approach"""
    
    # Create ConfigMaps and Secrets
    create_service_configmap(service_name, service_config, namespace, debug_mode)
    create_service_secret(service_name, service_config, namespace, debug_mode)
    
    # Get image from service configuration - priority: image > ecr_image > default
    image_name = service_config.get("image") or service_config.get("ecr_image", "alpine:latest")
    
    # Generate manifests using existing k8s_manifests.star function
    manifests = generate_k8s_manifests(
        service_name, service_config, namespace, image_name, global_config, developer_id
    )
    
    # Apply manifests
    k8s_yaml(manifests, allow_duplicates=False, validate=True)
    
    # Configure k8s resource with flexible port forwarding
    ports = service_config.get("ports", [])
    service_type = service_config.get("type", "external")
    
    # Generate unique port forwards to avoid conflicts
    port_forwards = generate_unique_port_forwards(service_name, ports) if ports else []
    
    k8s_resource(
        service_name,
        port_forwards=port_forwards,
        labels=[
            "category:external",
            "type:" + service_type,
            "developer:" + developer_id,
            "tier:service",
            "image:" + image_name.split(":")[0].replace("/", "_") if image_name else "unknown"
        ],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL,
        pod_readiness="wait"
    )
    
    # Add optional initialization commands if specified in config
    init_commands = service_config.get("init_commands", [])
    if init_commands and debug_mode:
        print("Service {} has {} initialization commands".format(service_name, len(init_commands)))
    
    return {
        "name": service_name,
        "type": service_config.get("type", "generic"),
        "ports": ports,
        "developer_id": developer_id
    }

def setup_external_service_monitoring(deployed_externals, namespace, developer_id, debug_mode):
    """Setup comprehensive monitoring for all external services"""
    
    if not deployed_externals:
        return
    
    # Group services by type for generic monitoring
    service_groups = {}
    for svc in deployed_externals:
        service_type = svc.get("type", "generic")
        if service_type not in service_groups:
            service_groups[service_type] = []
        service_groups[service_type].append(svc)
    
    local_resource(
        'external-services-dashboard',
        labels=['services'],
        cmd='''
        echo "=== EXTERNAL SERVICES DASHBOARD ==="
        echo "Developer: {}"
        echo "Namespace: {}"
        echo "Total Services: {}"
        echo ""
        
        echo "🔧 SERVICES BY TYPE"
        echo "==================="
        ''' + '\n        '.join([
            '''
        echo "📊 {} Services ({})"
        echo "{}:"
        {}
        echo ""'''.format(
                service_type.upper(),
                len(services),
                service_type,
                '\n        '.join([
                    '''POD_NAME=$(kubectl get pods -n {} -l app={} -o jsonpath='{{.items[0].metadata.name}}' 2>/dev/null)
        if [ -n "$POD_NAME" ]; then
            echo "   ✅ {} (Pod: $POD_NAME)"
            echo "   🔗 Ports: {}"
        else
            echo "   ❌ {} - Not running"
        fi'''.format(
                        namespace, svc["name"], svc["name"], 
                        ', '.join([str(p) for p in svc.get("ports", [])]) if svc.get("ports") else "none",
                        svc["name"]
                    ) for svc in services
                ])
            ) for service_type, services in service_groups.items()
        ]) + '''
        
        echo "🔧 MANAGEMENT COMMANDS"
        echo "====================="
        echo "View all pods: kubectl get pods -n {}"
        echo "View all services: kubectl get svc -n {}"
        echo "View all PVCs: kubectl get pvc -n {}"
        echo ""
        echo "💡 Use individual service monitors for detailed information"
        '''.format(
            developer_id, namespace, len(deployed_externals),
            namespace, namespace, namespace
        ),
        deps=[svc["name"] for svc in deployed_externals],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL
    )