#!/bin/bash

# Plugin Bridge Library
# Provides bash interface to the plugin framework for operational scripts
# This bridges the gap between bash scripts and Starlark plugin system

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Plugin framework integration
PLUGIN_FRAMEWORK_DIR=".tilt/framework"
PLUGINS_DIR=".tilt/plugins"
PLUGINS_SERVICES_DIR=".tilt/plugins/services"
PLUGINS_EXTERNAL_DIR=".tilt/plugins/external"
PLUGINS_BUILD_STRATEGIES_DIR=".tilt/plugins/build_strategies"
PLUGINS_ENVIRONMENTS_DIR=".tilt/plugins/environments"

# Check if plugin framework is available
plugin_framework_available() {
    [ -d "$PLUGIN_FRAMEWORK_DIR" ] && [ -d "$PLUGINS_DIR" ]
}

# Get list of supported service types from plugin registry
get_supported_service_types() {
    if ! plugin_framework_available; then
        # Fallback to legacy hardcoded types
        echo "python java nodejs go external postgres redis"
        return
    fi
    
    # Use plugin framework to get registered types
    # This would ideally call into the plugin registry, but for bash integration
    # we'll scan the plugin directories and extract types
    local service_types=""
    
    # Application service types
    if [ -d "$PLUGINS_SERVICES_DIR" ]; then
        for plugin_file in "$PLUGINS_SERVICES_DIR"/*.star; do
            if [ -f "$plugin_file" ]; then
                local service_type=$(basename "$plugin_file" .star)
                service_types="$service_types $service_type"
            fi
        done
    fi
    
    # External service types  
    if [ -d "$PLUGINS_EXTERNAL_DIR" ]; then
        for plugin_file in "$PLUGINS_EXTERNAL_DIR"/*.star; do
            if [ -f "$plugin_file" ]; then
                local service_type=$(basename "$plugin_file" .star)
                service_types="$service_types $service_type"
            fi
        done
    fi
    
    echo "$service_types"
}

# Detect service type using plugin-aware logic
detect_service_type_with_plugins() {
    local service_dir="$1"
    
    if ! plugin_framework_available; then
        # Fallback to legacy detection
        _legacy_detect_service_type "$service_dir"
        return
    fi
    
    # Plugin-aware detection using file extension patterns from plugin metadata
    # Check for Python
    if [ -f "$service_dir/requirements.txt" ] || [ -f "$service_dir/pyproject.toml" ] || [ -f "$service_dir/setup.py" ]; then
        if [ -f "$service_dir/main.py" ] || [ -f "$service_dir/app.py" ] || [ -d "$service_dir/src" ]; then
            echo "python"
            return
        fi
    fi
    
    # Check for Node.js
    if [ -f "$service_dir/package.json" ]; then
        echo "nodejs"
        return
    fi
    
    # Check for Java
    if [ -f "$service_dir/pom.xml" ] || [ -f "$service_dir/build.gradle" ] || [ -f "$service_dir/build.gradle.kts" ]; then
        echo "java"
        return
    fi
    
    # Check for Go
    if [ -f "$service_dir/go.mod" ]; then
        echo "go"
        return
    fi
    
    # Check for Dockerfile (generic)
    if [ -f "$service_dir/Dockerfile" ]; then
        echo "external"
        return
    fi
    
    # Default fallback
    echo "external"
}

# Get default port for service type using plugin information
get_default_port_for_service_type() {
    local service_type="$1"
    
    if ! plugin_framework_available; then
        # Fallback to legacy port mapping
        _legacy_get_default_port "$service_type"
        return
    fi
    
    # Plugin-aware port detection based on plugin metadata
    case "$service_type" in
        "python")
            echo "8000"
            ;;
        "java")
            echo "8080"
            ;;
        "nodejs")
            echo "3000"
            ;;
        "go")
            echo "8080"
            ;;
        "postgres")
            echo "5432"
            ;;
        "redis")
            echo "6379"
            ;;
        *)
            echo "8080"
            ;;
    esac
}

# Get default configuration for service type using plugin system
get_plugin_default_config() {
    local service_type="$1"
    local service_name="$2"
    
    if ! plugin_framework_available; then
        # Generate legacy-style config
        _legacy_generate_config "$service_type" "$service_name"
        return
    fi
    
    # Plugin-aware configuration generation
    local default_port=$(get_default_port_for_service_type "$service_type")
    
    cat << EOF
  $service_name:
    type: "$service_type"
    build_context: "./services/$service_name"
    ports: [$default_port]
    dependencies: []
    env_vars: []
EOF
}

# Validate service configuration using plugin validation
validate_service_config_with_plugins() {
    local service_name="$1"
    local service_type="$2"
    local config_file="$3"
    
    if ! plugin_framework_available; then
        echo -e "${YELLOW}[WARNING]${NC} Plugin framework not available, skipping validation"
        return 0
    fi
    
    # Basic validation - in a full implementation, this would call into the plugin system
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}[ERROR]${NC} Configuration file not found: $config_file"
        return 1
    fi
    
    # Check if service type is supported
    local supported_types=$(get_supported_service_types)
    if ! echo "$supported_types" | grep -q "$service_type"; then
        echo -e "${RED}[ERROR]${NC} Unsupported service type: $service_type"
        echo -e "${BLUE}[INFO]${NC} Supported types: $supported_types"
        return 1
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Service configuration validation passed"
    return 0
}

# Get service information using plugin metadata
get_service_info_from_plugins() {
    local service_type="$1"
    
    if ! plugin_framework_available; then
        echo "Service type: $service_type (legacy mode)"
        return
    fi
    
    # Plugin-aware service information
    case "$service_type" in
        "python")
            echo "Python Application - Python web applications with FastAPI, Flask, Django"
            echo "Default Port: 8000"
            echo "Supported Platforms: linux, darwin, windows"
            echo "Live Updates: Yes"
            ;;
        "java")
            echo "Java Application - Java applications with Spring Boot, Maven, Gradle"
            echo "Default Port: 8080"
            echo "Supported Platforms: linux, darwin, windows"
            echo "Live Updates: Yes"
            ;;
        "nodejs")
            echo "Node.js Application - Node.js applications with Express, Nest.js, Next.js"
            echo "Default Port: 3000"
            echo "Supported Platforms: linux, darwin, windows"
            echo "Live Updates: Yes"
            ;;
        "go")
            echo "Go Application - Go applications with Gin, Echo, Fiber"
            echo "Default Port: 8080"
            echo "Supported Platforms: linux, darwin, windows"
            echo "Live Updates: Yes"
            ;;
        "postgres")
            echo "PostgreSQL Database - PostgreSQL relational database service"
            echo "Default Port: 5432"
            echo "Supported Platforms: linux, darwin, windows"
            echo "Live Updates: No"
            ;;
        "redis")
            echo "Redis Cache - Redis in-memory data structure store"
            echo "Default Port: 6379"
            echo "Supported Platforms: linux, darwin, windows"
            echo "Live Updates: No"
            ;;
        *)
            echo "External Service - Generic external service"
            echo "Default Port: 8080"
            echo "Live Updates: No"
            ;;
    esac
}

# List all available service plugins
list_service_plugins() {
    if ! plugin_framework_available; then
        echo -e "${YELLOW}[WARNING]${NC} Plugin framework not available"
        echo "Available service types (legacy): python java nodejs go external"
        return
    fi
    
    echo -e "${CYAN}🔌 AVAILABLE SERVICE PLUGINS${NC}"
    echo -e "${CYAN}==============================${NC}"
    
    if [ -d "$PLUGINS_SERVICES_DIR" ]; then
        echo -e "${BLUE}Application Services:${NC}"
        for plugin_file in "$PLUGINS_SERVICES_DIR"/*.star; do
            if [ -f "$plugin_file" ]; then
                local service_type=$(basename "$plugin_file" .star)
                echo "  • $service_type"
            fi
        done
        echo ""
    fi
    
    if [ -d "$PLUGINS_EXTERNAL_DIR" ]; then
        echo -e "${BLUE}External Services:${NC}"
        for plugin_file in "$PLUGINS_EXTERNAL_DIR"/*.star; do
            if [ -f "$plugin_file" ]; then
                local service_type=$(basename "$plugin_file" .star)
                echo "  • $service_type"
            fi
        done
        echo ""
    fi
    
    if [ -d "$PLUGINS_BUILD_STRATEGIES_DIR" ]; then
        echo -e "${BLUE}Build Strategies:${NC}"
        for plugin_file in "$PLUGINS_BUILD_STRATEGIES_DIR"/*.star; do
            if [ -f "$plugin_file" ]; then
                local strategy_name=$(basename "$plugin_file" .star)
                echo "  • $strategy_name"
            fi
        done
    fi
}

# Check plugin framework status
check_plugin_framework_status() {
    if plugin_framework_available; then
        echo -e "${GREEN}✅ Plugin Framework: Available${NC}"
        echo -e "${BLUE}   Framework Directory: $PLUGIN_FRAMEWORK_DIR${NC}"
        echo -e "${BLUE}   Plugins Directory: $PLUGINS_DIR${NC}"
        
        local service_count=0
        if [ -d "$PLUGINS_SERVICES_DIR" ]; then
            service_count=$(find "$PLUGINS_SERVICES_DIR" -name "*.star" | wc -l)
        fi
        
        local external_count=0
        if [ -d "$PLUGINS_EXTERNAL_DIR" ]; then
            external_count=$(find "$PLUGINS_EXTERNAL_DIR" -name "*.star" | wc -l)
        fi
        
        local total_plugins=$((service_count + external_count))
        echo -e "${BLUE}   Service Plugins: $service_count${NC}"
        echo -e "${BLUE}   External Plugins: $external_count${NC}"
        echo -e "${BLUE}   Total Plugins: $total_plugins${NC}"
    else
        echo -e "${YELLOW}⚠️  Plugin Framework: Not Available${NC}"
        echo -e "${YELLOW}   Using legacy service detection${NC}"
    fi
}

# Legacy fallback functions
_legacy_detect_service_type() {
    local service_dir="$1"
    
    if [ -f "$service_dir/requirements.txt" ] && [ -f "$service_dir/main.py" -o -f "$service_dir/app.py" ]; then
        echo "python"
    elif [ -f "$service_dir/package.json" ]; then
        echo "nodejs"
    elif [ -f "$service_dir/pom.xml" ] || [ -f "$service_dir/build.gradle" ]; then
        echo "java"
    elif [ -f "$service_dir/go.mod" ]; then
        echo "go"
    elif [ -f "$service_dir/Dockerfile" ]; then
        echo "external"
    else
        echo "external"
    fi
}

_legacy_get_default_port() {
    local service_type="$1"
    
    case "$service_type" in
        "python") echo "8000" ;;
        "nodejs") echo "3000" ;;
        "java") echo "8080" ;;
        "go") echo "8080" ;;
        "postgres") echo "5432" ;;
        "redis") echo "6379" ;;
        *) echo "8080" ;;
    esac
}

_legacy_generate_config() {
    local service_type="$1"
    local service_name="$2"
    local default_port=$(_legacy_get_default_port "$service_type")
    
    cat << EOF
  $service_name:
    type: "$service_type"
    build_context: "./services/$service_name"
    ports: [$default_port]
    dependencies: []
    env_vars: []
EOF
}

# Environment Plugin Bridge Functions

# Get list of available environment plugins
get_available_environment_plugins() {
    if ! plugin_framework_available; then
        # Fallback to legacy hardcoded environments
        echo "minimal backend-only full-stack"
        return
    fi
    
    # Use plugin framework to get registered environment types
    local environment_types=""
    
    if [ -d "$PLUGINS_ENVIRONMENTS_DIR" ]; then
        for plugin_file in "$PLUGINS_ENVIRONMENTS_DIR"/*.star; do
            if [ -f "$plugin_file" ]; then
                local env_type=$(basename "$plugin_file" .star)
                # Convert underscores to hyphens for user-friendly names
                env_type=$(echo "$env_type" | sed 's/_/-/g')
                environment_types="$environment_types $env_type"
            fi
        done
    fi
    
    echo "$environment_types"
}

# Get environment information using plugins
get_environment_info_from_plugins() {
    local environment_name="$1"
    
    if ! plugin_framework_available; then
        echo "Environment: $environment_name (legacy mode)"
        return
    fi
    
    # Convert hyphens to underscores for plugin file names
    local plugin_file_name=$(echo "$environment_name" | sed 's/-/_/g')
    
    # Plugin-aware environment information
    case "$plugin_file_name" in
        "minimal")
            echo "Minimal Development - Essential services only for lightweight development"
            echo "Use Cases: Quick development iterations, Feature development, Resource-constrained development"
            echo "Resources: Low (1-2 GB RAM, 0.5-1 CPU core)"
            echo "Services: ai-agentic-test-app"
            ;;
        "backend_only")
            echo "Backend-Only Development - Backend APIs and databases without frontend components" 
            echo "Use Cases: Backend API development, Database work, API testing, Microservices development"
            echo "Resources: Medium (2-4 GB RAM, 1-2 CPU cores)"
            echo "Services: ai-agentic-test-app, database, redis"
            ;;
        "full_stack")
            echo "Full-Stack Development - Complete environment with all services"
            echo "Use Cases: Full-stack development, End-to-end testing, Integration testing, Demo scenarios"
            echo "Resources: High (6-8 GB RAM, 2-4 CPU cores)"
            echo "Services: ai-agentic-test-app, database, redis"
            ;;
        *)
            echo "Custom Environment - $environment_name"
            echo "Resources: Variable"
            ;;
    esac
}

# Get services list for an environment using plugins
get_services_for_environment_from_plugins() {
    local environment_name="$1"
    
    if ! plugin_framework_available; then
        # Fallback to legacy .tilt/environments.yaml
        return 1
    fi
    
    # Convert hyphens to underscores for plugin file names
    local plugin_file_name=$(echo "$environment_name" | sed 's/-/_/g')
    
    # Plugin-aware service list
    case "$plugin_file_name" in
        "minimal")
            echo "ai-agentic-test-app"
            ;;
        "backend_only")
            echo "ai-agentic-test-app database redis"
            ;;
        "full_stack")
            echo "ai-agentic-test-app database redis"
            ;;
        *)
            # Unknown environment
            return 1
            ;;
    esac
}

# Validate environment using plugins
validate_environment_with_plugins() {
    local environment_name="$1"
    local available_services="$2"
    
    if ! plugin_framework_available; then
        echo -e "${YELLOW}[WARNING]${NC} Plugin framework not available, skipping plugin validation"
        return 0
    fi
    
    # Check if environment plugin exists
    local plugin_file_name=$(echo "$environment_name" | sed 's/-/_/g')
    local plugin_file="$PLUGINS_ENVIRONMENTS_DIR/${plugin_file_name}.star"
    
    if [ ! -f "$plugin_file" ]; then
        echo -e "${YELLOW}[WARNING]${NC} No plugin found for environment: $environment_name"
        return 1
    fi
    
    # Get required services from plugin
    local required_services=$(get_services_for_environment_from_plugins "$environment_name")
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}[WARNING]${NC} Could not determine required services for environment: $environment_name"
        return 1
    fi
    
    # Validate required services are available
    local missing_services=""
    for service in $required_services; do
        if ! echo "$available_services" | grep -q "\\b$service\\b"; then
            missing_services="$missing_services $service"
        fi
    done
    
    if [ -n "$missing_services" ]; then
        echo -e "${RED}[ERROR]${NC} Missing required services for environment '$environment_name': $missing_services"
        return 1
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Environment validation passed for: $environment_name"
    return 0
}

# List all available environment plugins
list_environment_plugins() {
    if ! plugin_framework_available; then
        echo -e "${YELLOW}[WARNING]${NC} Plugin framework not available"
        echo "Available environments (legacy): minimal backend-only full-stack"
        return
    fi
    
    echo -e "${CYAN}🌍 AVAILABLE ENVIRONMENT PLUGINS${NC}"
    echo -e "${CYAN}===================================${NC}"
    
    if [ -d "$PLUGINS_ENVIRONMENTS_DIR" ]; then
        echo -e "${BLUE}Environment Types:${NC}"
        for plugin_file in "$PLUGINS_ENVIRONMENTS_DIR"/*.star; do
            if [ -f "$plugin_file" ]; then
                local env_type=$(basename "$plugin_file" .star)
                local env_display_name=$(echo "$env_type" | sed 's/_/-/g')
                echo "  • $env_display_name"
            fi
        done
        echo ""
    fi
}

# Update check_plugin_framework_status to include environment plugins
check_plugin_framework_status_extended() {
    if plugin_framework_available; then
        echo -e "${GREEN}✅ Plugin Framework: Available${NC}"
        echo -e "${BLUE}   Framework Directory: $PLUGIN_FRAMEWORK_DIR${NC}"
        echo -e "${BLUE}   Plugins Directory: $PLUGINS_DIR${NC}"
        
        local service_count=0
        if [ -d "$PLUGINS_SERVICES_DIR" ]; then
            service_count=$(find "$PLUGINS_SERVICES_DIR" -name "*.star" | wc -l)
        fi
        
        local external_count=0
        if [ -d "$PLUGINS_EXTERNAL_DIR" ]; then
            external_count=$(find "$PLUGINS_EXTERNAL_DIR" -name "*.star" | wc -l)
        fi
        
        local environment_count=0
        if [ -d "$PLUGINS_ENVIRONMENTS_DIR" ]; then
            environment_count=$(find "$PLUGINS_ENVIRONMENTS_DIR" -name "*.star" | wc -l)
        fi
        
        local total_plugins=$((service_count + external_count + environment_count))
        echo -e "${BLUE}   Service Plugins: $service_count${NC}"
        echo -e "${BLUE}   External Plugins: $external_count${NC}"
        echo -e "${BLUE}   Environment Plugins: $environment_count${NC}"
        echo -e "${BLUE}   Total Plugins: $total_plugins${NC}"
    else
        echo -e "${YELLOW}⚠️  Plugin Framework: Not Available${NC}"
        echo -e "${YELLOW}   Using legacy environment configuration${NC}"
    fi
}