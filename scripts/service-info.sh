#!/bin/bash

# Service Information Script for x-team-tools
# Shows detailed information about a specific service

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

# Parse arguments
SERVICE_NAME="$1"

show_usage() {
    echo "Usage: $0 <service-name>"
    echo ""
    echo "Shows detailed information about a service including:"
    echo "  - Configuration details"
    echo "  - File structure"
    echo "  - Dependencies"
    echo "  - Runtime status"
    echo ""
    echo "Example:"
    echo "  $0 ai-agentic-test-app"
}

if [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}[ERROR]${NC} Missing required argument: service-name"
    show_usage
    exit 1
fi

# Check if service exists in configuration
if ! grep -q "^  $SERVICE_NAME:" .tilt/service-config.yaml 2>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Service '$SERVICE_NAME' not found in configuration"
    echo ""
    echo -e "${BLUE}Available services:${NC}"
    grep -E "^  [a-zA-Z][a-zA-Z0-9-]*:" .tilt/service-config.yaml | sed 's/://g' | sed 's/^  /  - /' | grep -v "^  - global$"
    exit 1
fi

echo -e "${CYAN}📋 SERVICE INFORMATION: $SERVICE_NAME${NC}"
echo -e "${CYAN}$(printf '%.50s' '══════════════════════════════════════════════════')${NC}"
echo ""

# Extract service configuration
get_config_value() {
    local key="$1"
    grep -A 20 "^  $SERVICE_NAME:" .tilt/service-config.yaml | grep "$key:" | head -1 | sed "s/.*$key: *[\"']*\([^\"']*\)[\"']*.*/\1/"
}

get_config_array() {
    local key="$1"
    grep -A 20 "^  $SERVICE_NAME:" .tilt/service-config.yaml | grep "$key:" | head -1 | sed 's/.*\[\([^]]*\)\].*/\1/'
}

# Basic configuration
service_type=$(get_config_value "type")
build_context=$(get_config_value "build_context")
dockerfile=$(get_config_value "dockerfile")
ports=$(get_config_array "ports")
dependencies=$(get_config_array "dependencies")

echo -e "${BLUE}📝 CONFIGURATION${NC}"
echo "  Type: $service_type"
echo "  Ports: [$ports]"
echo "  Build Context: $build_context"
echo "  Dockerfile: $dockerfile"
[ -n "$dependencies" ] && echo "  Dependencies: [$dependencies]"
echo ""

# Directory status
echo -e "${BLUE}📁 DIRECTORY STATUS${NC}"
SERVICE_DIR="services/$SERVICE_NAME"
if [ -d "$SERVICE_DIR" ]; then
    echo -e "  Location: ${GREEN}✅ $SERVICE_DIR${NC}"
    
    # Check if it's a symlink, git repo, or regular directory
    if [ -L "$SERVICE_DIR" ]; then
        echo -e "  Type: ${CYAN}🔗 Symbolic link${NC}"
        echo "  Target: $(readlink "$SERVICE_DIR")"
    elif [ -d "$SERVICE_DIR/.git" ]; then
        echo -e "  Type: ${MAGENTA}📦 Git repository${NC}"
        if command -v git >/dev/null 2>&1; then
            cd "$SERVICE_DIR"
            echo "  Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
            echo "  Remote: $(git config --get remote.origin.url 2>/dev/null || echo 'none')"
            echo "  Commits: $(git rev-list --count HEAD 2>/dev/null || echo 'unknown')"
            cd - >/dev/null
        fi
    else
        echo -e "  Type: ${BLUE}📂 Local directory${NC}"
    fi
    
    # File structure
    echo ""
    echo -e "${BLUE}🗂️  FILE STRUCTURE${NC}"
    if command -v tree >/dev/null 2>&1; then
        tree "$SERVICE_DIR" -L 2 -a -I '.git' | head -15
    else
        find "$SERVICE_DIR" -maxdepth 2 -type f | head -10 | sort | sed 's/^/  /'
        file_count=$(find "$SERVICE_DIR" -type f | wc -l | tr -d ' ')
        [ "$file_count" -gt 10 ] && echo "  ... and $(($file_count - 10)) more files"
    fi
else
    echo -e "  Location: ${RED}❌ Directory not found: $SERVICE_DIR${NC}"
fi
echo ""

# Dockerfile analysis
echo -e "${BLUE}🐳 DOCKERFILE ANALYSIS${NC}"
if [ -f "$SERVICE_DIR/Dockerfile" ]; then
    echo -e "  Status: ${GREEN}✅ Found${NC}"
    
    # Extract key information from Dockerfile
    if grep -q "^FROM" "$SERVICE_DIR/Dockerfile"; then
        base_image=$(grep "^FROM" "$SERVICE_DIR/Dockerfile" | head -1 | awk '{print $2}')
        echo "  Base Image: $base_image"
    fi
    
    if grep -q "^EXPOSE" "$SERVICE_DIR/Dockerfile"; then
        exposed_ports=$(grep "^EXPOSE" "$SERVICE_DIR/Dockerfile" | awk '{print $2}' | tr '\n' ' ')
        echo "  Exposed Ports: $exposed_ports"
    fi
    
    if grep -q "^HEALTHCHECK" "$SERVICE_DIR/Dockerfile"; then
        echo -e "  Health Check: ${GREEN}✅ Configured${NC}"
    else
        echo -e "  Health Check: ${YELLOW}⚠️  Not configured${NC}"
    fi
else
    echo -e "  Status: ${RED}❌ Not found${NC}"
    echo -e "  ${YELLOW}Note: Service may use external image or need Dockerfile creation${NC}"
fi
echo ""

# Kubernetes status
echo -e "${BLUE}☸️  KUBERNETES STATUS${NC}"
if command -v kubectl >/dev/null 2>&1; then
    # Check if service is deployed
    pod_count=$(kubectl get pods -l app="$SERVICE_NAME" --no-headers 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$pod_count" -gt 0 ]; then
        echo -e "  Deployment: ${GREEN}✅ Active${NC}"
        
        # Pod information
        kubectl get pods -l app="$SERVICE_NAME" -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp" --no-headers 2>/dev/null | while read line; do
            echo "  Pod: $line"
        done
        
        # Service information
        if kubectl get service "$SERVICE_NAME" >/dev/null 2>&1; then
            service_ip=$(kubectl get service "$SERVICE_NAME" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
            service_ports=$(kubectl get service "$SERVICE_NAME" -o jsonpath='{.spec.ports[*].port}' 2>/dev/null)
            echo "  Service IP: $service_ip"
            echo "  Service Ports: $service_ports"
        fi
    else
        echo -e "  Deployment: ${RED}❌ Not deployed${NC}"
    fi
else
    echo -e "  Status: ${YELLOW}⚠️  kubectl not available${NC}"
fi
echo ""

# Environment variables
echo -e "${BLUE}🔧 ENVIRONMENT VARIABLES${NC}"
grep -A 20 "^  $SERVICE_NAME:" .tilt/service-config.yaml | grep -A 10 "env_vars:" | grep -E "name:|value:" | paste - - | sed 's/.*name: *[\"'"'"']*\([^\"'"'"']*\).*/\1/' | while IFS=$'\t' read name_line value_line; do
    env_name=$(echo "$name_line" | sed 's/.*name: *[\"'"'"']*\([^\"'"'"']*\).*/\1/')
    env_value=$(echo "$value_line" | sed 's/.*value: *[\"'"'"']*\([^\"'"'"']*\).*/\1/')
    echo "  $env_name=$env_value"
done
echo ""

# Quick actions
echo -e "${CYAN}⚡ QUICK ACTIONS${NC}"
echo -e "${BLUE}  Start service:${NC} tilt up $SERVICE_NAME -- --developer_id=\$(whoami)"
echo -e "${BLUE}  View logs:${NC}     kubectl logs -f deployment/$SERVICE_NAME"
echo -e "${BLUE}  Port forward:${NC}  kubectl port-forward service/$SERVICE_NAME 8080:$ports"
[ -d "$SERVICE_DIR" ] && echo -e "${BLUE}  Open directory:${NC} cd $SERVICE_DIR"