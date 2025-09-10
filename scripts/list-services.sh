#!/bin/bash

# Service Discovery Script for x-team-tools
# Lists all available services, their status, and key information

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Tiltfile" ] || [ ! -d ".tilt" ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run from the x-team-tools root directory"
    exit 1
fi

# Load plugin bridge for enhanced service information
source "$(dirname "$0")/lib/plugin-bridge.sh"

echo -e "${CYAN}📦 X-TEAM-TOOLS SERVICE CATALOG${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Show plugin framework status
check_plugin_framework_status
echo ""

# Show available service plugins
list_service_plugins
echo ""

# Parse services from configuration
if [ ! -f ".tilt/service-config.yaml" ]; then
    echo -e "${RED}[ERROR]${NC} Service configuration file not found: .tilt/service-config.yaml"
    exit 1
fi

# Function to extract service information
get_service_info() {
    local service_name="$1"
    local config_file=".tilt/service-config.yaml"
    
    # Extract service block using awk
    awk -v service="$service_name" '
    /^  [a-zA-Z]/ && $1 == service":" {
        in_service = 1
        print $0
        next
    }
    in_service && /^  [a-zA-Z]/ && $1 != service":" {
        in_service = 0
    }
    in_service && /^    / {
        print $0
    }
    ' "$config_file"
}

# Function to check if service directory exists
check_service_status() {
    local service_name="$1"
    
    if [ -d "services/$service_name" ]; then
        if [ -f "services/$service_name/Dockerfile" ]; then
            echo -e "${GREEN}✅ Ready${NC}"
        else
            echo -e "${YELLOW}⚠️  No Dockerfile${NC}"
        fi
    else
        echo -e "${RED}❌ Missing${NC}"
    fi
}

# Function to get service type
get_service_type() {
    local service_name="$1"
    grep -A 10 "^  $service_name:" .tilt/service-config.yaml | grep "type:" | head -1 | sed 's/.*type: *"\([^"]*\)".*/\1/'
}

# Function to get service ports
get_service_ports() {
    local service_name="$1"
    grep -A 10 "^  $service_name:" .tilt/service-config.yaml | grep "ports:" | head -1 | sed 's/.*ports: *\[\([^]]*\)\].*/\1/'
}

# Function to check if service is currently running in Kubernetes
check_k8s_status() {
    local service_name="$1"
    
    if command -v kubectl >/dev/null 2>&1; then
        local pod_status=$(kubectl get pods -l app="$service_name" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
        local pod_count=$(kubectl get pods -l app="$service_name" --no-headers 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$pod_count" -gt 0 ] && [ "$pod_status" = "Running" ]; then
            echo -e "${GREEN}🟢 Running${NC}"
        elif [ "$pod_count" -gt 0 ]; then
            echo -e "${YELLOW}🟡 Starting${NC}"
        else
            echo -e "${RED}🔴 Not Running${NC}"
        fi
    else
        echo -e "${BLUE}➖ kubectl N/A${NC}"
    fi
}

# Get list of all services
services=$(grep -E "^  [a-zA-Z][a-zA-Z0-9-]*:" .tilt/service-config.yaml | sed 's/://g' | sed 's/^  //' | grep -v "^global$")

if [ -z "$services" ]; then
    echo -e "${YELLOW}No services found in configuration.${NC}"
    exit 0
fi

# Header
printf "%-20s %-10s %-8s %-15s %-15s %s\n" "SERVICE" "TYPE" "PORTS" "LOCAL STATUS" "K8S STATUS" "LOCATION"
echo -e "${BLUE}$(printf '%.80s' "────────────────────────────────────────────────────────────────────────────────")${NC}"

# List each service
for service in $services; do
    type=$(get_service_type "$service")
    ports=$(get_service_ports "$service")
    local_status=$(check_service_status "$service")
    k8s_status=$(check_k8s_status "$service")
    
    # Determine location
    if [ -d "services/$service" ]; then
        if [ -L "services/$service" ]; then
            location="${CYAN}📎 Symlink${NC}"
        elif [ -d "services/$service/.git" ]; then
            location="${MAGENTA}📁 Git Repo${NC}"
        else
            location="${BLUE}📂 Local Copy${NC}"
        fi
    else
        location="${RED}❓ Unknown${NC}"
    fi
    
    printf "%-30s %-10s %-8s %-25s %-25s %s\n" "$service" "$type" "$ports" "$local_status" "$k8s_status" "$location"
done

echo ""
echo -e "${CYAN}QUICK ACTIONS:${NC}"
echo -e "${BLUE}  Import service:${NC} ./scripts/import-service.sh <repository>"
echo -e "${BLUE}  Service info:${NC}   ./scripts/service-info.sh <service-name>"  
echo -e "${BLUE}  Start services:${NC} tilt up <service-names> -- --developer_id=\$(whoami)"
echo -e "${BLUE}  Stop services:${NC}  tilt down"

echo ""
echo -e "${CYAN}EXAMPLES:${NC}"
echo -e "  ./scripts/import-service.sh github:company/user-service"
echo -e "  ./scripts/service-info.sh ai-agentic-test-app"
echo -e "  tilt up ai-agentic-test-app database -- --developer_id=\$(whoami)"