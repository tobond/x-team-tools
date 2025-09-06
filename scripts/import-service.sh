#!/bin/bash

# Service Import Script for x-team-tools
# Imports existing services from repositories into the local development environment

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
SERVICE_REPO=""
SERVICE_NAME=""
BRANCH="main"
IMPORT_TYPE="clone" # clone, submodule, or reference

show_usage() {
    echo "Usage: $0 <repository> [options]"
    echo ""
    echo "Repository formats:"
    echo "  github:company/service-name    # GitHub repository"
    echo "  git@github.com:company/service-name.git"
    echo "  https://github.com/company/service-name.git"
    echo "  ../existing-service            # Local directory reference"
    echo ""
    echo "Options:"
    echo "  --name <name>        Override service name (default: derived from repo)"
    echo "  --branch <branch>    Git branch to checkout (default: main)"
    echo "  --type <type>        Import type: clone, submodule, reference (default: clone)"
    echo ""
    echo "Examples:"
    echo "  $0 github:mycompany/user-service"
    echo "  $0 git@github.com:mycompany/payment-service.git --branch develop"
    echo "  $0 ../existing-checkout-service --type reference"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            SERVICE_NAME="$2"
            shift 2
            ;;
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --type)
            IMPORT_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$SERVICE_REPO" ]; then
                SERVICE_REPO="$1"
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
if [ -z "$SERVICE_REPO" ]; then
    log_error "Missing required argument: repository"
    show_usage
    exit 1
fi

# Normalize repository format and derive service name
normalize_repo() {
    local repo="$1"
    
    # Handle github:company/repo format
    if [[ "$repo" =~ ^github:(.+)$ ]]; then
        repo="https://github.com/${BASH_REMATCH[1]}.git"
    fi
    
    # Handle git@github.com format
    if [[ "$repo" =~ ^git@github\.com:(.+)\.git$ ]]; then
        repo="https://github.com/${BASH_REMATCH[1]}.git"
    fi
    
    echo "$repo"
}

derive_service_name() {
    local repo="$1"
    
    # Extract service name from various repository formats
    if [[ "$repo" =~ /([^/]+)\.git$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$repo" =~ /([^/]+)/?$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$repo" =~ ^\.\./ ]]; then
        basename "$repo"
    else
        log_error "Cannot derive service name from repository: $repo"
        exit 1
    fi
}

# Normalize repository URL
NORMALIZED_REPO=$(normalize_repo "$SERVICE_REPO")

# Derive service name if not provided
if [ -z "$SERVICE_NAME" ]; then
    SERVICE_NAME=$(derive_service_name "$NORMALIZED_REPO")
fi

# Validate service name format
if [[ ! "$SERVICE_NAME" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
    log_error "Service name must be lowercase, start with a letter, and contain only letters, numbers, and hyphens"
    exit 1
fi

# Check if service already exists
SERVICE_DIR="services/$SERVICE_NAME"
if [ -d "$SERVICE_DIR" ]; then
    log_error "Service directory already exists: $SERVICE_DIR"
    exit 1
fi

# Check if service is already configured
if grep -q "^  $SERVICE_NAME:" .tilt/service-config.yaml 2>/dev/null; then
    log_error "Service '$SERVICE_NAME' is already configured in .tilt/service-config.yaml"
    exit 1
fi

log_info "Importing service: $SERVICE_NAME"
log_info "Repository: $NORMALIZED_REPO"
log_info "Branch: $BRANCH"
log_info "Import type: $IMPORT_TYPE"

# Create services directory if it doesn't exist
mkdir -p services

# Import the service based on type
case $IMPORT_TYPE in
    "clone")
        log_step "Cloning repository..."
        if [[ "$NORMALIZED_REPO" =~ ^\.\./ ]]; then
            # Local directory reference
            if [ ! -d "$NORMALIZED_REPO" ]; then
                log_error "Local directory does not exist: $NORMALIZED_REPO"
                exit 1
            fi
            cp -r "$NORMALIZED_REPO" "$SERVICE_DIR"
            log_info "Copied local directory to $SERVICE_DIR"
        else
            # Git repository
            git clone --branch "$BRANCH" "$NORMALIZED_REPO" "$SERVICE_DIR"
            log_info "Cloned repository to $SERVICE_DIR"
        fi
        ;;
    "submodule")
        log_step "Adding as git submodule..."
        if [[ "$NORMALIZED_REPO" =~ ^\.\./ ]]; then
            log_error "Cannot add local directory as submodule"
            exit 1
        fi
        git submodule add -b "$BRANCH" "$NORMALIZED_REPO" "$SERVICE_DIR"
        log_info "Added repository as git submodule in $SERVICE_DIR"
        ;;
    "reference")
        log_step "Creating reference to existing directory..."
        if [ ! -d "$NORMALIZED_REPO" ]; then
            log_error "Reference directory does not exist: $NORMALIZED_REPO"
            exit 1
        fi
        ln -s "$(realpath "$NORMALIZED_REPO")" "$SERVICE_DIR"
        log_info "Created symbolic link to $NORMALIZED_REPO"
        ;;
    *)
        log_error "Unknown import type: $IMPORT_TYPE"
        exit 1
        ;;
esac

# Auto-detect service configuration
log_step "Auto-detecting service configuration..."

detect_service_type() {
    local service_dir="$1"
    
    if [ -f "$service_dir/requirements.txt" ] && [ -f "$service_dir/main.py" -o -f "$service_dir/app.py" ]; then
        echo "python"
    elif [ -f "$service_dir/package.json" ]; then
        echo "node"
    elif [ -f "$service_dir/pom.xml" ] || [ -f "$service_dir/build.gradle" ]; then
        echo "java"
    elif [ -f "$service_dir/go.mod" ]; then
        echo "go"
    elif [ -f "$service_dir/Dockerfile" ]; then
        echo "docker"
    else
        echo "generic"
    fi
}

detect_ports() {
    local service_dir="$1"
    local detected_ports=""
    
    # Check common configuration files for port declarations
    if [ -f "$service_dir/docker-compose.yml" ]; then
        detected_ports=$(grep -E "^\s*-\s*[\"']?\d+" "$service_dir/docker-compose.yml" | head -1 | grep -oE '\d+' | head -1)
    fi
    
    if [ -z "$detected_ports" ] && [ -f "$service_dir/Dockerfile" ]; then
        detected_ports=$(grep -E "^EXPOSE\s+\d+" "$service_dir/Dockerfile" | head -1 | grep -oE '\d+' | head -1)
    fi
    
    if [ -z "$detected_ports" ] && [ -f "$service_dir/package.json" ]; then
        detected_ports=$(grep -E '"port":\s*\d+' "$service_dir/package.json" | head -1 | grep -oE '\d+' | head -1)
    fi
    
    # Default ports by service type
    if [ -z "$detected_ports" ]; then
        case "$(detect_service_type "$service_dir")" in
            "python") detected_ports="8000" ;;
            "node") detected_ports="3000" ;;
            "java") detected_ports="8080" ;;
            "go") detected_ports="8080" ;;
            *) detected_ports="8080" ;;
        esac
    fi
    
    echo "$detected_ports"
}

# Detect service configuration
SERVICE_TYPE=$(detect_service_type "$SERVICE_DIR")
SERVICE_PORT=$(detect_ports "$SERVICE_DIR")

log_info "Detected service type: $SERVICE_TYPE"
log_info "Detected port: $SERVICE_PORT"

# Generate service configuration
log_step "Adding service to configuration..."

# Determine build configuration based on detected files
BUILD_CONFIG=""
if [ -f "$SERVICE_DIR/Dockerfile" ]; then
    BUILD_CONFIG="    build_context: \"./services/$SERVICE_NAME\"
    dockerfile: \"./services/$SERVICE_NAME/Dockerfile\""
else
    # Service might use external image or need Dockerfile creation
    BUILD_CONFIG="    # NOTE: No Dockerfile found - you may need to:
    # 1. Add a Dockerfile to the service repository, or  
    # 2. Configure an external image:
    # image: \"your-registry/service-name:tag\"
    build_context: \"./services/$SERVICE_NAME\"
    dockerfile: \"./services/$SERVICE_NAME/Dockerfile\""
fi

# Create service configuration
cat >> .tilt/service-config.yaml << EOF

  # $SERVICE_NAME (imported from $SERVICE_REPO)
  $SERVICE_NAME:
    type: "$SERVICE_TYPE"
$BUILD_CONFIG
    dependencies: []  # Add service dependencies here
    ports: [$SERVICE_PORT]
    env_vars:
      - name: "LOG_LEVEL"
        value: "DEBUG"
      - name: "ENVIRONMENT"
        value: "local"
      - name: "PORT"
        value: "$SERVICE_PORT"
    resources:
      cpu: "500m"
      memory: "512Mi"
    health_check:
      path: "/health"
      port: $SERVICE_PORT
EOF

log_success "Service '$SERVICE_NAME' imported successfully!"
echo ""
log_info "Service location: $SERVICE_DIR"
log_info "Configuration added to: .tilt/service-config.yaml"
echo ""
log_info "Next steps:"
echo "  1. Review the service configuration in .tilt/service-config.yaml"
echo "  2. Add any service dependencies if needed"
echo "  3. Create/verify Dockerfile if not present"
echo "  4. Test the service: tilt up $SERVICE_NAME -- --developer_id=\$(whoami)"
echo ""
log_info "Service structure:"
find "$SERVICE_DIR" -maxdepth 2 -type f | head -10 | sort