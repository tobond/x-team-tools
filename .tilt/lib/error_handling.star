"""
Error handling and recovery systems for Tilt development environment
Provides comprehensive error reporting, warnings, recovery mechanisms, and troubleshooting
"""

def setup_error_handling_system(namespace, services_to_deploy, tilt_config):
    """Setup comprehensive error handling and recovery system"""
    
    # Disable snapshots for better error recovery
    disable_snapshots()
    
    # Setup error monitoring and reporting
    setup_error_monitoring(namespace, services_to_deploy)
    
    # Setup recovery mechanisms
    setup_recovery_resources(namespace, services_to_deploy)
    
    # Setup environment validation
    setup_environment_validation(tilt_config)
    
    # Setup troubleshooting resources
    setup_troubleshooting_resources(namespace, services_to_deploy)

def validate_environment_safety(tilt_config):
    """Validate environment safety with comprehensive error reporting"""
    
    try:
        # Validate cluster context
        current_context = str(local('kubectl config current-context')).strip()
        
        # Check for dangerous patterns with detailed error messages
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
            ('.amazonaws.com', 'AWS managed cluster'),
            ('.gke.', 'Google Cloud managed cluster')
        ]
        
        context_lower = current_context.lower()
        for pattern, description in dangerous_patterns:
            if pattern in context_lower:
                fail("""
🚨 CRITICAL SAFETY VIOLATION: Dangerous cluster context detected!

Context: '{}'
Issue: Detected {} pattern: '{}'

This appears to be a {} which is STRICTLY PROHIBITED for local development.

IMMEDIATE ACTION REQUIRED:
1. Switch to a safe local development cluster:
   kubectl config use-context docker-desktop
   kubectl config use-context kind-tilt-dev
   kubectl config use-context k3d-dev

2. Verify your cluster is local:
   kubectl cluster-info

3. If you need to work with this cluster, use appropriate tools:
   - Production: Use CI/CD pipelines
   - Staging: Use dedicated staging deployment tools
   - Cloud: Use cloud-native deployment methods

SAFETY FIRST: This protection prevents accidental damage to critical environments.
                """.format(current_context, description, pattern, description))
        
        return current_context
        
    except Exception as e:
        fail("""
🚨 ENVIRONMENT VALIDATION FAILED

Unable to validate cluster context safety.

Error: {}

TROUBLESHOOTING STEPS:
1. Verify kubectl is installed and configured:
   kubectl version --client

2. Check if you have a valid kubeconfig:
   kubectl config view

3. Ensure you have access to a local Kubernetes cluster:
   kubectl cluster-info

4. If using Docker Desktop, ensure Kubernetes is enabled
5. If using kind/k3d, ensure your cluster is running

SAFETY NOTE: Cannot proceed without valid cluster context validation.
        """.format(str(e)))

def handle_service_deployment_error(service_name, error, recovery_suggestions=None):
    """Handle service deployment errors with actionable recovery steps"""
    
    error_msg = str(error)
    
    # Categorize error types and provide specific guidance
    if "ImagePullBackOff" in error_msg or "ErrImagePull" in error_msg:
        fail("""
🚨 IMAGE PULL ERROR: Service '{}' failed to pull container image

Error: {}

RECOVERY ACTIONS:
1. Check if ECR image exists and is accessible:
   aws ecr describe-images --repository-name <repo-name>

2. Verify ECR authentication:
   aws ecr get-login-password | docker login --username AWS --password-stdin <ecr-url>

3. Try building locally instead:
   tilt up -- --services={} --build_local={}

4. Check image tag in service-config.yaml
5. Verify network connectivity to ECR

ALTERNATIVE: Use local build while investigating:
   tilt up -- --build_local={}
        """.format(service_name, error_msg, service_name, service_name, service_name))
    
    elif "CrashLoopBackOff" in error_msg:
        fail("""
🚨 SERVICE CRASH: Service '{}' is crashing repeatedly

Error: {}

IMMEDIATE ACTIONS:
1. Check service logs:
   kubectl logs -l app={} -n <namespace> --tail=50

2. Check service configuration:
   kubectl describe pod -l app={} -n <namespace>

3. Verify environment variables and secrets
4. Check resource limits and requests
5. Validate health check endpoints

DEBUGGING COMMANDS:
   tilt trigger {}-monitor    # View detailed service status
   kubectl exec -it <pod> -- /bin/sh  # Debug inside container

RECOVERY: Fix the underlying issue and restart:
   tilt trigger {}
        """.format(service_name, error_msg, service_name, service_name, service_name, service_name))
    
    elif "Insufficient" in error_msg or "resource" in error_msg.lower():
        fail("""
🚨 RESOURCE SHORTAGE: Insufficient cluster resources for service '{}'

Error: {}

RESOURCE MANAGEMENT:
1. Check cluster resource usage:
   kubectl top nodes
   kubectl top pods --all-namespaces

2. Free up resources:
   tilt trigger cleanup-failed-resources  # Clean unused resources
   docker system prune -f           # Clean Docker resources

3. Reduce resource requests in service-config.yaml
4. Scale down other services temporarily

CLUSTER EXPANSION:
   - Docker Desktop: Increase memory/CPU in settings
   - Kind: Recreate cluster with more resources
   - K3d: Add more nodes or increase limits

IMMEDIATE FIX: Reduce resource requests for '{}'
        """.format(service_name, error_msg, service_name))
    
    else:
        # Generic error handling with recovery suggestions
        recovery_steps = recovery_suggestions or [
            "Check service logs: tilt trigger {}-monitor".format(service_name),
            "Verify service configuration in service-config.yaml",
            "Check cluster resources: tilt trigger resource-monitor",
            "Try restarting the service: tilt trigger {}".format(service_name),
            "Reset environment: tilt trigger cleanup-environment"
        ]
        
        fail("""
🚨 SERVICE DEPLOYMENT ERROR: Failed to deploy '{}'

Error: {}

RECOVERY STEPS:
{}

DEBUGGING RESOURCES:
   • Service Monitor: tilt trigger {}-monitor
   • Environment Debug: tilt trigger debug-environment
   • Resource Monitor: tilt trigger resource-monitor
   • Cleanup & Restart: tilt trigger cleanup-environment

If the issue persists, check the Tilt UI for detailed logs and status.
        """.format(
            service_name, 
            error_msg,
            '\n'.join(['   {}. {}'.format(i+1, step) for i, step in enumerate(recovery_steps)]),
            service_name
        ))

def warn_configuration_issue(service_name, issue, suggestion):
    """Issue configuration warnings for non-fatal issues"""
    
    warn("""
⚠️  CONFIGURATION WARNING: Service '{}'

Issue: {}
Suggestion: {}

This is not a fatal error, but may affect service functionality.
The service will continue to deploy with current configuration.
    """.format(service_name, issue, suggestion))

def setup_recovery_resources(namespace, services_to_deploy):
    """Setup comprehensive recovery resources with auto-cleanup capabilities"""
    
    # Cleanup failed resources
    local_resource(
        'cleanup-failed-resources',
        cmd='''
        echo "🧹 CLEANING UP FAILED RESOURCES"
        echo "==============================="
        echo "Namespace: ''' + namespace + '''"
        echo ""
        
        echo "🗑️  Removing failed pods..."
        FAILED_COUNT=$(kubectl get pods -n ''' + namespace + ''' --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
        if [ "$FAILED_COUNT" -gt 0 ]; then
            kubectl delete pods --field-selector=status.phase=Failed -n ''' + namespace + ''' --ignore-not-found=true
            echo "✅ Removed $FAILED_COUNT failed pods"
        else
            echo "✅ No failed pods to clean"
        fi
        echo ""
        
        echo "🔄 Restarting crash-looping pods..."
        CRASH_PODS=$(kubectl get pods -n ''' + namespace + ''' -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.containerStatuses[0].restartCount}{"\n"}{end}' 2>/dev/null | awk '$2 > 5 {print $1}')
        if [ -n "$CRASH_PODS" ]; then
            echo "$CRASH_PODS" | xargs -r kubectl delete pod -n ''' + namespace + '''
            echo "✅ Restarted crash-looping pods"
        else
            echo "✅ No crash-looping pods to restart"
        fi
        echo ""
        
        echo "🧽 Cleaning up completed jobs..."
        kubectl delete jobs --field-selector=status.successful=1 -n ''' + namespace + ''' --ignore-not-found=true 2>/dev/null || true
        echo "✅ Cleaned up completed jobs"
        echo ""
        
        echo "♻️  Cleanup complete! Services should recover automatically."
        ''',
        deps=[],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['recovery', 'cleanup', 'maintenance']
    )
    
    # Restart all services
    local_resource(
        'restart-all-services',
        cmd='''
        echo "🔄 RESTARTING ALL SERVICES"
        echo "========================="
        echo "Namespace: ''' + namespace + '''"
        echo ""
        
        ''' + '\n        '.join([
            '''
        echo "🔄 Restarting {}..."
        kubectl rollout restart deployment/{} -n {} 2>/dev/null || echo "⚠️  No deployment found for {}"
        '''.format(service, service, namespace, service) for service in (services_to_deploy if services_to_deploy else [])
        ]) + '''
        
        echo ""
        echo "⏳ Waiting for rollouts to complete..."
        ''' + '\n        '.join([
            '''kubectl rollout status deployment/{} -n {} --timeout=60s 2>/dev/null || echo "⚠️  Timeout waiting for {}"'''.format(service, namespace, service) 
            for service in (services_to_deploy if services_to_deploy else [])
        ]) + '''
        
        echo ""
        echo "✅ Service restart complete!"
        echo "💡 Check individual service monitors for status updates"
        ''',
        deps=services_to_deploy if services_to_deploy else [],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['recovery', 'restart', 'services']
    )
    
    # Emergency reset
    local_resource(
        'emergency-reset',
        cmd='''
        echo "🚨 EMERGENCY ENVIRONMENT RESET"
        echo "=============================="
        echo "⚠️  WARNING: This will destroy ALL resources in namespace ''' + namespace + '''"
        echo "⚠️  This action cannot be undone!"
        echo ""
        echo "Proceeding in 5 seconds... (Ctrl+C to cancel)"
        sleep 5
        echo ""
        
        echo "🗑️  Deleting all resources..."
        kubectl delete all --all -n ''' + namespace + ''' --ignore-not-found=true --timeout=60s
        kubectl delete configmaps --all -n ''' + namespace + ''' --ignore-not-found=true
        kubectl delete secrets --all -n ''' + namespace + ''' --ignore-not-found=true --field-selector type!=kubernetes.io/service-account-token
        kubectl delete pvc --all -n ''' + namespace + ''' --ignore-not-found=true
        
        echo ""
        echo "🔄 Recreating namespace..."
        kubectl delete namespace ''' + namespace + ''' --ignore-not-found=true --timeout=60s
        kubectl create namespace ''' + namespace + ''' 2>/dev/null || true
        
        echo ""
        echo "✅ Emergency reset complete!"
        echo "💡 Restart Tilt to redeploy services"
        echo "💡 Command: tilt up -- --services=<your-services>"
        ''',
        deps=[],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['recovery', 'emergency', 'reset']
    )def set
up_error_monitoring(namespace, services_to_deploy):
    """Setup comprehensive error monitoring resources"""
    
    local_resource(
        'error-monitor',
        cmd='''
        echo "🚨 ERROR MONITORING DASHBOARD"
        echo "============================"
        echo "Namespace: ''' + namespace + '''"
        echo "Monitoring {} services for errors..."
        echo ""
        
        echo "🔍 FAILED PODS"
        echo "-------------"
        FAILED_PODS=$(kubectl get pods -n ''' + namespace + ''' --field-selector=status.phase=Failed --no-headers 2>/dev/null)
        if [ -n "$FAILED_PODS" ]; then
            echo "$FAILED_PODS"
            echo ""
            echo "🔧 RECOVERY: Delete failed pods to retry:"
            echo "kubectl delete pods --field-selector=status.phase=Failed -n ''' + namespace + '''"
        else
            echo "✅ No failed pods detected"
        fi
        echo ""
        
        echo "🔄 CRASH LOOPING PODS"
        echo "--------------------"
        CRASH_PODS=$(kubectl get pods -n ''' + namespace + ''' -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.containerStatuses[0].restartCount}{"\n"}{end}' 2>/dev/null | awk '$2 > 3 {print $1 " (restarts: " $2 ")"}')
        if [ -n "$CRASH_PODS" ]; then
            echo "$CRASH_PODS"
            echo ""
            echo "🔧 RECOVERY: Check logs and fix underlying issues"
        else
            echo "✅ No crash looping pods detected"
        fi
        echo ""
        
        echo "⚠️  WARNING EVENTS"
        echo "-----------------"
        kubectl get events -n ''' + namespace + ''' --field-selector type=Warning --sort-by='.lastTimestamp' --no-headers | tail -5 2>/dev/null || echo "No warning events"
        echo ""
        
        echo "❌ ERROR EVENTS"
        echo "---------------"
        kubectl get events -n ''' + namespace + ''' --field-selector type=Error --sort-by='.lastTimestamp' --no-headers | tail -5 2>/dev/null || echo "No error events"
        echo ""
        
        echo "🔧 QUICK RECOVERY ACTIONS"
        echo "========================"
        echo "• Restart all services: tilt trigger restart-all-services"
        echo "• Clean failed resources: tilt trigger cleanup-failed-resources"
        echo "• Reset environment: tilt trigger emergency-reset"
        echo "• Debug specific service: tilt trigger <service-name>-monitor"
        ''',
        deps=services_to_deploy if services_to_deploy else [],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['error-monitoring', 'recovery', 'debugging']
    )

def setup_environment_validation(tilt_config):
    """Setup comprehensive environment validation with detailed error reporting"""
    
    local_resource(
        'environment-validator',
        cmd='''
        echo "🔍 ENVIRONMENT VALIDATION"
        echo "========================"
        echo "Developer: ''' + tilt_config.get("developer_id", "unknown") + '''"
        echo "Cluster Type: ''' + tilt_config.get("cluster_type", "unknown") + '''"
        echo ""
        
        VALIDATION_ERRORS=0
        
        echo "🔧 KUBECTL VALIDATION"
        echo "--------------------"
        if kubectl version --client >/dev/null 2>&1; then
            echo "✅ kubectl is installed and accessible"
            KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | grep Client || echo "Unknown version")
            echo "   Version: $KUBECTL_VERSION"
        else
            echo "❌ kubectl is not installed or not accessible"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
        echo ""
        
        echo "🏗️  CLUSTER CONNECTIVITY"
        echo "-----------------------"
        if kubectl cluster-info >/dev/null 2>&1; then
            echo "✅ Cluster is accessible"
            CLUSTER_INFO=$(kubectl cluster-info | head -1)
            echo "   $CLUSTER_INFO"
        else
            echo "❌ Cannot connect to cluster"
            echo "   Check: kubectl config current-context"
            echo "   Check: kubectl cluster-info"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
        echo ""
        
        echo "🔒 CLUSTER SAFETY"
        echo "----------------"
        CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "unknown")
        case "$CURRENT_CONTEXT" in
            *prod*|*production*|*staging*|*stage*|*live*|*aws*|*gke*|*aks*|*eks*)
                echo "❌ DANGEROUS CONTEXT: $CURRENT_CONTEXT"
                echo "   This appears to be a production/staging cluster!"
                echo "   Switch to a local development cluster immediately"
                VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
                ;;
            docker-desktop|docker-for-desktop|kind-*|k3d-*|minikube)
                echo "✅ Safe local development context: $CURRENT_CONTEXT"
                ;;
            *)
                echo "⚠️  Unknown context pattern: $CURRENT_CONTEXT"
                echo "   Verify this is a local development cluster"
                ;;
        esac
        echo ""
        
        echo "💾 DOCKER VALIDATION"
        echo "-------------------"
        if docker version >/dev/null 2>&1; then
            echo "✅ Docker is running and accessible"
            DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "Unknown")
            echo "   Version: $DOCKER_VERSION"
        else
            echo "❌ Docker is not running or not accessible"
            echo "   Start Docker Desktop or Docker daemon"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
        echo ""
        
        echo "📊 RESOURCE AVAILABILITY"
        echo "-----------------------"
        if kubectl top nodes >/dev/null 2>&1; then
            echo "✅ Metrics server is available"
            kubectl top nodes | head -3
        else
            echo "⚠️  Metrics server not available (optional)"
            echo "   Resource monitoring will be limited"
        fi
        echo ""
        
        echo "🎯 VALIDATION SUMMARY"
        echo "===================="
        if [ $VALIDATION_ERRORS -eq 0 ]; then
            echo "✅ Environment validation PASSED"
            echo "✅ Ready for safe local development"
        else
            echo "❌ Environment validation FAILED ($VALIDATION_ERRORS errors)"
            echo "❌ Fix the above issues before proceeding"
            echo ""
            echo "🔧 COMMON FIXES:"
            echo "   • Install kubectl: https://kubernetes.io/docs/tasks/tools/"
            echo "   • Start Docker Desktop"
            echo "   • Switch cluster context: kubectl config use-context docker-desktop"
            echo "   • Check cluster status: kubectl cluster-info"
        fi
        ''',
        deps=[],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['validation', 'environment', 'safety']
    )

def setup_error_monitoring(namespace, services_to_deploy):
    """Setup comprehensive error monitoring resources"""
    
    local_resource(
        'error-monitor',
        cmd='''
        echo "🚨 ERROR MONITORING DASHBOARD"
        echo "============================"
        echo "Namespace: ''' + namespace + '''"
        echo "Monitoring {} services for errors..."
        echo ""
        
        echo "🔍 FAILED PODS"
        echo "-------------"
        FAILED_PODS=$(kubectl get pods -n ''' + namespace + ''' --field-selector=status.phase=Failed --no-headers 2>/dev/null)
        if [ -n "$FAILED_PODS" ]; then
            echo "$FAILED_PODS"
            echo ""
            echo "🔧 RECOVERY: Delete failed pods to retry:"
            echo "kubectl delete pods --field-selector=status.phase=Failed -n ''' + namespace + '''"
        else
            echo "✅ No failed pods detected"
        fi
        echo ""
        
        echo "🔄 CRASH LOOPING PODS"
        echo "--------------------"
        CRASH_PODS=$(kubectl get pods -n ''' + namespace + ''' -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.containerStatuses[0].restartCount}{"\n"}{end}' 2>/dev/null | awk '$2 > 3 {print $1 " (restarts: " $2 ")"}')
        if [ -n "$CRASH_PODS" ]; then
            echo "$CRASH_PODS"
            echo ""
            echo "🔧 RECOVERY: Check logs and fix underlying issues"
        else
            echo "✅ No crash looping pods detected"
        fi
        echo ""
        
        echo "⚠️  WARNING EVENTS"
        echo "-----------------"
        kubectl get events -n ''' + namespace + ''' --field-selector type=Warning --sort-by='.lastTimestamp' --no-headers | tail -5 2>/dev/null || echo "No warning events"
        echo ""
        
        echo "❌ ERROR EVENTS"
        echo "---------------"
        kubectl get events -n ''' + namespace + ''' --field-selector type=Error --sort-by='.lastTimestamp' --no-headers | tail -5 2>/dev/null || echo "No error events"
        echo ""
        
        echo "🔧 QUICK RECOVERY ACTIONS"
        echo "========================"
        echo "• Restart all services: tilt trigger restart-all-services"
        echo "• Clean failed resources: tilt trigger cleanup-failed-resources"
        echo "• Reset environment: tilt trigger emergency-reset"
        echo "• Debug specific service: tilt trigger <service-name>-monitor"
        ''',
        deps=services_to_deploy if services_to_deploy else [],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['error-monitoring', 'recovery', 'debugging']
    )

def setup_troubleshooting_resources(namespace, services_to_deploy):
    """Setup comprehensive troubleshooting and diagnostic resources"""
    
    local_resource(
        'troubleshooting-guide',
        cmd='''
        echo "🔧 TROUBLESHOOTING GUIDE"
        echo "======================="
        echo "Namespace: ''' + namespace + '''"
        echo ""
        
        echo "🚨 COMMON ISSUES & SOLUTIONS"
        echo "============================"
        echo ""
        echo "1. SERVICE WON'T START"
        echo "   Symptoms: Pod stuck in Pending/CrashLoopBackOff"
        echo "   Solutions:"
        echo "   • Check logs: tilt trigger <service>-monitor"
        echo "   • Check resources: tilt trigger resource-monitor"
        echo "   • Verify image: Check ECR access or try local build"
        echo "   • Check config: Review service-config.yaml"
        echo ""
        echo "2. IMAGE PULL ERRORS"
        echo "   Symptoms: ImagePullBackOff, ErrImagePull"
        echo "   Solutions:"
        echo "   • Try local build: tilt up -- --build_local=<service>"
        echo "   • Check ECR auth: aws ecr get-login-password"
        echo "   • Verify image exists: aws ecr describe-images"
        echo "   • Check network connectivity"
        echo ""
        echo "3. PORT CONFLICTS"
        echo "   Symptoms: Port already in use errors"
        echo "   Solutions:"
        echo "   • Check running processes: lsof -i :<port>"
        echo "   • Kill conflicting process: kill -9 <pid>"
        echo "   • Change port in service-config.yaml"
        echo "   • Use different port forwarding"
        echo ""
        echo "4. RESOURCE EXHAUSTION"
        echo "   Symptoms: Insufficient CPU/memory errors"
        echo "   Solutions:"
        echo "   • Check usage: tilt trigger resource-monitor"
        echo "   • Clean up: tilt trigger cleanup-failed-resources"
        echo "   • Reduce requests in service-config.yaml"
        echo "   • Increase Docker Desktop resources"
        echo ""
        
        echo "🔍 DIAGNOSTIC COMMANDS"
        echo "====================="
        echo "• Environment check: tilt trigger environment-validator"
        echo "• Error monitoring: tilt trigger error-monitor"
        echo "• Service health: tilt trigger service-health-check"
        echo "• Resource usage: tilt trigger resource-monitor"
        echo "• Debug environment: tilt trigger debug-environment"
        echo ""
        
        echo "🆘 EMERGENCY PROCEDURES"
        echo "======================"
        echo "• Clean failed resources: tilt trigger cleanup-failed-resources"
        echo "• Restart all services: tilt trigger restart-all-services"
        echo "• Reset environment: tilt trigger emergency-reset"
        echo "• Complete restart: Stop Tilt, run emergency-reset, restart Tilt"
        ''',
        deps=[],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['troubleshooting', 'guide', 'help']
    )

def create_error_recovery_dashboard(namespace, services_to_deploy):
    """Create comprehensive error recovery dashboard"""
    
    local_resource(
        'error-recovery-dashboard',
        cmd='''
        clear
        echo "🚨 ERROR RECOVERY DASHBOARD"
        echo "==========================="
        echo "Namespace: ''' + namespace + '''"
        echo "Services: ''' + str(len(services_to_deploy) if services_to_deploy else 0) + '''"
        echo "Updated: $(date)"
        echo ""
        
        # Check overall system health
        OVERALL_STATUS="✅ HEALTHY"
        ERROR_COUNT=0
        
        echo "🏥 SYSTEM HEALTH CHECK"
        echo "====================="
        
        # Check for failed pods
        FAILED_PODS=$(kubectl get pods -n ''' + namespace + ''' --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
        if [ "$FAILED_PODS" -gt 0 ]; then
            echo "❌ Failed Pods: $FAILED_PODS"
            OVERALL_STATUS="❌ UNHEALTHY"
            ERROR_COUNT=$((ERROR_COUNT + FAILED_PODS))
        else
            echo "✅ Failed Pods: 0"
        fi
        
        # Check for crash looping pods
        CRASH_PODS=$(kubectl get pods -n ''' + namespace + ''' -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.containerStatuses[0].restartCount}{"\n"}{end}' 2>/dev/null | awk '$2 > 3' | wc -l)
        if [ "$CRASH_PODS" -gt 0 ]; then
            echo "⚠️  Crash Looping: $CRASH_PODS"
            if [ "$OVERALL_STATUS" = "✅ HEALTHY" ]; then
                OVERALL_STATUS="⚠️  DEGRADED"
            fi
            ERROR_COUNT=$((ERROR_COUNT + CRASH_PODS))
        else
            echo "✅ Crash Looping: 0"
        fi
        
        # Check for pending pods
        PENDING_PODS=$(kubectl get pods -n ''' + namespace + ''' --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
        if [ "$PENDING_PODS" -gt 0 ]; then
            echo "🔄 Pending Pods: $PENDING_PODS"
            if [ "$OVERALL_STATUS" = "✅ HEALTHY" ]; then
                OVERALL_STATUS="🔄 STARTING"
            fi
        else
            echo "✅ Pending Pods: 0"
        fi
        
        echo ""
        echo "📊 OVERALL STATUS: $OVERALL_STATUS"
        echo "🔢 Total Issues: $ERROR_COUNT"
        echo ""
        
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo "🔧 RECOMMENDED RECOVERY ACTIONS"
            echo "==============================="
            echo "1. 🧹 Clean failed resources: tilt trigger cleanup-failed-resources"
            echo "2. 🔄 Restart problematic services: tilt trigger restart-all-services"
            echo "3. 🔍 Check detailed errors: tilt trigger error-monitor"
            echo "4. 📋 Collect diagnostics: tilt trigger collect-diagnostics"
            echo "5. 🆘 Emergency reset: tilt trigger emergency-reset"
            echo ""
        fi
        
        echo "🎛️  RECOVERY TOOLS"
        echo "=================="
        echo "• Error Monitor: tilt trigger error-monitor"
        echo "• Troubleshooting Guide: tilt trigger troubleshooting-guide"
        echo "• Environment Validator: tilt trigger environment-validator"
        echo "• Resource Monitor: tilt trigger resource-monitor"
        echo "• Service Health: tilt trigger service-health-check"
        echo ""
        
        echo "💡 TIP: Use the specific recovery tools above to diagnose and fix issues"
        ''',
        deps=services_to_deploy if services_to_deploy else [],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['error-recovery', 'dashboard', 'health']
    )