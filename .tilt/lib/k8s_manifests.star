"""
Kubernetes manifest generation system
Handles dynamic manifest creation with proper templating and configuration
"""

def generate_k8s_manifests(service_name, service_config, namespace, image_name, global_config, developer_id):
    """Generate comprehensive Kubernetes manifests using Tilt's templating capabilities"""
    
    # Extract service configuration
    ports = service_config.get("ports", [8080])
    env_vars = service_config.get("env_vars", [])
    resources = service_config.get("resources", {})
    health_check = service_config.get("health_check", {"path": "/health", "port": ports[0] if ports else 8080})
    service_type = service_config.get("type", "generic")
    
    # Get defaults from global configuration
    default_resources = global_config.get("default_resources", {"cpu": "100m", "memory": "128Mi"})
    default_health = global_config.get("default_health_check", {
        "initial_delay_seconds": 30,
        "period_seconds": 10,
        "timeout_seconds": 5,
        "failure_threshold": 3
    })
    default_readiness = global_config.get("default_readiness_check", {
        "initial_delay_seconds": 5,
        "period_seconds": 5,
        "timeout_seconds": 3,
        "failure_threshold": 3
    })
    
    # Generate manifest components
    env_yaml = _generate_env_vars(env_vars, service_name)
    ports_yaml = _generate_container_ports(ports)
    resources_yaml = _generate_resources(resources, default_resources)
    service_ports_yaml = _generate_service_ports(ports)
    liveness_probe, readiness_probe = _generate_probes(service_type, health_check, default_health, default_readiness)
    labels_yaml = _generate_labels(service_name, service_type, developer_id)
    
    # Build complete manifest
    deployment_yaml = """apiVersion: apps/v1
kind: Deployment
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
{labels_yaml}  annotations:
    tilt.dev/created-by: "tilt"
    tilt.dev/created-at: "{timestamp}"
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app: {service_name}
  template:
    metadata:
      labels:
{labels_yaml}      annotations:
        tilt.dev/restart-count: "0"
    spec:
      restartPolicy: Always
      containers:
      - name: {service_name}
        image: {image_name}
        imagePullPolicy: Always
{ports_yaml}{env_yaml}{resources_yaml}{liveness_probe}{readiness_probe}        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: false
          capabilities:
            drop:
            - ALL
---
apiVersion: v1
kind: Service
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
{labels_yaml}  annotations:
    tilt.dev/created-by: "tilt"
spec:
  selector:
    app: {service_name}
{service_ports_yaml}  type: ClusterIP
  sessionAffinity: None
""".format(
        service_name=service_name,
        namespace=namespace,
        image_name=image_name,
        labels_yaml=labels_yaml,
        ports_yaml=ports_yaml,
        env_yaml=env_yaml,
        resources_yaml=resources_yaml,
        liveness_probe=liveness_probe,
        readiness_probe=readiness_probe,
        service_ports_yaml=service_ports_yaml,
        timestamp=str(local('date -u +"%Y-%m-%dT%H:%M:%SZ"')).strip()
    )
    
    return deployment_yaml

def _generate_env_vars(env_vars, service_name):
    """Generate environment variables YAML with ConfigMap and Secret references"""
    
    if not env_vars:
        return ""
    
    env_yaml = "        env:\n"
    for env in env_vars:
        if env.get("from_configmap"):
            env_yaml += """        - name: {}
          valueFrom:
            configMapKeyRef:
              name: {}-config
              key: {}
""".format(env["name"], service_name, env.get("key", env["name"].lower()))
        elif env.get("from_secret"):
            env_yaml += """        - name: {}
          valueFrom:
            secretKeyRef:
              name: {}-secret
              key: {}
""".format(env["name"], service_name, env.get("key", env["name"].lower()))
        else:
            env_yaml += "        - name: {}\n          value: \"{}\"\n".format(env["name"], env["value"])
    
    return env_yaml

def _generate_container_ports(ports):
    """Generate container ports YAML with proper naming"""
    
    if not ports:
        return ""
    
    ports_yaml = "        ports:\n"
    for port in ports:
        port_name = _get_port_name(port)
        ports_yaml += "        - name: {}\n          containerPort: {}\n          protocol: TCP\n".format(port_name, port)
    
    return ports_yaml

def _generate_service_ports(ports):
    """Generate service ports YAML with proper naming and protocols"""
    
    if not ports:
        return ""
    
    service_ports_yaml = "  ports:\n"
    for port in ports:
        port_name = _get_port_name(port)
        service_ports_yaml += "  - name: {}\n    port: {}\n    targetPort: {}\n    protocol: TCP\n".format(port_name, port, port)
    
    return service_ports_yaml

def _get_port_name(port):
    """Get appropriate port name based on port number"""
    
    if port in [80, 8080, 3000]:
        return "http"
    elif port in [443, 8443]:
        return "https"
    else:
        return "port-{}".format(port)

def _generate_resources(resources, default_resources):
    """Generate resources YAML with proper requests and limits"""
    
    if not resources and not default_resources:
        return ""
    
    cpu_limit = resources.get("cpu", default_resources.get("cpu", "500m"))
    memory_limit = resources.get("memory", default_resources.get("memory", "512Mi"))
    cpu_request = resources.get("cpu_request", "100m")
    memory_request = resources.get("memory_request", "128Mi")
    
    return """        resources:
          requests:
            cpu: "{}"
            memory: "{}"
          limits:
            cpu: "{}"
            memory: "{}"
""".format(cpu_request, memory_request, cpu_limit, memory_limit)

def _generate_probes(service_type, health_check, default_health, default_readiness):
    """Generate health and readiness probes based on service type"""
    
    health_path = health_check.get("path", "/health")
    health_port = health_check.get("port", 8080)
    
    if service_type in ["postgres", "redis"]:
        # TCP probes for databases
        liveness_probe = """        livenessProbe:
          tcpSocket:
            port: {}
          initialDelaySeconds: {}
          periodSeconds: {}
          timeoutSeconds: {}
          failureThreshold: {}
""".format(health_port, 
           default_health.get("initial_delay_seconds", 30),
           default_health.get("period_seconds", 10),
           default_health.get("timeout_seconds", 5),
           default_health.get("failure_threshold", 3))
        
        readiness_probe = """        readinessProbe:
          tcpSocket:
            port: {}
          initialDelaySeconds: {}
          periodSeconds: {}
          timeoutSeconds: {}
          failureThreshold: {}
""".format(health_port,
           default_readiness.get("initial_delay_seconds", 5),
           default_readiness.get("period_seconds", 5),
           default_readiness.get("timeout_seconds", 3),
           default_readiness.get("failure_threshold", 3))
    else:
        # HTTP probes for application services
        liveness_probe = """        livenessProbe:
          httpGet:
            path: {}
            port: {}
            scheme: HTTP
          initialDelaySeconds: {}
          periodSeconds: {}
          timeoutSeconds: {}
          failureThreshold: {}
""".format(health_path, health_port,
           default_health.get("initial_delay_seconds", 30),
           default_health.get("period_seconds", 10),
           default_health.get("timeout_seconds", 5),
           default_health.get("failure_threshold", 3))
        
        readiness_probe = """        readinessProbe:
          httpGet:
            path: {}
            port: {}
            scheme: HTTP
          initialDelaySeconds: {}
          periodSeconds: {}
          timeoutSeconds: {}
          failureThreshold: {}
""".format(health_path, health_port,
           default_readiness.get("initial_delay_seconds", 5),
           default_readiness.get("period_seconds", 5),
           default_readiness.get("timeout_seconds", 3),
           default_readiness.get("failure_threshold", 3))
    
    return liveness_probe, readiness_probe

def _generate_labels(service_name, service_type, developer_id):
    """Generate comprehensive labels for Kubernetes resources"""
    
    labels = {
        "app": service_name,
        "tilt.dev/resource": service_name,
        "tilt.dev/type": service_type,
        "tilt.dev/developer": developer_id,
        "tilt.dev/environment": "local",
        "version": "dev"
    }
    
    labels_yaml = ""
    for key, value in labels.items():
        labels_yaml += "    {}: {}\n".format(key, value)
    
    return labels_yaml