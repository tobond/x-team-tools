"""
Service dependency management and ordering
Handles dependency graph creation, topological sorting, and resource dependency configuration
"""

def setup_service_dependencies(services, service_configs, debug_mode=False):
    """Configure comprehensive service startup dependencies with proper ordering and validation"""
    
    # Build dependency graph
    dependency_graph = _build_dependency_graph(services, service_configs, debug_mode)
    
    # Validate dependency graph for circular dependencies
    _validate_dependency_graph(dependency_graph)
    
    # Get deployment order using topological sort
    deployment_order = _topological_sort(dependency_graph)
    
    if debug_mode:
        print("🔄 Service deployment order: " + str(deployment_order))
    
    # Apply resource dependencies to k8s resources
    _apply_resource_dependencies(services, dependency_graph, debug_mode)
    
    # Create comprehensive dependency monitoring
    _create_dependency_monitoring_resources(deployment_order, dependency_graph, services)
    
    # Setup dependency health validation
    _setup_dependency_health_validation(dependency_graph, debug_mode)
    
    return deployment_order

def _build_dependency_graph(services, service_configs, debug_mode):
    """Build dependency graph from service configurations"""
    
    dependency_graph = {}
    all_services = set(services)
    
    for service_name in services:
        if service_name in service_configs['services']:
            service_config = service_configs['services'][service_name]
            deps = service_config.get("dependencies", [])
            
            # Only add dependencies that are also being deployed
            active_deps = [dep for dep in deps if dep in all_services]
            dependency_graph[service_name] = active_deps
            
            if debug_mode and active_deps:
                print("Service {} depends on: {}".format(service_name, active_deps))
    
    return dependency_graph

def _topological_sort(graph):
    """Perform topological sort to determine safe deployment order"""
    
    in_degree = {node: 0 for node in graph}
    
    # Calculate in-degrees
    for node in graph:
        for neighbor in graph[node]:
            if neighbor in in_degree:
                in_degree[neighbor] += 1
    
    # Find nodes with no incoming edges
    queue = [node for node in in_degree if in_degree[node] == 0]
    result = []
    
    while queue:
        node = queue.pop(0)
        result.append(node)
        
        # Remove edges from this node
        for neighbor in graph[node]:
            if neighbor in in_degree:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)
    
    # Check for circular dependencies
    if len(result) != len(graph):
        remaining = [node for node in graph if node not in result]
        fail("Circular dependency detected in services: {}".format(remaining))
    
    return result

def _apply_resource_dependencies(services, dependency_graph, debug_mode):
    """Apply resource dependencies to k8s resources"""
    
    for service_name in services:
        if service_name in dependency_graph and dependency_graph[service_name]:
            # Set resource dependencies
            k8s_resource(
                service_name,
                resource_deps=dependency_graph[service_name]
            )
            
            if debug_mode:
                print("Applied dependencies for {}: {}".format(service_name, dependency_graph[service_name]))

def _validate_dependency_graph(dependency_graph):
    """Validate dependency graph for circular dependencies and missing services"""
    
    # Check for self-dependencies
    for service, deps in dependency_graph.items():
        if service in deps:
            fail("Service '{}' cannot depend on itself".format(service))
    
    # Check for missing dependencies (dependencies not in the deployment list)
    all_services = set(dependency_graph.keys())
    for service, deps in dependency_graph.items():
        missing_deps = [dep for dep in deps if dep not in all_services]
        if missing_deps:
            fail("Service '{}' depends on services not being deployed: {}".format(service, missing_deps))

def _create_dependency_monitoring_resources(deployment_order, dependency_graph, services):
    """Create comprehensive dependency monitoring resources"""
    
    # Main dependency overview
    local_resource(
        'dependency-overview',
        cmd='''
        echo "=== MULTI-SERVICE DEPENDENCY OVERVIEW ==="
        echo "Total Services: ''' + str(len(services)) + '''"
        echo ""
        echo "=== Deployment Order ==="
        ''' + '\n'.join(['echo "  {}. {}"'.format(i+1, svc) for i, svc in enumerate(deployment_order)]) + '''
        echo ""
        echo "=== Dependency Relationships ==="
        ''' + '\n'.join([
            'echo "{} depends on: {}"'.format(svc, ', '.join(deps) if deps else 'No dependencies')
            for svc, deps in dependency_graph.items()
        ]) + '''
        echo ""
        echo "=== Dependency Validation ==="
        echo "✅ No circular dependencies detected"
        echo "✅ All dependencies are being deployed"
        echo "✅ Deployment order calculated successfully"
        ''',
        deps=[],
        labels=['infrastructure', 'dependencies', 'overview'],
        auto_init=True
    )
    
    # Create dependency chain visualization
    _create_dependency_chain_resource(dependency_graph)

def _create_dependency_chain_resource(dependency_graph):
    """Create resource showing dependency chains and levels"""
    
    # Calculate dependency levels
    dependency_levels = _calculate_dependency_levels(dependency_graph)
    
    local_resource(
        'dependency-chains',
        cmd='''
        echo "=== SERVICE DEPENDENCY CHAINS ==="
        ''' + '\n'.join([
            'echo "Level {}: {}"'.format(level, ', '.join(services))
            for level, services in enumerate(dependency_levels)
        ]) + '''
        echo ""
        echo "=== Parallel Deployment Opportunities ==="
        ''' + '\n'.join([
            'echo "  Level {} services can deploy in parallel: {}"'.format(level, len(services))
            for level, services in enumerate(dependency_levels) if len(services) > 1
        ]) + '''
        ''',
        deps=[],
        labels=['infrastructure', 'dependencies', 'chains'],
        auto_init=True
    )

def _calculate_dependency_levels(dependency_graph):
    """Calculate dependency levels for parallel deployment visualization"""
    
    levels = []
    remaining_services = set(dependency_graph.keys())
    resolved_services = set()
    
    while remaining_services:
        current_level = []
        for service in list(remaining_services):
            service_deps = set(dependency_graph[service])
            if service_deps.issubset(resolved_services):
                current_level.append(service)
        
        if not current_level:
            break  # Should not happen if validation passed
        
        levels.append(current_level)
        remaining_services -= set(current_level)
        resolved_services.update(current_level)
    
    return levels

def _setup_dependency_health_validation(dependency_graph, debug_mode):
    """Setup health validation for service dependencies"""
    
    for service, deps in dependency_graph.items():
        if deps:
            _create_service_dependency_health_check(service, deps, debug_mode)

def _create_service_dependency_health_check(service, dependencies, debug_mode):
    """Create health check resource for service dependencies"""
    
    local_resource(
        service + "-dependency-health",
        cmd='''
        echo "=== Dependency Health Check: ''' + service + ''' ==="
        echo "Checking dependencies: ''' + ', '.join(dependencies) + '''"
        
        all_healthy=true
        ''' + '\n'.join([
            '''
        echo "Checking {}..."
        if kubectl get pods -l app={} --no-headers | grep -q Running; then
            echo "  ✅ {} is running"
        else
            echo "  ❌ {} is not ready"
            all_healthy=false
        fi'''.format(dep, dep, dep, dep) for dep in dependencies
        ]) + '''
        
        if [ "$all_healthy" = true ]; then
            echo "✅ All dependencies for ''' + service + ''' are healthy"
        else
            echo "⚠️  Some dependencies for ''' + service + ''' are not ready"
        fi
        ''',
        deps=dependencies,
        labels=['health-check', 'dependencies', 'service:' + service],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )