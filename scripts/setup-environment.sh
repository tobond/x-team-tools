#!/bin/bash

# Environment Setup Script for x-team-tools
# Sets up predefined development environments with specific service combinations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "Tiltfile" ] || [ ! -d ".tilt" ]; then
    log_error "This script must be run from the x-team-tools root directory"
    exit 1
fi

# Parse arguments
ENVIRONMENT=""
DRY_RUN=false
DEVELOPER_ID=$(whoami)

show_usage() {
    echo "Usage: $0 <environment> [options]"
    echo ""
    echo "Predefined environments:"
    echo "  full-stack       # All services (frontend + backend + data)"
    echo "  backend-only     # API services + databases"
    echo "  minimal          # Core services only"
    echo "  staging-mirror   # Mirror staging environment locally"
    echo "  feature-branch   # Lightweight environment for feature work"
    echo ""
    echo "Options:"
    echo "  --dry-run        Show what would be started without starting"
    echo "  --developer-id   Override developer ID (default: $(whoami))"
    echo ""
    echo "Examples:"
    echo "  $0 backend-only"
    echo "  $0 full-stack --dry-run"
    echo "  $0 staging-mirror --developer-id=john.doe"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --developer-id)
            DEVELOPER_ID="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$ENVIRONMENT" ]; then
                ENVIRONMENT="$1"
            else
                log_error "Unknown option: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$ENVIRONMENT" ]; then
    log_error "Missing required argument: environment"
    show_usage
    exit 1
fi

# Define environment configurations
get_services_for_environment() {
    local env="$1"
    
    case "$env" in
        "full-stack")
            echo "ai-agentic-test-app database redis"
            ;;
        "backend-only")
            echo "ai-agentic-test-app database redis"
            ;;
        "minimal")
            echo "ai-agentic-test-app"
            ;;
        "staging-mirror")
            echo "ai-agentic-test-app database redis"
            ;;
        "feature-branch")
            echo "ai-agentic-test-app redis"
            ;;
        *)
            log_error "Unknown environment: $env"
            echo ""
            echo "Available environments:"
            echo "  full-stack, backend-only, minimal, staging-mirror, feature-branch"
            exit 1
            ;;
    esac
}

get_build_strategy_for_environment() {
    local env="$1"
    
    case "$env" in
        "staging-mirror")
            echo "ecr"  # Use production-like images
            ;;
        "feature-branch"|"minimal")
            echo "local"  # Fast local development
            ;;
        *)
            echo "mixed"  # Default: ECR for external, local for development services
            ;;
    esac
}

get_description_for_environment() {
    local env="$1"
    
    case "$env" in
        "full-stack")
            echo "Complete environment with all frontend, backend, and data services"
            ;;
        "backend-only")
            echo "Backend APIs and databases without frontend components"
            ;;
        "minimal")
            echo "Essential services only for lightweight development"
            ;;
        "staging-mirror")
            echo "Local replica of staging environment using production-like images"
            ;;
        "feature-branch")
            echo "Lightweight setup optimized for feature development"
            ;;
        *)
            echo "Custom environment"
            ;;
    esac
}

# Get configuration for selected environment
SERVICES=$(get_services_for_environment "$ENVIRONMENT")
BUILD_STRATEGY=$(get_build_strategy_for_environment "$ENVIRONMENT")
DESCRIPTION=$(get_description_for_environment "$ENVIRONMENT")

# Check if all required services are available
log_step "Validating environment requirements..."
available_services=$(grep -E "^  [a-zA-Z][a-zA-Z0-9-]*:" .tilt/service-config.yaml | sed 's/://g' | sed 's/^  //' | grep -v "^global$")

for service in $SERVICES; do
    if ! echo "$available_services" | grep -q "^$service$"; then
        log_error "Required service not found in configuration: $service"
        echo ""
        echo "Available services:"
        echo "$available_services" | sed 's/^/  - /'
        echo ""
        echo "To add missing services:"
        echo "  ./scripts/import-service.sh <repository> --name $service"
        exit 1
    fi
done

log_success "All required services are available"

# Show environment plan
echo ""
echo -e "${CYAN}🚀 ENVIRONMENT SETUP PLAN${NC}"
echo -e "${CYAN}══════════════════════════${NC}"
echo "Environment: $ENVIRONMENT"
echo "Description: $DESCRIPTION"
echo "Developer ID: $DEVELOPER_ID"
echo "Build Strategy: $BUILD_STRATEGY"
echo "Services to start:"
for service in $SERVICES; do
    echo "  - $service"
done
echo ""

# Prepare Tilt command
TILT_CMD="tilt up $SERVICES -- --developer_id=$DEVELOPER_ID"

# Add build strategy flags
case "$BUILD_STRATEGY" in
    "local")
        TILT_CMD="$TILT_CMD --build_local=$(echo $SERVICES | tr ' ' ',')"
        ;;
    "ecr")
        # Use ECR images (default behavior)
        ;;
    "mixed")
        # Build main development services locally, use ECR for external services
        dev_services=""
        for service in $SERVICES; do
            service_type=$(grep -A 10 "^  $service:" .tilt/service-config.yaml | grep "type:" | head -1 | sed 's/.*type: *"\([^"]*\)".*/\1/')
            if [ "$service_type" != "external" ]; then
                dev_services="$dev_services $service"
            fi
        done
        if [ -n "$dev_services" ]; then
            TILT_CMD="$TILT_CMD --build_local=$(echo $dev_services | tr ' ' ',' | sed 's/^,//')"
        fi
        ;;
esac

# Execute or show dry run
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN]${NC} Would execute:"
    echo "  $TILT_CMD"
    echo ""
    echo -e "${BLUE}Environment Status Check:${NC}"
    for service in $SERVICES; do
        if kubectl get pods -l app="$service" >/dev/null 2>&1; then
            echo -e "  $service: ${GREEN}Already running${NC}"
        else
            echo -e "  $service: ${YELLOW}Would be started${NC}"
        fi
    done
else
    log_step "Starting environment: $ENVIRONMENT"
    echo "Executing: $TILT_CMD"
    echo ""
    
    # Check if Tilt is already running
    if curl -s http://localhost:10350 >/dev/null 2>&1; then
        log_warning "Tilt is already running. This will modify the current environment."
        echo "Press Enter to continue or Ctrl+C to abort..."
        read -r
    fi
    
    # Execute the command
    eval "$TILT_CMD"
fi

echo ""
log_info "Environment setup completed!"
echo ""
echo -e "${CYAN}⚡ QUICK ACTIONS:${NC}"
echo -e "${BLUE}  View status:${NC}      ./scripts/list-services.sh"
echo -e "${BLUE}  Tilt UI:${NC}          http://localhost:10350"
echo -e "${BLUE}  Stop environment:${NC} tilt down"