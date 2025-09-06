"""
Kubernetes manifest generation system
Handles dynamic manifest creation with proper templating and configuration
"""

def generate_k8s_manifests(service_name, service_config, namespace, image_name, global_config, developer_id):
    """Generate comprehensive Kubernetes manifests using simple string building"""

    # Extract service configuration
    ports = service_config.get("ports", [8080])
    env_vars = service_config.get("env_vars", [])
    service_type = service_config.get("type", "generic")
    timestamp = str(local('date -u +"%Y-%m-%dT%H:%M:%SZ"')).strip()

    # Build container spec sections
    container_ports_section = ""
    if ports:
        container_ports_section = "\n        ports:"
        for port in ports:
            container_ports_section += "\n        - name: port-" + str(port)
            container_ports_section += "\n          containerPort: " + str(port)
            container_ports_section += "\n          protocol: TCP"

    env_section = ""
    if env_vars:
        env_section = "\n        env:"
        for env in env_vars:
            env_section += "\n        - name: " + env["name"]
            env_section += "\n          value: \"" + env["value"] + "\""

    # Build service ports section
    service_ports_section = ""
    if ports:
        service_ports_section = "\n  ports:"
        for port in ports:
            service_ports_section += "\n  - name: port-" + str(port)
            service_ports_section += "\n    port: " + str(port)
            service_ports_section += "\n    targetPort: " + str(port)
            service_ports_section += "\n    protocol: TCP"

    # Build the manifest using string concatenation to avoid indentation issues
    manifest = "apiVersion: apps/v1\n"
    manifest += "kind: Deployment\n"
    manifest += "metadata:\n"
    manifest += "  name: " + service_name + "\n"
    manifest += "  namespace: " + namespace + "\n"
    manifest += "  labels:\n"
    manifest += "    app: " + service_name + "\n"
    manifest += "    tilt.dev/resource: " + service_name + "\n"
    manifest += "    tilt.dev/type: " + service_type + "\n"
    manifest += "    tilt.dev/developer: " + developer_id + "\n"
    manifest += "    version: dev\n"
    manifest += "  annotations:\n"
    manifest += "    tilt.dev/created-by: \"tilt\"\n"
    manifest += "    tilt.dev/created-at: \"" + timestamp + "\"\n"
    manifest += "spec:\n"
    manifest += "  replicas: 1\n"
    manifest += "  selector:\n"
    manifest += "    matchLabels:\n"
    manifest += "      app: " + service_name + "\n"
    manifest += "  template:\n"
    manifest += "    metadata:\n"
    manifest += "      labels:\n"
    manifest += "        app: " + service_name + "\n"
    manifest += "        tilt.dev/resource: " + service_name + "\n"
    manifest += "        version: dev\n"
    manifest += "    spec:\n"
    manifest += "      containers:\n"
    manifest += "      - name: " + service_name + "\n"
    manifest += "        image: " + image_name + "\n"
    manifest += "        imagePullPolicy: Always"
    manifest += container_ports_section
    manifest += env_section
    manifest += "\n        resources:\n"
    manifest += "          requests:\n"
    manifest += "            cpu: \"100m\"\n"
    manifest += "            memory: \"128Mi\"\n"
    manifest += "          limits:\n"
    manifest += "            cpu: \"500m\"\n"
    manifest += "            memory: \"512Mi\"\n"
    manifest += "---\n"
    manifest += "apiVersion: v1\n"
    manifest += "kind: Service\n"
    manifest += "metadata:\n"
    manifest += "  name: " + service_name + "\n"
    manifest += "  namespace: " + namespace + "\n"
    manifest += "  labels:\n"
    manifest += "    app: " + service_name + "\n"
    manifest += "spec:\n"
    manifest += "  selector:\n"
    manifest += "    app: " + service_name
    manifest += service_ports_section
    manifest += "\n  type: ClusterIP\n"

    return manifest
