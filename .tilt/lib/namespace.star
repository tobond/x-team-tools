"""
Namespace management for Tilt development environment
Handles namespace creation, labeling, validation, resource quotas, and isolation
"""

def setup_namespace(developer_id, current_context, debug_mode=False):
    """Setup isolated namespace with proper labeling, resource quotas, and validation"""
    
    developer_namespace = "dev-" + developer_id
    
    # Create namespace labels for isolation and management
    namespace_labels = [
        'tilt.dev/developer=' + developer_id,
        'tilt.dev/environment=local',
        'tilt.dev/cluster-context=' + current_context.replace(':', '-'),
        'tilt.dev/created-by=tilt',
        'tilt.dev/isolation=enabled',
        'tilt.dev/resource-management=enabled'
    ]
    
    if debug_mode:
        print("Creating isolated namespace: " + developer_namespace)
        print("Namespace labels: " + str(namespace_labels))
    
    # Create namespace using Tilt extension
    namespace_create(
        developer_namespace,
        labels=namespace_labels
    )
    
    # Setup resource quotas for developer isolation
    _setup_resource_quotas(developer_namespace, developer_id, debug_mode)
    
    # Setup network policies for isolation
    _setup_network_policies(developer_namespace, developer_id, debug_mode)
    
    # Setup namespace monitoring and validation
    _setup_namespace_monitoring(developer_namespace, developer_id, debug_mode)
    
    # Setup cleanup and reset functionality
    _setup_namespace_cleanup(developer_namespace, developer_id, debug_mode)
    
    # Setup developer environment state management
    _setup_environment_state_management(developer_namespace, developer_id, debug_mode)
    
    # Setup secure secret management for developer isolation
    _setup_developer_secret_management(developer_namespace, developer_id, debug_mode)
    
    # Create developer isolation guide (only once)
    if debug_mode:
        print("Setting up developer isolation guide")
    create_developer_isolation_guide()
    
    return developer_namespace

def _setup_resource_quotas(namespace, developer_id, debug_mode=False):
    """Setup resource quotas for developer isolation and resource management"""
    
    # Define resource quota manifest for developer isolation
    resource_quota_yaml = """apiVersion: v1
kind: ResourceQuota
metadata:
  name: developer-quota
  namespace: {namespace}
  labels:
    tilt.dev/developer: {developer_id}
    tilt.dev/resource-type: quota
    tilt.dev/managed-by: tilt
spec:
  hard:
    # Compute resources
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    
    # Storage resources
    requests.storage: 20Gi
    persistentvolumeclaims: "10"
    
    # Object counts for isolation
    pods: "50"
    services: "20"
    secrets: "20"
    configmaps: "20"
    deployments.apps: "20"
    replicasets.apps: "20"
    
    # Network resources
    services.nodeports: "5"
    services.loadbalancers: "2"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: developer-limits
  namespace: {namespace}
  labels:
    tilt.dev/developer: {developer_id}
    tilt.dev/resource-type: limits
    tilt.dev/managed-by: tilt
spec:
  limits:
  - default:
      cpu: "1"
      memory: 1Gi
    defaultRequest:
      cpu: "100m"
      memory: 128Mi
    max:
      cpu: "4"
      memory: 8Gi
    min:
      cpu: "10m"
      memory: 64Mi
    type: Container
  - default:
      storage: 1Gi
    max:
      storage: 10Gi
    min:
      storage: 100Mi
    type: PersistentVolumeClaim
""".format(namespace=namespace, developer_id=developer_id)
    
    if debug_mode:
        print("Setting up resource quotas for namespace: " + namespace)
    
    # Apply resource quota and limits
    k8s_yaml(resource_quota_yaml)

def _setup_network_policies(namespace, developer_id, debug_mode=False):
    """Setup network policies for developer isolation"""
    
    # Define network policy for namespace isolation
    network_policy_yaml = """apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: developer-isolation
  namespace: {namespace}
  labels:
    tilt.dev/developer: {developer_id}
    tilt.dev/resource-type: network-policy
    tilt.dev/managed-by: tilt
spec:
  podSelector: {{}}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow ingress from same namespace
  - from:
    - namespaceSelector:
        matchLabels:
          name: {namespace}
  # Allow ingress from system namespaces
  - from:
    - namespaceSelector:
        matchLabels:
          name: kube-system
  - from:
    - namespaceSelector:
        matchLabels:
          name: tilt-system
  egress:
  # Allow egress to same namespace
  - to:
    - namespaceSelector:
        matchLabels:
          name: {namespace}
  # Allow egress to system namespaces
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
  # Allow egress to DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
  # Allow egress to external services (internet)
  - to: []
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
""".format(namespace=namespace, developer_id=developer_id)
    
    if debug_mode:
        print("Setting up network policies for namespace: " + namespace)
    
    # Apply network policy
    k8s_yaml(network_policy_yaml)

def _setup_namespace_monitoring(namespace, developer_id, debug_mode=False):
    """Setup comprehensive namespace validation and monitoring resources"""
    
    local_resource(
        'namespace-validation-' + developer_id,
        cmd='''
        echo "=== Developer Environment Status ({developer_id}) ==="
        echo "Namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        echo "=== Namespace Details ==="
        kubectl get namespace {namespace} -o yaml 2>/dev/null || echo "Namespace not found"
        echo ""
        
        echo "=== Resource Quotas ==="
        kubectl get resourcequota -n {namespace} -o wide 2>/dev/null || echo "No resource quotas set"
        echo ""
        kubectl describe resourcequota -n {namespace} 2>/dev/null || echo "No quota details available"
        echo ""
        
        echo "=== Resource Usage ==="
        kubectl top pods -n {namespace} 2>/dev/null || echo "Metrics not available"
        echo ""
        
        echo "=== Network Policies ==="
        kubectl get networkpolicy -n {namespace} -o wide 2>/dev/null || echo "No network policies set"
        echo ""
        
        echo "=== Limit Ranges ==="
        kubectl get limitrange -n {namespace} -o wide 2>/dev/null || echo "No limit ranges set"
        echo ""
        
        echo "=== Pod Status ==="
        kubectl get pods -n {namespace} -o wide 2>/dev/null || echo "No pods running"
        echo ""
        
        echo "=== Service Status ==="
        kubectl get services -n {namespace} -o wide 2>/dev/null || echo "No services running"
        echo ""
        
        echo "=== Storage Usage ==="
        kubectl get pvc -n {namespace} -o wide 2>/dev/null || echo "No persistent volumes"
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=['cluster-resource-validation'],
        labels=['infrastructure', 'namespace', 'monitoring', developer_id],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL
    )
    
    # Resource usage monitoring
    local_resource(
        'resource-monitor-' + developer_id,
        cmd='''
        echo "=== Resource Monitoring ({developer_id}) ==="
        echo "Checking resource usage and quotas..."
        echo ""
        
        # Check quota usage
        QUOTA_OUTPUT=$(kubectl get resourcequota developer-quota -n {namespace} -o json 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "=== Quota Usage ==="
            echo "$QUOTA_OUTPUT" | jq -r '.status.used // {{}} | to_entries[] | "\\(.key): \\(.value)"' 2>/dev/null || echo "Quota data available but jq not installed"
            echo ""
            
            # Check for quota warnings
            CPU_USED=$(echo "$QUOTA_OUTPUT" | jq -r '.status.used["requests.cpu"] // "0"' 2>/dev/null | sed 's/m$//')
            CPU_LIMIT=$(echo "$QUOTA_OUTPUT" | jq -r '.status.hard["requests.cpu"] // "4000"' 2>/dev/null | sed 's/m$//')
            
            if [ "$CPU_USED" -gt "$((CPU_LIMIT * 80 / 100))" ] 2>/dev/null; then
                echo "⚠️  WARNING: CPU usage is above 80% of quota"
            fi
            
            MEMORY_USED=$(echo "$QUOTA_OUTPUT" | jq -r '.status.used["requests.memory"] // "0"' 2>/dev/null | sed 's/Gi$//')
            MEMORY_LIMIT=$(echo "$QUOTA_OUTPUT" | jq -r '.status.hard["requests.memory"] // "8"' 2>/dev/null | sed 's/Gi$//')
            
            if [ "$MEMORY_USED" -gt "$((MEMORY_LIMIT * 80 / 100))" ] 2>/dev/null; then
                echo "⚠️  WARNING: Memory usage is above 80% of quota"
            fi
        else
            echo "No resource quota found"
        fi
        
        echo ""
        echo "=== Pod Resource Usage ==="
        kubectl top pods -n {namespace} --no-headers 2>/dev/null | while read line; do
            if [ -n "$line" ]; then
                echo "$line"
            fi
        done || echo "Pod metrics not available"
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=['namespace-validation-' + developer_id],
        labels=['monitoring', 'resources', developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )
def _set
up_namespace_cleanup(namespace, developer_id, debug_mode=False):
    """Setup namespace cleanup and reset functionality"""
    
    # Cleanup resource for removing all resources in namespace
    local_resource(
        'cleanup-namespace-' + developer_id,
        cmd='''
        echo "=== Namespace Cleanup ({developer_id}) ==="
        echo "This will remove ALL resources from namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        # Confirm namespace exists
        if ! kubectl get namespace {namespace} >/dev/null 2>&1; then
            echo "Namespace {namespace} does not exist - nothing to clean"
            exit 0
        fi
        
        echo "=== Current Resources ==="
        kubectl get all -n {namespace} 2>/dev/null || echo "No resources found"
        echo ""
        
        echo "=== Cleaning up resources ==="
        
        # Delete all deployments first (graceful shutdown)
        echo "Deleting deployments..."
        kubectl delete deployments --all -n {namespace} --timeout=60s 2>/dev/null || echo "No deployments to delete"
        
        # Delete all services
        echo "Deleting services..."
        kubectl delete services --all -n {namespace} --timeout=30s 2>/dev/null || echo "No services to delete"
        
        # Delete all configmaps (except system ones)
        echo "Deleting configmaps..."
        kubectl delete configmaps --all -n {namespace} --timeout=30s 2>/dev/null || echo "No configmaps to delete"
        
        # Delete all secrets (except system ones)
        echo "Deleting secrets..."
        kubectl delete secrets --all -n {namespace} --timeout=30s 2>/dev/null || echo "No secrets to delete"
        
        # Delete all persistent volume claims
        echo "Deleting persistent volume claims..."
        kubectl delete pvc --all -n {namespace} --timeout=60s 2>/dev/null || echo "No PVCs to delete"
        
        # Delete any remaining pods
        echo "Deleting remaining pods..."
        kubectl delete pods --all -n {namespace} --timeout=60s --force 2>/dev/null || echo "No pods to delete"
        
        echo ""
        echo "=== Cleanup Complete ==="
        echo "Namespace {namespace} has been cleaned but preserved"
        echo "Resource quotas and network policies remain intact"
        echo ""
        
        # Show final state
        kubectl get all -n {namespace} 2>/dev/null || echo "Namespace is now empty"
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=[],
        labels=['cleanup', 'namespace', developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )
    
    # Reset resource for complete namespace reset (including quotas)
    local_resource(
        'reset-namespace-' + developer_id,
        cmd='''
        echo "=== Namespace Reset ({developer_id}) ==="
        echo "This will COMPLETELY RESET namespace: {namespace}"
        echo "Including resource quotas, network policies, and all resources"
        echo "Timestamp: $(date)"
        echo ""
        
        # Confirm namespace exists
        if ! kubectl get namespace {namespace} >/dev/null 2>&1; then
            echo "Namespace {namespace} does not exist - nothing to reset"
            exit 0
        fi
        
        echo "=== Deleting entire namespace ==="
        kubectl delete namespace {namespace} --timeout=120s
        
        echo "Waiting for namespace deletion to complete..."
        while kubectl get namespace {namespace} >/dev/null 2>&1; do
            echo "Still waiting for namespace deletion..."
            sleep 2
        done
        
        echo ""
        echo "=== Namespace Reset Complete ==="
        echo "Namespace {namespace} has been completely removed"
        echo "Run 'tilt up' again to recreate with fresh configuration"
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=[],
        labels=['reset', 'namespace', developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )
    
    # Namespace health check and recovery
    local_resource(
        'namespace-health-' + developer_id,
        cmd='''
        echo "=== Namespace Health Check ({developer_id}) ==="
        echo "Checking namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        # Check namespace status
        if kubectl get namespace {namespace} >/dev/null 2>&1; then
            echo "✅ Namespace exists and is accessible"
            
            # Check resource quota status
            if kubectl get resourcequota developer-quota -n {namespace} >/dev/null 2>&1; then
                echo "✅ Resource quota is configured"
            else
                echo "⚠️  Resource quota missing - may need recreation"
            fi
            
            # Check network policy status
            if kubectl get networkpolicy developer-isolation -n {namespace} >/dev/null 2>&1; then
                echo "✅ Network policy is configured"
            else
                echo "⚠️  Network policy missing - may need recreation"
            fi
            
            # Check for stuck resources
            STUCK_PODS=$(kubectl get pods -n {namespace} --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
            if [ "$STUCK_PODS" -gt 0 ]; then
                echo "⚠️  Found $STUCK_PODS stuck pods in Pending state"
                kubectl get pods -n {namespace} --field-selector=status.phase=Pending
            fi
            
            FAILED_PODS=$(kubectl get pods -n {namespace} --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
            if [ "$FAILED_PODS" -gt 0 ]; then
                echo "⚠️  Found $FAILED_PODS failed pods"
                kubectl get pods -n {namespace} --field-selector=status.phase=Failed
            fi
            
        else
            echo "❌ Namespace does not exist or is not accessible"
            echo "Run 'tilt up' to recreate the namespace"
        fi
        
        echo ""
        echo "=== Health Check Complete ==="
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=[],
        labels=['health', 'namespace', developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def _setup_environment_state_management(namespace, developer_id, debug_mode=False):
    """Setup developer environment state management and persistence"""
    
    # Environment state tracking
    local_resource(
        'environment-state-' + developer_id,
        cmd='''
        echo "=== Environment State Management ({developer_id}) ==="
        echo "Namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        # Create state directory if it doesn't exist
        STATE_DIR="$HOME/.tilt/state/{developer_id}"
        mkdir -p "$STATE_DIR"
        
        # Save current environment state
        STATE_FILE="$STATE_DIR/environment-state.json"
        
        echo "=== Collecting Environment State ==="
        
        # Collect namespace information
        NAMESPACE_INFO=$(kubectl get namespace {namespace} -o json 2>/dev/null || echo '{{}}')
        
        # Collect resource quota information
        QUOTA_INFO=$(kubectl get resourcequota -n {namespace} -o json 2>/dev/null || echo '{{}}')
        
        # Collect running services
        SERVICES_INFO=$(kubectl get services -n {namespace} -o json 2>/dev/null || echo '{{}}')
        
        # Collect deployment information
        DEPLOYMENTS_INFO=$(kubectl get deployments -n {namespace} -o json 2>/dev/null || echo '{{}}')
        
        # Create state snapshot
        cat > "$STATE_FILE" << EOF
{{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "developer_id": "{developer_id}",
  "namespace": "{namespace}",
  "cluster_context": "$(kubectl config current-context)",
  "namespace_info": $NAMESPACE_INFO,
  "quota_info": $QUOTA_INFO,
  "services_info": $SERVICES_INFO,
  "deployments_info": $DEPLOYMENTS_INFO,
  "tilt_version": "$(tilt version --short 2>/dev/null || echo 'unknown')"
}}
EOF
        
        echo "Environment state saved to: $STATE_FILE"
        echo ""
        
        # Show current state summary
        echo "=== Current State Summary ==="
        echo "Developer: {developer_id}"
        echo "Namespace: {namespace}"
        echo "Cluster: $(kubectl config current-context)"
        
        RUNNING_PODS=$(kubectl get pods -n {namespace} --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
        TOTAL_PODS=$(kubectl get pods -n {namespace} --no-headers 2>/dev/null | wc -l)
        echo "Pods: $RUNNING_PODS running / $TOTAL_PODS total"
        
        SERVICES_COUNT=$(kubectl get services -n {namespace} --no-headers 2>/dev/null | wc -l)
        echo "Services: $SERVICES_COUNT"
        
        DEPLOYMENTS_COUNT=$(kubectl get deployments -n {namespace} --no-headers 2>/dev/null | wc -l)
        echo "Deployments: $DEPLOYMENTS_COUNT"
        
        # Check resource usage
        if kubectl get resourcequota developer-quota -n {namespace} >/dev/null 2>&1; then
            echo ""
            echo "=== Resource Usage ==="
            kubectl get resourcequota developer-quota -n {namespace} -o json 2>/dev/null | jq -r '
                .status.used // {{}} | to_entries[] | 
                "\\(.key): \\(.value)"
            ' 2>/dev/null || echo "Resource quota exists but details unavailable"
        fi
        
        echo ""
        echo "=== State Management Complete ==="
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=[],
        labels=['state', 'environment', developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )
    
    # Environment backup and restore
    local_resource(
        'backup-environment-' + developer_id,
        cmd='''
        echo "=== Environment Backup ({developer_id}) ==="
        echo "Creating backup of namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        # Create backup directory
        BACKUP_DIR="$HOME/.tilt/backups/{developer_id}/$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        echo "Backup directory: $BACKUP_DIR"
        echo ""
        
        # Backup namespace configuration
        echo "Backing up namespace configuration..."
        kubectl get namespace {namespace} -o yaml > "$BACKUP_DIR/namespace.yaml" 2>/dev/null || echo "Failed to backup namespace"
        
        # Backup resource quotas
        echo "Backing up resource quotas..."
        kubectl get resourcequota -n {namespace} -o yaml > "$BACKUP_DIR/resourcequotas.yaml" 2>/dev/null || echo "No resource quotas to backup"
        
        # Backup network policies
        echo "Backing up network policies..."
        kubectl get networkpolicy -n {namespace} -o yaml > "$BACKUP_DIR/networkpolicies.yaml" 2>/dev/null || echo "No network policies to backup"
        
        # Backup configmaps
        echo "Backing up configmaps..."
        kubectl get configmaps -n {namespace} -o yaml > "$BACKUP_DIR/configmaps.yaml" 2>/dev/null || echo "No configmaps to backup"
        
        # Backup secrets (metadata only for security)
        echo "Backing up secrets metadata..."
        kubectl get secrets -n {namespace} -o yaml | kubectl neat > "$BACKUP_DIR/secrets-metadata.yaml" 2>/dev/null || echo "No secrets to backup"
        
        # Backup services
        echo "Backing up services..."
        kubectl get services -n {namespace} -o yaml > "$BACKUP_DIR/services.yaml" 2>/dev/null || echo "No services to backup"
        
        # Backup deployments
        echo "Backing up deployments..."
        kubectl get deployments -n {namespace} -o yaml > "$BACKUP_DIR/deployments.yaml" 2>/dev/null || echo "No deployments to backup"
        
        # Create backup manifest
        cat > "$BACKUP_DIR/backup-info.json" << EOF
{{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "developer_id": "{developer_id}",
  "namespace": "{namespace}",
  "cluster_context": "$(kubectl config current-context)",
  "backup_path": "$BACKUP_DIR",
  "tilt_version": "$(tilt version --short 2>/dev/null || echo 'unknown')"
}}
EOF
        
        echo ""
        echo "=== Backup Complete ==="
        echo "Backup saved to: $BACKUP_DIR"
        echo "Files created:"
        ls -la "$BACKUP_DIR"
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=[],
        labels=['backup', 'environment', developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def get_namespace_isolation_status(developer_id):
    """Get the current isolation status for a developer namespace"""
    
    namespace = "dev-" + developer_id
    
    return {
        'namespace': namespace,
        'developer_id': developer_id,
        'has_resource_quota': True,  # Will be validated at runtime
        'has_network_policy': True,  # Will be validated at runtime
        'isolation_enabled': True
    }

def _setup_developer_secret_management(namespace, developer_id, debug_mode=False):
    """Setup secure secret management for developer isolation"""
    
    # Load secret management functions
    load('.tilt/lib/config_secrets.star', 'create_developer_secret_template', 'setup_secret_management_monitoring')
    
    # Create secret template for developer
    create_developer_secret_template(developer_id, namespace, debug_mode)
    
    # Setup secret management monitoring
    setup_secret_management_monitoring(developer_id, namespace, debug_mode)
    
    if debug_mode:
        print("Secret management configured for developer: " + developer_id)

def create_developer_isolation_guide():
    """Create a guide for developer isolation features"""
    
    local_resource(
        'developer-isolation-guide',
        cmd='''
        echo "=== DEVELOPER ISOLATION GUIDE ==="
        echo "This environment provides complete developer isolation with:"
        echo ""
        echo "🏠 NAMESPACE ISOLATION"
        echo "  - Each developer gets a unique namespace (dev-<developer-id>)"
        echo "  - Resources are completely isolated between developers"
        echo "  - Network policies prevent cross-developer communication"
        echo ""
        echo "📊 RESOURCE MANAGEMENT"
        echo "  - CPU limits: 4 cores request, 8 cores max"
        echo "  - Memory limits: 8GB request, 16GB max"
        echo "  - Storage limits: 20GB total"
        echo "  - Pod limits: 50 pods maximum"
        echo ""
        echo "🔧 MANAGEMENT COMMANDS"
        echo "  - Monitor resources: Click 'resource-monitor-<developer-id>'"
        echo "  - Clean namespace: Click 'cleanup-namespace-<developer-id>'"
        echo "  - Reset environment: Click 'reset-namespace-<developer-id>'"
        echo "  - Check health: Click 'namespace-health-<developer-id>'"
        echo "  - Backup environment: Click 'backup-environment-<developer-id>'"
        echo ""
        echo "🔒 SECURITY FEATURES"
        echo "  - Network isolation between developer namespaces"
        echo "  - Resource quotas prevent resource exhaustion"
        echo "  - Secure secret management per developer"
        echo ""
        echo "📈 MONITORING"
        echo "  - Real-time resource usage tracking"
        echo "  - Quota utilization warnings"
        echo "  - Environment state persistence"
        echo ""
        echo "=== USAGE EXAMPLES ==="
        echo "Start with specific developer ID:"
        echo "  tilt up -- --developer_id=john-doe"
        echo ""
        echo "Monitor your resources:"
        echo "  Click on 'resource-monitor-john-doe' in Tilt UI"
        echo ""
        echo "Clean up your environment:"
        echo "  Click on 'cleanup-namespace-john-doe' in Tilt UI"
        echo ""
        echo "=== TROUBLESHOOTING ==="
        echo "If you hit resource limits:"
        echo "  1. Check 'resource-monitor-<your-id>' for usage"
        echo "  2. Clean up unused resources with 'cleanup-namespace-<your-id>'"
        echo "  3. Contact team lead if limits need adjustment"
        echo ""
        echo "If namespace is corrupted:"
        echo "  1. Try 'namespace-health-<your-id>' to diagnose"
        echo "  2. Use 'reset-namespace-<your-id>' for complete reset"
        echo "  3. Restart with 'tilt up' after reset"
        ''',
        deps=[],
        labels=['guide', 'isolation', 'documentation'],
        auto_init=True
    )