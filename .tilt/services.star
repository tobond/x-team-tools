"""
Service deployment using Tilt best practices
Simple, direct use of docker_build() and k8s_resource()
"""

def deploy_service(service_name, service_config, namespace, developer_id, debug=False, deployed_services=None):
    """Deploy a service using simple Tilt primitives
    
    Args:
        deployed_services: List of services that are being deployed (for dependency filtering)
    """
    
    service_type = service_config.get("type", "generic")
    
    if debug:
        print("  Deploying {}: type={}".format(service_name, service_type))
    
    # Build or use external image
    if service_type == "external":
        # External service (database, redis, etc.)
        image = service_config.get("image", "")
        if not image:
            fail("External service {} requires 'image' field".format(service_name))
    else:
        # Build image for application services
        image = build_service_image(service_name, service_config, service_type, namespace)
    
    # Create Kubernetes manifests
    manifests = generate_k8s_manifests(service_name, service_config, namespace, image)
    k8s_yaml(blob(manifests))
    
    # Configure resource with port forwarding
    ports = service_config.get("ports", [])
    port_forwards = ["{}:{}".format(p, p) for p in ports]
    
    # Set up resource dependencies (only for services actually being deployed)
    deps = []
    deployed_services = deployed_services or []
    for dep in service_config.get("dependencies", []):
        # Only add dependency if that service is actually being deployed
        if dep in deployed_services:
            deps.append(dep)
    
    # Create Kubernetes resource with appropriate label
    # External services (databases, redis, etc.) get their own group
    if service_type == "external":
        resource_label = "infrastructure"
    else:
        resource_label = "services"
    
    k8s_resource(
        service_name,
        port_forwards=port_forwards,
        resource_deps=deps,
        labels=[resource_label]
    )

def build_service_image(service_name, service_config, service_type, namespace):
    """Build Docker image using docker_build with live updates"""
    
    # Use a simpler image name that Tilt can properly track
    image_name = "tilt-{}-{}".format(namespace.replace("dev-", ""), service_name)
    build_context = service_config.get("build_context", "./services/{}".format(service_name))
    dockerfile_path = service_config.get("dockerfile", "{}/Dockerfile".format(build_context))
    
    # Check if the build context exists
    if not os.path.exists(build_context):
        fail("Build context not found for {}: {}".format(service_name, build_context))
    
    # Check if Dockerfile exists
    if not os.path.exists(dockerfile_path):
        fail("Dockerfile not found for {}: {}".format(service_name, dockerfile_path))
    
    # Configure live updates based on service type
    live_updates = get_live_updates(service_type, build_context)
    
    # Use docker_build (Tilt best practice)
    docker_build(
        image_name,
        context=build_context,
        dockerfile=dockerfile_path,
        live_update=live_updates if live_updates else []
    )
    
    return image_name

def get_live_updates(service_type, build_context):
    """Get live update configuration based on service type"""
    
    if service_type == "python":
        return [
            # Sync all Python files to the container
            sync(build_context + '/', '/app/'),
            # Uvicorn with --reload will auto-restart when files change
            # No need for manual restart since CMD uses --reload flag
        ]
    elif service_type == "nodejs" or service_type == "node":
        return [
            sync(build_context + '/src', '/app/src'),
            sync(build_context + '/package*.json', '/app/'),
            run('npm install', 
                trigger=[build_context + '/package.json'])
        ]
    elif service_type == "java":
        return [
            sync(build_context + '/src', '/app/src'),
            sync(build_context + '/pom.xml', '/app/pom.xml'),
            run('mvn compile', 
                trigger=[build_context + '/pom.xml'])
        ]
    elif service_type == "go":
        return [
            sync(build_context + '/cmd', '/app/cmd'),
            sync(build_context + '/pkg', '/app/pkg'),
            sync(build_context + '/go.*', '/app/'),
            run('go build -o /app/main ./cmd', 
                trigger=[build_context + '/**/*.go'])
        ]
    elif service_type == "crewai":
        # CrewAI services are Python-based, similar to regular Python services
        return [
            sync(build_context + '/', '/app/'),
            # CrewAI agents typically use Python, may need custom restart logic
        ]
    
    return []

def generate_k8s_manifests(service_name, service_config, namespace, image):
    """Generate simple Kubernetes manifests"""
    
    # Get configuration
    ports = service_config.get("ports", [8080])
    env_vars = service_config.get("env_vars", [])
    resources = service_config.get("resources", {})
    health_check = service_config.get("health_check", {})
    
    # Build environment variables
    env_yaml = ""
    for env in env_vars:
        env_yaml += """
        - name: {}
          value: "{}"
""".format(env.get("name"), env.get("value"))
    
    # Build container ports
    ports_yaml = ""
    for port in ports:
        ports_yaml += """
        - containerPort: {}
          protocol: TCP
""".format(port)
    
    # Build health checks
    health_yaml = ""
    if health_check:
        if health_check.get("path"):
            health_yaml = """
        livenessProbe:
          httpGet:
            path: {}
            port: {}
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: {}
            port: {}
          initialDelaySeconds: 5
          periodSeconds: 5
""".format(
                health_check.get("path", "/health"),
                health_check.get("port", ports[0] if ports else 8080),
                health_check.get("path", "/health"),
                health_check.get("port", ports[0] if ports else 8080)
            )
        elif health_check.get("command"):
            cmd_list = str(health_check.get("command"))
            health_yaml = """
        livenessProbe:
          exec:
            command: {}
          initialDelaySeconds: 30
          periodSeconds: 10
""".format(cmd_list)
    
    # Generate manifests
    manifests = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {}
  namespace: {}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {}
  template:
    metadata:
      labels:
        app: {}
    spec:
      containers:
      - name: {}
        image: {}
        ports:
{}
        env:
{}
{}
        resources:
          requests:
            memory: "{}"
            cpu: "{}"
          limits:
            memory: "{}"
            cpu: "{}"
---
apiVersion: v1
kind: Service
metadata:
  name: {}
  namespace: {}
spec:
  selector:
    app: {}
  ports:
{}
  type: ClusterIP
""".format(
        service_name, namespace,  # deployment name, namespace
        service_name,              # selector
        service_name,              # label
        service_name,              # container name
        image,                     # image
        ports_yaml,                # container ports
        env_yaml,                  # environment variables
        health_yaml,               # health checks
        resources.get("memory", "256Mi"),  # memory request
        resources.get("cpu", "100m"),      # cpu request
        resources.get("memory", "256Mi"),  # memory limit
        resources.get("cpu", "100m"),      # cpu limit
        service_name, namespace,   # service name, namespace
        service_name,              # service selector
        generate_service_ports(ports)  # service ports
    )
    
    return manifests

def generate_service_ports(ports):
    """Generate service port configuration"""
    if not ports:
        return """
  - port: 8080
    targetPort: 8080
    protocol: TCP"""
    
    result = ""
    for port in ports:
        result += """
  - port: {}
    targetPort: {}
    protocol: TCP""".format(port, port)
    
    return result