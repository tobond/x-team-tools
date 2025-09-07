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

# Helper function to get available environments (needed early for usage)
get_available_environments() {
    local env_file=".tilt/environments.yaml"
    
    if [ ! -f "$env_file" ]; then
        echo "  No environments configured"
        return
    fi
    
    # Extract environment names
    if command -v yq >/dev/null 2>&1; then
        yq eval '.environments | keys | .[]' "$env_file" | sed 's/^/  /'
    else
        # Fallback: grep-based extraction
        grep "^  [a-zA-Z]" "$env_file" | grep ":" | sed 's/://g' | sed 's/^/  /'
    fi
}

# Parse arguments
ENVIRONMENT=""
DRY_RUN=false
DEVELOPER_ID=$(whoami)

show_usage() {
    echo "Usage: $0 <environment> [options]"
    echo ""
    echo "User-defined environments (configure in .tilt/environments.yaml):"
    get_available_environments
    echo ""
    echo "Options:"
    echo "  --dry-run        Show what would be started without starting"
    echo "  --developer-id   Override developer ID (default: $(whoami))"
    echo ""
    echo "Examples:"
    echo "  $0 minimal"
    echo "  $0 my-custom-env --dry-run"  
    echo "  $0 integration-test --developer-id=john.doe"
    echo ""
    echo "Note: Define your environments in .tilt/environments.yaml"
    echo "      You can create any environment name with any service combination"
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

# Read environment configurations from user-defined file
get_services_for_environment() {
    local env="$1"
    local env_file=".tilt/environments.yaml"
    
    if [ ! -f "$env_file" ]; then
        log_error "Environment configuration file not found: $env_file"
        echo ""
        echo "Create $env_file to define your custom environments."
        echo "See documentation for format and examples."
        exit 1
    fi
    
    # Extract services for the specified environment using yq or Python fallback
    if command -v yq >/dev/null 2>&1; then
        services=$(yq eval ".environments.$env.services[]" "$env_file" 2>/dev/null | tr '\n' ' ')
    else
        # Fallback: simple grep-based extraction (assumes simple YAML structure)
        services=$(awk -v env="$env" '
        /^  [a-zA-Z]/ && $1 == env":" { in_env = 1; next }
        in_env && /^  [a-zA-Z]/ && $1 != env":" { in_env = 0 }
        in_env && /services:/ { 
            getline
            while ($0 ~ /^      - /) {
                gsub(/^      - /, "")
                gsub(/"/, "")
                printf "%s ", $0
                getline
            }
        }
        ' "$env_file")
    fi
    
    if [ -z "$services" ]; then
        log_error "Environment '$env' not found or has no services defined"
        echo ""
        echo "Available environments:"
        get_available_environments
        exit 1
    fi
    
    echo "$services"
}

get_build_strategy_for_environment() {
    local env="$1"
    local env_file=".tilt/environments.yaml"
    
    if [ ! -f "$env_file" ]; then
        echo "mixed"  # Default fallback
        return
    fi
    
    # Extract build strategy for the specified environment
    if command -v yq >/dev/null 2>&1; then
        build_strategy=$(yq eval ".environments.$env.build_strategy" "$env_file" 2>/dev/null)
        if [ "$build_strategy" = "null" ] || [ -z "$build_strategy" ]; then
            # Try global default
            build_strategy=$(yq eval ".global.default_build_strategy" "$env_file" 2>/dev/null)
        fi
    else
        # Fallback: awk-based extraction
        build_strategy=$(awk -v env="$env" '
        /^  [a-zA-Z]/ && $1 == env":" { in_env = 1; next }
        in_env && /^  [a-zA-Z]/ && $1 != env":" { in_env = 0 }
        in_env && /build_strategy:/ { 
            gsub(/.*build_strategy: *"/, "")
            gsub(/".*/, "")
            print $0
        }
        ' "$env_file")
    fi
    
    # Default to mixed if not found
    if [ -z "$build_strategy" ] || [ "$build_strategy" = "null" ]; then
        build_strategy="mixed"
    fi
    
    echo "$build_strategy"
}

get_description_for_environment() {
    local env="$1"
    local env_file=".tilt/environments.yaml"
    
    if [ ! -f "$env_file" ]; then
        echo "Custom environment"
        return
    fi
    
    # Extract description for the specified environment
    if command -v yq >/dev/null 2>&1; then
        description=$(yq eval ".environments.$env.description" "$env_file" 2>/dev/null)
    else
        # Fallback: awk-based extraction
        description=$(awk -v env="$env" '
        /^  [a-zA-Z]/ && $1 == env":" { in_env = 1; next }
        in_env && /^  [a-zA-Z]/ && $1 != env":" { in_env = 0 }
        in_env && /description:/ { 
            gsub(/.*description: *"/, "")
            gsub(/".*/, "")
            print $0
        }
        ' "$env_file")
    fi
    
    # Default if not found
    if [ -z "$description" ] || [ "$description" = "null" ]; then
        description="User-defined environment"
    fi
    
    echo "$description"
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