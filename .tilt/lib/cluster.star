"""
Cluster management and safety validation
Handles cluster context validation, safety checks, and environment detection
"""

def validate_cluster_safety(cluster_type, debug_mode=False):
    """Validate cluster context for safety with automatic cluster setup and fallback"""
    
    # Get current cluster context
    current_context = str(local('kubectl config current-context')).strip()

    # Test cluster connectivity
    local('kubectl cluster-info --request-timeout=10s')

    if debug_mode:
        print("✅ Cluster connectivity verified: {}".format(current_context))

    # Define dangerous context patterns with descriptions
    dangerous_patterns = [
        ('prod', 'production environment'),
        ('production', 'production environment'),
        ('staging', 'staging environment'),
        ('stage', 'staging environment'),
        ('live', 'live environment'),
        ('release', 'release environment'),
        ('aws', 'AWS cloud environment'),
        ('gke', 'Google Kubernetes Engine'),
        ('aks', 'Azure Kubernetes Service'),
        ('eks', 'Amazon EKS'),
        ('cloud', 'cloud environment'),
        ('remote', 'remote environment'),
        ('us-east', 'AWS US East region'),
        ('us-west', 'AWS US West region'),
        ('eu-', 'European cloud region'),
        ('ap-', 'Asia Pacific cloud region'),
        ('ca-', 'Canada cloud region'),
        ('sa-', 'South America cloud region'),
        ('cluster.local', 'remote cluster'),
        ('.amazonaws.com', 'AWS managed cluster'),
        ('.gke.', 'Google Cloud managed cluster'),
        ('.aks.', 'Azure managed cluster')
    ]
    
    # Check for dangerous patterns with enhanced error reporting
    context_lower = current_context.lower()
    for pattern, description in dangerous_patterns:
        if pattern in context_lower:
            fail("""
🚨 CRITICAL SAFETY VIOLATION: Dangerous cluster context detected!

Context: '{}'
Issue: Detected {} (pattern: '{}')

This appears to be a {} which is STRICTLY PROHIBITED for local development.
Operations are BLOCKED to prevent accidental damage to critical environments.

IMMEDIATE ACTION REQUIRED:
1. Switch to a safe local development cluster:
   kubectl config use-context docker-desktop
   kubectl config use-context kind-tilt-dev
   kubectl config use-context k3d-dev

2. Verify your cluster is local and safe:
   kubectl cluster-info
   kubectl get nodes

3. Available local cluster options:
   • Docker Desktop: Enable Kubernetes in Docker Desktop
   • Kind: kind create cluster --name tilt-dev
   • K3d: k3d cluster create tilt-dev
   • Minikube: minikube start

SAFETY FIRST: This protection prevents accidental damage to production systems.
Never override this safety check for production or staging environments.

If you need to work with non-local clusters, use appropriate deployment tools:
• Production: CI/CD pipelines, GitOps, kubectl with explicit confirmation
• Staging: Dedicated staging deployment scripts with safety checks
            """.format(current_context, description, pattern, description))
    
    # Define allowed contexts based on cluster type
    allowed_contexts = _get_allowed_contexts(cluster_type)
    
    # Validate current context is allowed
    if current_context not in allowed_contexts:
        fail("""
SAFETY VIOLATION: Current cluster context '{}' is not in the allowed list for local development.

Allowed contexts for cluster type '{}':
{}

This safety check prevents accidental operations on non-local clusters.

To fix this:
1. Switch to an allowed local development context:
   kubectl config use-context <allowed-context>

2. Or update your cluster_type parameter:
   tilt up -- --cluster_type=<your-cluster-type>

Available cluster types: kind, k3d, docker-desktop
        """.format(current_context, cluster_type, '\n'.join(['  - ' + ctx for ctx in allowed_contexts])))
    
    # Use Tilt's built-in context validation
    allow_k8s_contexts(allowed_contexts)
    
    if debug_mode:
        print("✅ SAFETY CHECK PASSED")
        print("Current cluster context: " + current_context)
        print("Allowed contexts: " + str(allowed_contexts))
        print("Cluster type: " + cluster_type)
    
    return current_context

def _get_allowed_contexts(cluster_type):
    """Get allowed contexts based on cluster type"""
    
    if cluster_type == "kind":
        return ['kind-tilt-dev', 'kind-kind', 'kind-dev', 'kind-local']
    elif cluster_type == "k3d":
        return ['k3d-tilt-dev', 'k3d-default', 'k3d-dev', 'k3d-local']
    elif cluster_type == "docker-desktop":
        return ['docker-desktop', 'docker-for-desktop']
    else:
        # Default: allow common local development contexts
        return [
            'kind-tilt-dev', 'kind-kind', 'kind-dev', 'kind-local',
            'k3d-tilt-dev', 'k3d-default', 'k3d-dev', 'k3d-local',
            'docker-desktop', 'docker-for-desktop',
            'minikube'
        ]

def detect_cluster_environment(current_context, debug_mode=False):
    """Detect and validate cluster environment with enhanced safety checks"""
    
    # Get API server information
    api_server = str(local('kubectl config view --minify -o jsonpath="{.clusters[0].cluster.server}"')).strip()
    
    # Detect cluster type
    cluster_info = {
        'context': current_context,
        'type': _detect_cluster_type(current_context),
        'api_server': api_server,
        'is_safe': False
    }
    
    # Validate API server locality
    local_api_indicators = [
        'localhost', '127.0.0.1', '0.0.0.0',
        'kubernetes.docker.internal', 'host.docker.internal',
        '192.168.', '10.', '172.16.', '172.17.', '172.18.', '172.19.',
        '172.20.', '172.21.', '172.22.', '172.23.', '172.24.', '172.25.',
        '172.26.', '172.27.', '172.28.', '172.29.', '172.30.', '172.31.'
    ]
    
    is_local_api = False
    for indicator in local_api_indicators:
        if indicator in api_server:
            is_local_api = True
            break

    # Validate context locality
    local_cluster_indicators = ['kind', 'k3d', 'docker-desktop', 'docker-for-desktop', 'minikube']
    is_local_context = False
    for indicator in local_cluster_indicators:
        if indicator in current_context.lower():
            is_local_context = True
            break

    # Cluster is safe if both context and API are local
    cluster_info['is_safe'] = is_local_context and is_local_api
    
    if not cluster_info['is_safe']:
        fail("""
SAFETY VIOLATION: Cluster environment validation failed.

Context: {}
API Server: {}
Detected Type: {}
Local Context: {}
Local API: {}

This cluster does not appear to be a safe local development environment.
Operations are BLOCKED to prevent accidental changes to remote clusters.

Ensure you are using a local development cluster:
- Docker Desktop with context 'docker-desktop'
- Kind cluster with context starting with 'kind-'
- K3d cluster with context starting with 'k3d-'
- Minikube with context 'minikube'

The API server should also be local (localhost, 127.0.0.1, or private network).
        """.format(
            current_context, api_server, cluster_info['type'],
            is_local_context, is_local_api
        ))
    
    if debug_mode:
        print("✅ CLUSTER SAFETY VALIDATION PASSED")
        print("Detected cluster type: " + cluster_info['type'])
        print("Context is local: " + str(is_local_context))
        print("API server is local: " + str(is_local_api))
        print("Overall safety: " + str(cluster_info['is_safe']))
    
    return cluster_info

def _detect_cluster_type(context):
    """Detect cluster type from context name"""
    
    context_lower = context.lower()
    if 'kind' in context_lower:
        return 'kind'
    elif 'k3d' in context_lower:
        return 'k3d'
    elif 'docker-desktop' in context_lower or 'docker-for-desktop' in context_lower:
        return 'docker-desktop'
    elif 'minikube' in context_lower:
        return 'minikube'
    else:
        return 'unknown'

def _auto_setup_local_cluster(cluster_type, debug_mode=False):
    """Automatically setup a local development cluster"""
    
    if debug_mode:
        print("🔧 Setting up local development cluster...")
    
    if cluster_type == "kind":
        return _setup_kind_cluster(debug_mode)
    elif cluster_type == "k3d":
        return _setup_k3d_cluster(debug_mode)
    elif cluster_type == "docker-desktop":
        return _setup_docker_desktop_cluster(debug_mode)
    else:
        # Try to setup the most reliable option
        return _setup_best_available_cluster(debug_mode)

def _auto_fix_cluster_issues(cluster_type, current_context, debug_mode=False):
    """Attempt to fix common cluster connectivity issues"""
    
    if debug_mode:
        print("🔧 Attempting to fix cluster connectivity issues...")
    
    # For Docker Desktop, try to restart the context
    if "docker-desktop" in current_context.lower():
        # Reset Docker Desktop Kubernetes context
        local('kubectl config use-context docker-desktop')

        # Test connectivity
        local('kubectl cluster-info --request-timeout=5s')

        if debug_mode:
            print("✅ Fixed Docker Desktop connectivity")
        return current_context

    # For other cluster types, try to recreate
    return _auto_setup_local_cluster(cluster_type, debug_mode)

def _setup_kind_cluster(debug_mode=False):
    """Setup a Kind cluster for local development"""
    
    cluster_name = "tilt-dev"
    
    # Check if kind is installed
    local('which kind')

    # Check if cluster already exists
    existing_clusters = str(local('kind get clusters')).strip()
    if cluster_name in existing_clusters.split('\n'):
        if debug_mode:
            print("✅ Using existing Kind cluster: {}".format(cluster_name))
        local('kubectl config use-context kind-{}'.format(cluster_name))
        return 'kind-{}'.format(cluster_name)

    if debug_mode:
        print("🔧 Creating Kind cluster: {}".format(cluster_name))
    
    # Create Kind cluster with optimized configuration
    kind_config = """
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
"""
    
    # Write config to temporary file
    local('echo \'{}\' > /tmp/kind-config.yaml'.format(kind_config))
    
    # Create cluster
    local('kind create cluster --name {} --config /tmp/kind-config.yaml'.format(cluster_name))
    local('kubectl config use-context kind-{}'.format(cluster_name))

    # Wait for cluster to be ready
    local('kubectl wait --for=condition=Ready nodes --all --timeout=120s')

    if debug_mode:
        print("✅ Kind cluster created successfully: {}".format(cluster_name))

    return 'kind-{}'.format(cluster_name)

def _setup_k3d_cluster(debug_mode=False):
    """Setup a K3d cluster for local development"""
    
    cluster_name = "tilt-dev"
    
    # Check if k3d is installed
    local('which k3d')

    # Check if cluster already exists
    existing_clusters = str(local('k3d cluster list -o json')).strip()
    if cluster_name in existing_clusters:
        if debug_mode:
            print("✅ Using existing K3d cluster: {}".format(cluster_name))
        local('kubectl config use-context k3d-{}'.format(cluster_name))
        return 'k3d-{}'.format(cluster_name)

    if debug_mode:
        print("🔧 Creating K3d cluster: {}".format(cluster_name))
    
    # Create cluster
    local('k3d cluster create {} --port "80:80@loadbalancer" --port "443:443@loadbalancer"'.format(cluster_name))
    local('kubectl config use-context k3d-{}'.format(cluster_name))

    # Wait for cluster to be ready
    local('kubectl wait --for=condition=Ready nodes --all --timeout=120s')

    if debug_mode:
        print("✅ K3d cluster created successfully: {}".format(cluster_name))

    return 'k3d-{}'.format(cluster_name)

def _setup_docker_desktop_cluster(debug_mode=False):
    """Setup Docker Desktop Kubernetes cluster"""
    
    # Check if Docker Desktop is running
    local('docker info')

    # Check if Kubernetes is enabled in Docker Desktop
    local('kubectl config use-context docker-desktop')
    local('kubectl cluster-info --request-timeout=10s')

    if debug_mode:
        print("✅ Docker Desktop Kubernetes is ready")

    return 'docker-desktop'

def _setup_best_available_cluster(debug_mode=False):
    """Setup the best available local cluster option"""
    
    if debug_mode:
        print("🔧 Detecting best available cluster option...")
    
    # Try Docker Desktop first (most common)
    return _setup_docker_desktop_cluster(debug_mode)

def setup_cluster_monitoring(current_context, cluster_info):
    """Setup cluster monitoring and validation resources"""
    
    # Cluster safety validation resource
    local_resource(
        'cluster-safety-validation',
        cmd='''
        echo "=== CLUSTER SAFETY VALIDATION ==="
        echo "✅ SAFETY CHECKS PASSED - Local development environment confirmed"
        echo ""
        echo "Context: ''' + current_context + '''"
        echo "Detected Type: ''' + cluster_info['type'] + '''"
        echo "API Server: ''' + cluster_info['api_server'] + '''"
        echo "Is Safe for Development: ''' + str(cluster_info['is_safe']) + '''"
        echo ""
        echo "=== Additional Cluster Information ==="
        kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
        echo ""
        echo ""
        echo "=== Cluster Certificate Authority (first 50 chars) ==="
        kubectl config view --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | head -c 50
        echo "... (truncated for security)"
        echo ""
        echo ""
        echo "=== Current User Context ==="
        kubectl config view --minify -o jsonpath='{.users[0].name}'
        ''',
        deps=[],
        labels=['infrastructure', 'safety', 'validation'],
        auto_init=True
    )
    
    # Cluster health check
    local_resource(
        'cluster-health-check',
        cmd='''
        echo "=== Cluster Health Check ==="
        kubectl cluster-info
        echo ""
        echo "=== Node Status ==="
        kubectl get nodes -o wide
        echo ""
        echo "=== Cluster Version ==="
        kubectl version --short 2>/dev/null || kubectl version --client
        ''',
        deps=[],
        labels=['infrastructure', 'health-check'],
        auto_init=True
    )
    
    # Cluster initialization check
    local_resource(
        'cluster-initialization',
        cmd='''
        echo "=== Cluster Initialization Check ==="
        kubectl wait --for=condition=Ready nodes --all --timeout=60s
        echo "All nodes are ready"
        
        echo ""
        echo "=== System Namespaces ==="
        kubectl get namespaces kube-system kube-public default
        
        echo ""
        echo "=== Core System Pods ==="
        kubectl get pods -n kube-system --field-selector=status.phase=Running
        ''',
        deps=['cluster-health-check'],
        labels=['infrastructure', 'initialization'],
        auto_init=True
    )
    
    # Cluster resource validation
    local_resource(
        'cluster-resource-validation',
        cmd='''
        echo "=== Cluster Resource Validation ==="
        kubectl describe nodes | grep -A 5 "Allocated resources" || echo "Resource info not available"
        
        echo ""
        echo "=== Storage Classes ==="
        kubectl get storageclass || echo "No storage classes found"
        
        echo ""
        echo "=== Metrics Server Status ==="
        kubectl get deployment metrics-server -n kube-system 2>/dev/null || echo "Metrics server not installed (optional)"
        ''',
        deps=['cluster-initialization'],
        labels=['infrastructure', 'validation'],
        auto_init=True
    )
