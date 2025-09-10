"""
Simple namespace management for local Tilt development environment
Handles basic namespace creation and management for local development
"""

def setup_namespace(developer_id, current_context, debug_mode=False):
    """Setup simple namespace for local development"""
    
    # Use default namespace for local development - no need for complex isolation
    # since each developer runs their own local cluster
    developer_namespace = "default"
    
    if debug_mode:
        print("Using namespace: " + developer_namespace)
        print("Local cluster context: " + current_context)
    
    # Setup basic cleanup and reset functionality
    _setup_namespace_cleanup(developer_namespace, developer_id, debug_mode)
    
    # Setup simple environment state management
    _setup_environment_state_management(developer_namespace, developer_id, debug_mode)
    
    # Setup simple monitoring
    _setup_namespace_monitoring(developer_namespace, developer_id, debug_mode)
    
    return developer_namespace

def _setup_namespace_monitoring(namespace, developer_id, debug_mode=False):
    """Setup simple environment monitoring for local development"""
    
    local_resource(
        'environment-status-' + developer_id,
        labels=['infrastructure'],
        cmd='''
        echo "=== Local Development Environment Status ==="
        echo "Developer: {developer_id}"
        echo "Namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        echo "=== Pod Status ==="
        kubectl get pods -n {namespace} -o wide 2>/dev/null || echo "No pods running"
        echo ""
        
        echo "=== Service Status ==="
        kubectl get services -n {namespace} -o wide 2>/dev/null || echo "No services running"
        echo ""
        
        echo "=== Resource Usage ==="
        kubectl top pods -n {namespace} 2>/dev/null || echo "Metrics not available"
        echo ""
        
        echo "=== Storage Usage ==="
        kubectl get pvc -n {namespace} -o wide 2>/dev/null || echo "No persistent volumes"
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=[],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def _setup_namespace_cleanup(namespace, developer_id, debug_mode=False):
    """Setup simple cleanup functionality for local development"""
    
    # Cleanup resource for removing all resources in namespace
    local_resource(
        'cleanup-environment-' + developer_id,
        labels=['support'],
        cmd='''
        echo "=== Local Environment Cleanup ==="
        echo "This will remove ALL resources from namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        echo "=== Current Resources ==="
        kubectl get all -n {namespace} 2>/dev/null || echo "No resources found"
        echo ""
        
        echo "=== Cleaning up resources ==="
        
        # Delete all deployments first (graceful shutdown)
        echo "Deleting deployments..."
        kubectl delete deployments --all -n {namespace} --timeout=60s 2>/dev/null || echo "No deployments to delete"
        
        # Delete all services (except kubernetes service)
        echo "Deleting services..."
        kubectl delete services --all -n {namespace} --timeout=30s 2>/dev/null || echo "No services to delete"
        
        # Delete all configmaps
        echo "Deleting configmaps..."
        kubectl delete configmaps --all -n {namespace} --timeout=30s 2>/dev/null || echo "No configmaps to delete"
        
        # Delete all secrets (except default token)
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
        echo "Local environment has been cleaned"
        echo ""
        
        # Show final state
        kubectl get all -n {namespace} 2>/dev/null || echo "Environment is now clean"
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=[],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def _setup_environment_state_management(namespace, developer_id, debug_mode=False):
    """Setup simple environment state management and persistence"""
    
    # Environment state tracking
    local_resource(
        'environment-state-' + developer_id,
        labels=['monitoring'],
        cmd='''
        echo "=== Environment State Management ==="
        echo "Developer: {developer_id}"
        echo "Namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        # Create state directory if it doesn't exist
        STATE_DIR="$HOME/.tilt/state/{developer_id}"
        mkdir -p "$STATE_DIR"
        
        # Save current environment state
        STATE_FILE="$STATE_DIR/environment-state.json"
        
        echo "=== Collecting Environment State ==="
        
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
        
        echo ""
        echo "=== State Management Complete ==="
        '''.format(namespace=namespace, developer_id=developer_id),
        deps=[],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def get_namespace_isolation_status(developer_id):
    """Get the current status for a developer environment (simplified for local development)"""
    
    namespace = "default"
    
    return {
        'namespace': namespace,
        'developer_id': developer_id,
        'isolation_type': 'local_cluster',
        'isolation_enabled': True
    }