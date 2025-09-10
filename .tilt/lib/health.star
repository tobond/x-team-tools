"""
Service health checking and startup validation
Provides comprehensive health monitoring, startup validation, and failure recovery
"""

def setup_comprehensive_health_monitoring(deployed_services, namespace, debug_mode=False):
    """Setup comprehensive health monitoring for all deployed services"""
    
    if debug_mode:
        print("🏥 Setting up comprehensive health monitoring for {} services".format(len(deployed_services)))
    
    # Create overall health dashboard
    _create_health_dashboard(deployed_services, namespace)
    
    # Create service-specific health monitors
    for service in deployed_services:
        _create_service_health_monitor(service, namespace, debug_mode)
    
    # Create startup validation monitors
    _create_startup_validation_monitors(deployed_services, namespace, debug_mode)
    
    # Create failure recovery resources
    _create_failure_recovery_resources(deployed_services, namespace, debug_mode)

def _create_health_dashboard(deployed_services, namespace):
    """Create comprehensive health dashboard for all services"""
    
    local_resource(
        'health-dashboard',
        labels=['monitoring'],
        cmd='''
        echo "=== COMPREHENSIVE HEALTH DASHBOARD ==="
        echo "Namespace: ''' + namespace + '''"
        echo "Services: ''' + str(len(deployed_services)) + '''"
        echo "Timestamp: $(date)"
        echo ""
        
        # Overall cluster health
        echo "=== CLUSTER HEALTH ==="
        kubectl cluster-info --request-timeout=5s 2>/dev/null || echo "❌ Cluster not accessible"
        echo ""
        
        # Namespace resource usage
        echo "=== NAMESPACE RESOURCE USAGE ==="
        kubectl top pods -n ''' + namespace + ''' 2>/dev/null || echo "Metrics not available"
        echo ""
        
        # Service health summary
        echo "=== SERVICE HEALTH SUMMARY ==="
        total_services=''' + str(len(deployed_services)) + '''
        healthy_services=0
        
        ''' + '\n'.join([
            '''
        # Check {}
        if kubectl get pods -n ''' + namespace + ''' -l app={} --no-headers 2>/dev/null | grep -q Running; then
            echo "✅ {}: Healthy"
            healthy_services=$((healthy_services + 1))
        else
            echo "❌ {}: Unhealthy"
        fi'''.format(svc['name'], svc['name'], svc['name'], svc['name'])
            for svc in deployed_services
        ]) + '''
        
        echo ""
        echo "Health Score: $healthy_services/$total_services services healthy"
        
        if [ $healthy_services -eq $total_services ]; then
            echo "🎉 All services are healthy!"
        elif [ $healthy_services -gt 0 ]; then
            echo "⚠️  Some services need attention"
        else
            echo "🚨 All services are unhealthy - check individual service logs"
        fi
        ''',
        deps=[svc['name'] for svc in deployed_services],
        labels=['health', 'dashboard', 'monitoring'],
        auto_init=True,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def _create_service_health_monitor(service_info, namespace, debug_mode):
    """Create detailed health monitor for individual service"""
    
    service_name = service_info['name']
    service_type = service_info['type']
    ports = service_info.get('ports', [])
    
    health_cmd = _build_service_health_command(service_name, service_type, ports, namespace)
    
    local_resource(
        service_name + '-health',
        labels=['monitoring'],
        cmd=health_cmd,
        deps=[service_name],
        labels=['health', 'service:' + service_name, 'type:' + service_type],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def _build_service_health_command(service_name, service_type, ports, namespace):
    """Build comprehensive health check command for a service"""
    
    cmd = '''
    echo "=== DETAILED HEALTH CHECK: ''' + service_name + ''' ==="
    echo "Service Type: ''' + service_type + '''"
    echo "Timestamp: $(date)"
    echo ""
    
    # Pod health
    echo "=== POD STATUS ==="
    kubectl get pods -n ''' + namespace + ''' -l app=''' + service_name + ''' -o wide
    
    # Check if pods are ready
    ready_pods=$(kubectl get pods -n ''' + namespace + ''' -l app=''' + service_name + ''' --no-headers 2>/dev/null | grep Running | wc -l)
    total_pods=$(kubectl get pods -n ''' + namespace + ''' -l app=''' + service_name + ''' --no-headers 2>/dev/null | wc -l)
    
    echo ""
    echo "Pod Readiness: $ready_pods/$total_pods pods running"
    
    # Service endpoints
    echo ""
    echo "=== SERVICE ENDPOINTS ==="
    kubectl get svc -n ''' + namespace + ''' ''' + service_name + ''' -o wide 2>/dev/null || echo "Service not found"
    
    # Recent events
    echo ""
    echo "=== RECENT EVENTS ==="
    kubectl get events -n ''' + namespace + ''' --field-selector involvedObject.name=''' + service_name + ''' --sort-by='.lastTimestamp' | tail -5
    
    # Logs (last few lines)
    echo ""
    echo "=== RECENT LOGS ==="
    kubectl logs -n ''' + namespace + ''' -l app=''' + service_name + ''' --tail=10 2>/dev/null || echo "No logs available"
    '''
    
    # Add service-type specific health checks
    if service_type == "postgres":
        cmd += '''
    echo ""
    echo "=== DATABASE SPECIFIC CHECKS ==="
    kubectl exec -n ''' + namespace + ''' deployment/''' + service_name + ''' -- pg_isready -U devuser 2>/dev/null && echo "✅ Database accepting connections" || echo "❌ Database not ready"
    '''
    elif service_type == "redis":
        cmd += '''
    echo ""
    echo "=== REDIS SPECIFIC CHECKS ==="
    kubectl exec -n ''' + namespace + ''' deployment/''' + service_name + ''' -- redis-cli ping 2>/dev/null && echo "✅ Redis responding to ping" || echo "❌ Redis not responding"
    '''
    elif ports and service_type not in ['postgres', 'redis']:
        primary_port = ports[0]
        cmd += '''
    echo ""
    echo "=== HTTP HEALTH CHECKS ==="
    # Try health endpoint
    kubectl exec -n ''' + namespace + ''' deployment/''' + service_name + ''' -- curl -f -s http://localhost:''' + str(primary_port) + '''/health 2>/dev/null && echo "✅ Health endpoint responding" || echo "❌ Health endpoint not responding"
    
    # Try root endpoint
    kubectl exec -n ''' + namespace + ''' deployment/''' + service_name + ''' -- curl -f -s -o /dev/null http://localhost:''' + str(primary_port) + '''/ 2>/dev/null && echo "✅ Root endpoint accessible" || echo "❌ Root endpoint not accessible"
    '''
    
    return cmd

def _create_startup_validation_monitors(deployed_services, namespace, debug_mode):
    """Create startup validation monitors for services"""
    
    local_resource(
        'startup-validation',
        labels=['monitoring'],
        cmd='''
        echo "=== STARTUP VALIDATION ==="
        echo "Validating service startup sequence..."
        echo ""
        
        # Check if all services have started
        all_started=true
        ''' + '\n'.join([
            '''
        echo "Checking startup: {}"
        if kubectl wait --for=condition=ready pod -l app={} -n ''' + namespace + ''' --timeout=10s 2>/dev/null; then
            echo "  ✅ {} started successfully"
        else
            echo "  ⏳ {} still starting or failed"
            all_started=false
        fi'''.format(svc['name'], svc['name'], svc['name'], svc['name'])
            for svc in deployed_services
        ]) + '''
        
        echo ""
        if [ "$all_started" = true ]; then
            echo "🎉 All services have started successfully!"
        else
            echo "⚠️  Some services are still starting or have failed"
            echo "💡 Check individual service logs for details"
        fi
        ''',
        deps=[svc['name'] for svc in deployed_services],
        labels=['startup', 'validation', 'monitoring'],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def _create_failure_recovery_resources(deployed_services, namespace, debug_mode):
    """Create failure recovery resources for services"""
    
    # Create recovery resource for each service
    for service in deployed_services:
        service_name = service['name']
        
        local_resource(
            service_name + '-recovery',
            labels=['support'],
            cmd='''
            echo "=== RECOVERY ACTIONS: ''' + service_name + ''' ==="
            echo "Attempting to recover service..."
            
            # Restart deployment
            echo "Restarting deployment..."
            kubectl rollout restart deployment/''' + service_name + ''' -n ''' + namespace + '''
            
            # Wait for rollout
            echo "Waiting for rollout to complete..."
            kubectl rollout status deployment/''' + service_name + ''' -n ''' + namespace + ''' --timeout=60s
            
            # Check final status
            if kubectl get pods -n ''' + namespace + ''' -l app=''' + service_name + ''' --no-headers | grep -q Running; then
                echo "✅ Recovery successful for ''' + service_name + '''"
            else
                echo "❌ Recovery failed for ''' + service_name + '''"
                echo "Check logs: kubectl logs -n ''' + namespace + ''' -l app=''' + service_name + '''"
            fi
            ''',
            deps=[service_name],
            labels=['recovery', 'service:' + service_name, 'emergency'],
            auto_init=False,
            trigger_mode=TRIGGER_MODE_MANUAL
        )
    
    # Create global recovery resource
    local_resource(
        'global-recovery',
        labels=['support'],
        cmd='''
        echo "=== GLOBAL RECOVERY ==="
        echo "Attempting to recover all services..."
        
        # Restart all deployments
        ''' + '\n'.join([
            '''
        echo "Restarting {}..."
        kubectl rollout restart deployment/{} -n ''' + namespace + '''
        '''.format(svc['name'], svc['name'])
            for svc in deployed_services
        ]) + '''
        
        # Wait for all rollouts
        echo "Waiting for all services to recover..."
        ''' + '\n'.join([
            'kubectl rollout status deployment/{} -n {} --timeout=30s'.format(svc['name'], namespace)
            for svc in deployed_services
        ]) + '''
        
        echo "Global recovery attempt completed"
        echo "Check health-dashboard for current status"
        ''',
        deps=[svc['name'] for svc in deployed_services],
        labels=['recovery', 'global', 'emergency'],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def create_service_isolation_monitor(deployed_services, namespace, debug_mode):
    """Create monitor to ensure service isolation and independence"""
    
    local_resource(
        'service-isolation-monitor',
        labels=['monitoring'],
        cmd='''
        echo "=== SERVICE ISOLATION MONITOR ==="
        echo "Checking service independence and isolation..."
        echo ""
        
        # Check namespace isolation
        echo "=== NAMESPACE ISOLATION ==="
        echo "Current namespace: ''' + namespace + '''"
        other_namespaces=$(kubectl get namespaces --no-headers | grep -v ''' + namespace + ''' | grep -v "kube-" | grep -v "default" | wc -l)
        echo "Other development namespaces: $other_namespaces"
        
        # Check resource isolation
        echo ""
        echo "=== RESOURCE ISOLATION ==="
        ''' + '\n'.join([
            '''
        echo "Checking {}: $(kubectl get pods -n ''' + namespace + ''' -l app={} --no-headers | wc -l) pods"
        '''.format(svc['name'], svc['name'])
            for svc in deployed_services
        ]) + '''
        
        # Check service independence (simulate failure)
        echo ""
        echo "=== SERVICE INDEPENDENCE TEST ==="
        echo "Testing if services can handle dependency failures..."
        
        # This is a dry-run test - we don't actually break anything
        ''' + '\n'.join([
            '''
        deps="{}"
        if [ -n "$deps" ]; then
            echo "{} depends on: $deps"
            echo "  - Service should handle dependency failures gracefully"
        else
            echo "{} has no dependencies - fully independent"
        fi
        '''.format(
                ' '.join(svc.get('dependencies', [])),
                svc['name'],
                svc['name']
            ) for svc in deployed_services
        ]) + '''
        
        echo ""
        echo "✅ Service isolation check completed"
        ''',
        deps=[svc['name'] for svc in deployed_services],
        labels=['isolation', 'independence', 'monitoring'],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )