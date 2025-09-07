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

def deploy_postgres_database(service_name, service_config, namespace, global_config, developer_id, debug_mode=False):
    """Deploy PostgreSQL database with test data and developer isolation"""
    
    # Create developer-specific database configuration
    db_config = _create_postgres_config(service_config, developer_id)
    
    # Create ConfigMaps and Secrets with developer isolation
    create_service_configmap(service_name, db_config, namespace, debug_mode)
    create_service_secret(service_name, db_config, namespace, debug_mode)
    
    # Generate PostgreSQL manifests with persistent volume
    manifests = _generate_postgres_manifests(service_name, db_config, namespace, developer_id)
    
    # Apply manifests
    k8s_yaml(manifests, allow_duplicates=False, validate=True)
    
    # Configure k8s resource with database-specific settings
    # Generate unique port forwards to avoid conflicts
    port_forwards = generate_unique_port_forwards(service_name, [5432])
    k8s_resource(
        service_name,
        port_forwards=port_forwards,
        labels=[
            "category:database",
            "type:postgres", 
            "developer:" + developer_id,
            "tier:data"
        ],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL,
        pod_readiness="wait"
    )
    
    # Setup database initialization and test data
    _setup_postgres_initialization(service_name, namespace, developer_id, debug_mode)
    
    return {
        "name": service_name,
        "type": "postgres",
        "ports": [5432],
        "database": db_config["env_vars"][0]["value"],  # POSTGRES_DB
        "username": db_config["env_vars"][1]["value"],  # POSTGRES_USER
        "developer_id": developer_id
    }

def deploy_redis_cache(service_name, service_config, namespace, global_config, developer_id, debug_mode=False):
    """Deploy Redis cache with developer isolation"""
    
    # Create developer-specific Redis configuration
    redis_config = _create_redis_config(service_config, developer_id)
    
    # Create ConfigMaps and Secrets
    create_service_configmap(service_name, redis_config, namespace, debug_mode)
    create_service_secret(service_name, redis_config, namespace, debug_mode)
    
    # Generate Redis manifests
    manifests = _generate_redis_manifests(service_name, redis_config, namespace, developer_id)
    
    # Apply manifests
    k8s_yaml(manifests, allow_duplicates=False, validate=True)
    
    # Configure k8s resource
    # Generate unique port forwards to avoid conflicts
    port_forwards = generate_unique_port_forwards(service_name, [6379])
    k8s_resource(
        service_name,
        port_forwards=port_forwards,
        labels=[
            "category:cache",
            "type:redis",
            "developer:" + developer_id,
            "tier:data"
        ],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL,
        pod_readiness="wait"
    )
    
    # Setup Redis monitoring and test data
    _setup_redis_monitoring(service_name, namespace, developer_id, debug_mode)
    
    return {
        "name": service_name,
        "type": "redis",
        "ports": [6379],
        "developer_id": developer_id
    }


def deploy_mock_service(service_name, service_config, namespace, global_config, developer_id, debug_mode=False):
    """Deploy configurable mock service for external APIs"""
    
    # Create mock service configuration
    mock_config = _create_mock_service_config(service_config, developer_id)
    
    # Create ConfigMaps and Secrets
    create_service_configmap(service_name, mock_config, namespace, debug_mode)
    create_service_secret(service_name, mock_config, namespace, debug_mode)
    
    # Generate mock service manifests
    manifests = _generate_mock_service_manifests(service_name, mock_config, namespace, developer_id)
    
    # Apply manifests
    k8s_yaml(manifests, allow_duplicates=False, validate=True)
    
    # Configure k8s resource
    ports = mock_config.get("ports", [8080])
    # Generate unique port forwards to avoid conflicts
    port_forwards = generate_unique_port_forwards(service_name, ports)
    k8s_resource(
        service_name,
        port_forwards=port_forwards,
        labels=[
            "category:mock",
            "type:mock-api",
            "developer:" + developer_id,
            "tier:service"
        ],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_AUTO,
        pod_readiness="wait"
    )
    
    # Setup mock service configuration and endpoints
    _setup_mock_service_endpoints(service_name, mock_config, namespace, developer_id, debug_mode)
    
    return {
        "name": service_name,
        "type": "mock",
        "ports": ports,
        "endpoints": mock_config.get("mock_endpoints", []),
        "developer_id": developer_id
    }

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

def _create_postgres_config(service_config, developer_id):
    """Create PostgreSQL configuration with developer isolation"""
    
    # Use standard database credentials for local development
    db_name = "testdb"
    db_user = "testuser"
    
    return {
        "type": "postgres",
        "ports": [5432],
        "env_vars": [
            {"name": "POSTGRES_DB", "value": db_name, "from_configmap": True},
            {"name": "POSTGRES_USER", "value": db_user, "from_configmap": True},
            {"name": "POSTGRES_PASSWORD", "value": "testpass", "from_secret": True, "sensitive": True},
            {"name": "PGDATA", "value": "/var/lib/postgresql/data/pgdata", "from_configmap": True}
        ],
        "resources": service_config.get("resources", {"cpu": "250m", "memory": "512Mi"}),
        "health_check": {"path": "/", "port": 5432, "type": "tcp"},
        "volume_mounts": [
            {"name": "postgres-data", "mount_path": "/var/lib/postgresql/data"}
        ]
    }

def _create_redis_config(service_config, developer_id):
    """Create Redis configuration with developer isolation"""
    
    return {
        "type": "redis",
        "ports": [6379],
        "env_vars": [
            {"name": "REDIS_PASSWORD", "value": "testpass", "from_secret": True, "sensitive": True},
            {"name": "REDIS_DATABASES", "value": "16", "from_configmap": True},
            {"name": "REDIS_MAXMEMORY", "value": "128mb", "from_configmap": True}
        ],
        "resources": service_config.get("resources", {"cpu": "100m", "memory": "128Mi"}),
        "health_check": {"path": "/", "port": 6379, "type": "tcp"},
        "volume_mounts": [
            {"name": "redis-data", "mount_path": "/data"}
        ]
    }


def _create_mock_service_config(service_config, developer_id):
    """Create mock service configuration"""
    
    mock_endpoints = service_config.get("mock_endpoints", [
        {"path": "/api/v1/users", "method": "GET", "response": {"users": []}},
        {"path": "/api/v1/health", "method": "GET", "response": {"status": "ok"}}
    ])
    
    return {
        "type": "mock",
        "ports": service_config.get("ports", [8080]),
        "env_vars": [
            {"name": "MOCK_PORT", "value": str(service_config.get("ports", [8080])[0]), "from_configmap": True},
            {"name": "MOCK_DEVELOPER_ID", "value": developer_id, "from_configmap": True},
            {"name": "MOCK_ENDPOINTS", "value": str(len(mock_endpoints)), "from_configmap": True}
        ],
        "resources": service_config.get("resources", {"cpu": "100m", "memory": "128Mi"}),
        "health_check": {"path": "/health", "port": service_config.get("ports", [8080])[0]},
        "mock_endpoints": mock_endpoints
    }

def _generate_postgres_manifests(service_name, db_config, namespace, developer_id):
    """Generate PostgreSQL Kubernetes manifests with persistent volume"""
    
    labels = """    app: {}
    type: postgres
    developer: {}
    category: database""".format(service_name, developer_id)
    
    return """apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {service_name}-pvc
  namespace: {namespace}
  labels:
{labels}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
{labels}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: {service_name}
  template:
    metadata:
      labels:
{labels}
    spec:
      containers:
      - name: postgres
        image: postgres:14-alpine
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: {service_name}-config
              key: postgres_db
        - name: POSTGRES_USER
          valueFrom:
            configMapKeyRef:
              name: {service_name}-config
              key: postgres_user
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {service_name}-secret
              key: postgres_password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        resources:
          requests:
            cpu: {cpu}
            memory: {memory}
          limits:
            cpu: {cpu}
            memory: {memory}
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - $(POSTGRES_USER)
            - -d
            - $(POSTGRES_DB)
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - $(POSTGRES_USER)
            - -d
            - $(POSTGRES_DB)
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: {service_name}-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
{labels}
spec:
  selector:
    app: {service_name}
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres
  type: ClusterIP
""".format(
        service_name=service_name,
        namespace=namespace,
        labels=labels,
        cpu=db_config["resources"]["cpu"],
        memory=db_config["resources"]["memory"]
    )

def _generate_redis_manifests(service_name, redis_config, namespace, developer_id):
    """Generate Redis Kubernetes manifests with persistent volume"""
    
    labels = """    app: {}
    type: redis
    developer: {}
    category: cache""".format(service_name, developer_id)
    
    return """apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {service_name}-pvc
  namespace: {namespace}
  labels:
{labels}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: standard
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
{labels}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: {service_name}
  template:
    metadata:
      labels:
{labels}
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
          name: redis
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {service_name}-secret
              key: redis_password
        command:
        - redis-server
        - --requirepass
        - $(REDIS_PASSWORD)
        - --appendonly
        - "yes"
        - --dir
        - /data
        resources:
          requests:
            cpu: {cpu}
            memory: {memory}
          limits:
            cpu: {cpu}
            memory: {memory}
        volumeMounts:
        - name: redis-data
          mountPath: /data
        livenessProbe:
          exec:
            command:
            - redis-cli
            - -a
            - $(REDIS_PASSWORD)
            - ping
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - redis-cli
            - -a
            - $(REDIS_PASSWORD)
            - ping
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: {service_name}-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
{labels}
spec:
  selector:
    app: {service_name}
  ports:
  - port: 6379
    targetPort: 6379
    name: redis
  type: ClusterIP
""".format(
        service_name=service_name,
        namespace=namespace,
        labels=labels,
        cpu=redis_config["resources"]["cpu"],
        memory=redis_config["resources"]["memory"]
    )


def _generate_mock_service_manifests(service_name, mock_config, namespace, developer_id):
    """Generate mock service Kubernetes manifests"""
    
    labels = """    app: {}
    type: mock
    developer: {}
    category: mock""".format(service_name, developer_id)
    
    port = mock_config["ports"][0]
    
    return """apiVersion: v1
kind: ConfigMap
metadata:
  name: {service_name}-mock-config
  namespace: {namespace}
  labels:
{labels}
data:
  mock-config.json: |
    {{
      "port": {port},
      "developer_id": "{developer_id}",
      "endpoints": {endpoints}
    }}
  startup.sh: |
    #!/bin/sh
    echo "Starting mock service for developer: {developer_id}"
    echo "Port: {port}"
    echo "Endpoints configured: $(echo '{endpoints}' | jq length)"
    
    # Create simple HTTP server using Python
    cat > /app/mock_server.py << 'EOF'
import json
import http.server
import socketserver
from urllib.parse import urlparse, parse_qs
import os

class MockHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.handle_request()
    
    def do_POST(self):
        self.handle_request()
    
    def do_PUT(self):
        self.handle_request()
    
    def do_DELETE(self):
        self.handle_request()
    
    def handle_request(self):
        path = self.path.split('?')[0]
        
        # Load mock configuration
        with open('/app/mock-config.json', 'r') as f:
            config = json.load(f)
        
        # Find matching endpoint
        for endpoint in config['endpoints']:
            if endpoint['path'] == path and endpoint['method'] == self.command:
                self.send_response(endpoint.get('status_code', 200))
                self.send_header('Content-type', 'application/json')
                self.send_header('X-Mock-Service', 'true')
                self.send_header('X-Developer-ID', config['developer_id'])
                self.end_headers()
                
                response = endpoint.get('response', {{}})
                self.wfile.write(json.dumps(response).encode())
                return
        
        # Default health endpoint
        if path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {{
                "status": "healthy",
                "service": "{service_name}",
                "developer_id": config['developer_id'],
                "endpoints": len(config['endpoints'])
            }}
            self.wfile.write(json.dumps(response).encode())
            return
        
        # 404 for unknown endpoints
        self.send_response(404)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {{
            "error": "Endpoint not found",
            "path": path,
            "method": self.command,
            "available_endpoints": [ep['path'] for ep in config['endpoints']]
        }}
        self.wfile.write(json.dumps(response).encode())

if __name__ == "__main__":
    PORT = int(os.environ.get('MOCK_PORT', {port}))
    with socketserver.TCPServer(("", PORT), MockHandler) as httpd:
        print(f"Mock server serving at port {{PORT}}")
        httpd.serve_forever()
EOF
    
    python3 /app/mock_server.py
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
{labels}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {service_name}
  template:
    metadata:
      labels:
{labels}
    spec:
      containers:
      - name: mock-service
        image: python:3.9-alpine
        ports:
        - containerPort: {port}
          name: http
        env:
        - name: MOCK_PORT
          value: "{port}"
        - name: MOCK_DEVELOPER_ID
          value: "{developer_id}"
        command: ["/bin/sh"]
        args: ["/app/startup.sh"]
        resources:
          requests:
            cpu: {cpu}
            memory: {memory}
          limits:
            cpu: {cpu}
            memory: {memory}
        volumeMounts:
        - name: mock-config
          mountPath: /app
        livenessProbe:
          httpGet:
            path: /health
            port: {port}
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: {port}
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: mock-config
        configMap:
          name: {service_name}-mock-config
          defaultMode: 0755
---
apiVersion: v1
kind: Service
metadata:
  name: {service_name}
  namespace: {namespace}
  labels:
{labels}
spec:
  selector:
    app: {service_name}
  ports:
  - port: {port}
    targetPort: {port}
    name: http
  type: ClusterIP
""".format(
        service_name=service_name,
        namespace=namespace,
        labels=labels,
        port=port,
        developer_id=developer_id,
        endpoints=str(mock_config["mock_endpoints"]),
        cpu=mock_config["resources"]["cpu"],
        memory=mock_config["resources"]["memory"]
    )

def _setup_postgres_initialization(service_name, namespace, developer_id, debug_mode):
    """Setup PostgreSQL database initialization with test data"""
    
    local_resource(
        service_name + "-init",
        cmd='''
        echo "=== PostgreSQL Database Initialization ({}) ==="
        echo "Developer: {}"
        echo "Namespace: {}"
        echo ""
        
        # Wait for PostgreSQL to be ready
        echo "Waiting for PostgreSQL to be ready..."
        kubectl wait --for=condition=ready pod -l app={} -n {} --timeout=120s
        
        POD_NAME=$(kubectl get pods -n {} -l app={} -o jsonpath='{{.items[0].metadata.name}}')
        
        if [ -n "$POD_NAME" ]; then
            echo "PostgreSQL pod: $POD_NAME"
            
            # Create test database and tables
            echo "Creating test data..."
            kubectl exec $POD_NAME -n {} -- psql -U testuser -d testdb -c "
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100) NOT NULL,
                    email VARCHAR(100) UNIQUE NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                
                CREATE TABLE IF NOT EXISTS products (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100) NOT NULL,
                    price DECIMAL(10,2) NOT NULL,
                    category VARCHAR(50),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                
                -- Insert test data
                INSERT INTO users (name, email) VALUES 
                    ('Test User 1', 'user1@{}.local'),
                    ('Test User 2', 'user2@{}.local'),
                    ('Developer User', 'dev@{}.local')
                ON CONFLICT (email) DO NOTHING;
                
                INSERT INTO products (name, price, category) VALUES 
                    ('Test Product A', 19.99, 'electronics'),
                    ('Test Product B', 29.99, 'books'),
                    ('Test Product C', 9.99, 'tools')
                ON CONFLICT DO NOTHING;
            "
            
            echo "✅ Test data created successfully"
            
            # Show database info
            echo ""
            echo "📊 Database Information:"
            kubectl exec $POD_NAME -n {} -- psql -U testuser -d testdb -c "
                SELECT 'Users' as table_name, COUNT(*) as row_count FROM users
                UNION ALL
                SELECT 'Products' as table_name, COUNT(*) as row_count FROM products;
            "
            
            echo ""
            echo "🔗 Connection Information:"
            echo "  Host: localhost"
            echo "  Port: 5432"
            echo "  Database: testdb"
            echo "  Username: testuser"
            echo "  Password: testpass"
            echo ""
            echo "💡 Connect using: psql -h localhost -p 5432 -U testuser -d testdb"
        else
            echo "❌ PostgreSQL pod not found"
            exit 1
        fi
        '''.format(
            service_name, developer_id, namespace,
            service_name, namespace, namespace, service_name, namespace,
            developer_id.replace("-", "_"), developer_id.replace("-", "_"),
            developer_id, developer_id, developer_id,
            namespace, developer_id.replace("-", "_"), developer_id.replace("-", "_"),
            developer_id.replace("-", "_"), developer_id.replace("-", "_"), developer_id,
            developer_id.replace("-", "_"), developer_id.replace("-", "_")
        ),
        deps=[service_name],
        labels=["database", "initialization", "test-data", developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def _setup_redis_monitoring(service_name, namespace, developer_id, debug_mode):
    """Setup Redis monitoring and test data"""
    
    local_resource(
        service_name + "-monitor",
        cmd='''
        echo "=== Redis Cache Monitoring ({}) ==="
        echo "Developer: {}"
        echo "Namespace: {}"
        echo ""
        
        POD_NAME=$(kubectl get pods -n {} -l app={} -o jsonpath='{{.items[0].metadata.name}}' 2>/dev/null)
        
        if [ -n "$POD_NAME" ]; then
            echo "Redis pod: $POD_NAME"
            
            # Check Redis status
            echo "📊 Redis Status:"
            kubectl exec $POD_NAME -n {} -- redis-cli -a testpass info server | grep -E "(redis_version|uptime_in_seconds|connected_clients)"
            
            echo ""
            echo "💾 Memory Usage:"
            kubectl exec $POD_NAME -n {} -- redis-cli -a testpass info memory | grep -E "(used_memory_human|maxmemory_human)"
            
            echo ""
            echo "🔑 Sample Test Data:"
            kubectl exec $POD_NAME -n {} -- redis-cli -a testpass eval "
                redis.call('SET', 'test:user:1', '{{\\"name\\": \\"Test User\\", \\"developer\\": \\"{}\\"}}')
                redis.call('SET', 'test:counter', '42')
                redis.call('LPUSH', 'test:queue', 'message1', 'message2', 'message3')
                redis.call('HSET', 'test:config', 'environment', 'local', 'developer', '{}')
                return 'Test data created'
            " 0
            
            echo ""
            echo "📈 Key Statistics:"
            kubectl exec $POD_NAME -n {} -- redis-cli -a testpass eval "
                local keys = redis.call('KEYS', '*')
                return 'Total keys: ' .. #keys
            " 0
            
            echo ""
            echo "🔗 Connection Information:"
            echo "  Host: localhost"
            echo "  Port: 6379"
            echo "  Password: testpass"
            echo ""
            echo "💡 Connect using: redis-cli -h localhost -p 6379 -a testpass"
        else
            echo "❌ Redis pod not found"
        fi
        '''.format(
            service_name, developer_id, namespace,
            namespace, service_name, namespace, developer_id,
            namespace, developer_id, namespace, developer_id,
            developer_id, developer_id, namespace, developer_id,
            developer_id, developer_id
        ),
        deps=[service_name],
        labels=["cache", "monitoring", "redis", developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )


def _setup_mock_service_endpoints(service_name, mock_config, namespace, developer_id, debug_mode):
    """Setup mock service endpoint documentation and testing"""
    
    endpoints = mock_config.get("mock_endpoints", [])
    port = mock_config["ports"][0]
    
    local_resource(
        service_name + "-endpoints",
        cmd='''
        echo "=== Mock Service Endpoints ({}) ==="
        echo "Developer: {}"
        echo "Base URL: http://localhost:{}"
        echo ""
        
        echo "📋 Available Endpoints:"
        ''' + '\n        '.join([
            'echo "  {} {} - {}"'.format(
                ep.get("method", "GET"),
                ep.get("path", "/"),
                ep.get("description", "Mock endpoint")
            ) for ep in endpoints
        ]) + '''
        
        echo ""
        echo "🧪 Test Commands:"
        ''' + '\n        '.join([
            'echo "curl -X {} http://localhost:{}{}"'.format(
                ep.get("method", "GET"),
                port,
                ep.get("path", "/")
            ) for ep in endpoints
        ]) + '''
        
        echo ""
        echo "🔍 Health Check:"
        echo "curl http://localhost:{}/health"
        
        echo ""
        echo "📊 Service Status:"
        if nc -z localhost {} 2>/dev/null; then
            echo "✅ Mock service is accessible"
            
            # Test health endpoint
            HEALTH_RESPONSE=$(curl -s http://localhost:{{}}/health 2>/dev/null || echo "unavailable")
            if [ "$HEALTH_RESPONSE" != "unavailable" ]; then
                echo "✅ Health endpoint responding"
                echo "Response: $HEALTH_RESPONSE"
            else
                echo "❌ Health endpoint not responding"
            fi
        else
            echo "❌ Mock service is not accessible on port {}"
        fi
        '''.format(
            service_name, developer_id, port, port, port, port
        ),
        deps=[service_name],
        labels=["mock", "endpoints", "testing", developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def setup_external_service_monitoring(deployed_externals, namespace, developer_id, debug_mode):
    """Setup comprehensive monitoring for all external services"""
    
    if not deployed_externals:
        return
    
    # Group services by type
    databases = [svc for svc in deployed_externals if svc["type"] in ["postgres", "mysql", "mongodb"]]
    caches = [svc for svc in deployed_externals if svc["type"] in ["redis", "memcached"]]
    queues = [svc for svc in deployed_externals if svc["type"] in ["kafka"]]
    mocks = [svc for svc in deployed_externals if svc["type"] == "mock"]
    
    local_resource(
        'external-services-dashboard',
        cmd='''
        echo "=== EXTERNAL SERVICES DASHBOARD ==="
        echo "Developer: {}"
        echo "Namespace: {}"
        echo "Total Services: {}"
        echo ""
        
        ''' + ('''
        echo "🗄️  DATABASE SERVICES"
        echo "--------------------"
        ''' + '\n        '.join([
            '''
        echo "📊 {}"
        POD_NAME=$(kubectl get pods -n {} -l app={} -o jsonpath='{{.items[0].metadata.name}}' 2>/dev/null)
        if [ -n "$POD_NAME" ]; then
            echo "   ✅ Running (Pod: $POD_NAME)"
            echo "   🔗 Connection: localhost:{}"
        else
            echo "   ❌ Not running"
        fi
        echo ""'''.format(svc["name"], namespace, svc["name"], svc["ports"][0] if svc["ports"] else "N/A")
            for svc in databases
        ]) + '''
        ''' if databases else '') + '''
        
        ''' + ('''
        echo "⚡ CACHE SERVICES"
        echo "----------------"
        ''' + '\n        '.join([
            '''
        echo "💾 {}"
        POD_NAME=$(kubectl get pods -n {} -l app={} -o jsonpath='{{.items[0].metadata.name}}' 2>/dev/null)
        if [ -n "$POD_NAME" ]; then
            echo "   ✅ Running (Pod: $POD_NAME)"
            echo "   🔗 Connection: localhost:{}"
        else
            echo "   ❌ Not running"
        fi
        echo ""'''.format(svc["name"], namespace, svc["name"], svc["ports"][0] if svc["ports"] else "N/A")
            for svc in caches
        ]) + '''
        ''' if caches else '') + '''
        
        ''' + ('''
        echo "📨 MESSAGE QUEUE SERVICES"
        echo "------------------------"
        ''' + '\n        '.join([
            '''
        echo "🔄 {}"
        POD_NAME=$(kubectl get pods -n {} -l app={} -o jsonpath='{{.items[0].metadata.name}}' 2>/dev/null)
        if [ -n "$POD_NAME" ]; then
            echo "   ✅ Running (Pod: $POD_NAME)"
            echo "   🔗 AMQP: localhost:{}"
            ''' + ('echo "   🌐 Management: {}"'.format(svc.get("management_ui", "N/A")) if "management_ui" in svc else '') + '''
        else
            echo "   ❌ Not running"
        fi
        echo ""'''.format(svc["name"], namespace, svc["name"], svc["ports"][0] if svc["ports"] else "N/A")
            for svc in queues
        ]) + '''
        ''' if queues else '') + '''
        
        ''' + ('''
        echo "🎭 MOCK SERVICES"
        echo "---------------"
        ''' + '\n        '.join([
            '''
        echo "🔧 {}"
        if nc -z localhost {} 2>/dev/null; then
            echo "   ✅ Running"
            echo "   🔗 API: http://localhost:{}"
            echo "   📋 Endpoints: {}"
        else
            echo "   ❌ Not accessible"
        fi
        echo ""'''.format(
                svc["name"], 
                svc["ports"][0] if svc["ports"] else 8080,
                svc["ports"][0] if svc["ports"] else 8080,
                len(svc.get("endpoints", []))
            ) for svc in mocks
        ]) + '''
        ''' if mocks else '') + '''
        
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
        labels=["external-services", "dashboard", "monitoring", developer_id],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

