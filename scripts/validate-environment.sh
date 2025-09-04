#!/bin/bash

# Environment Validation Script
# Validates the development environment setup and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Function to print colored output
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((CHECKS_PASSED++))
}

print_failure() {
    echo -e "${RED}❌ $1${NC}"
    ((CHECKS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((CHECKS_WARNING++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check command availability
check_command() {
    local cmd=$1
    local name=$2
    local required=${3:-true}
    
    if command -v "$cmd" &> /dev/null; then
        local version
        case $cmd in
            docker)
                version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
                ;;
            kubectl)
                version=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo "unknown")
                ;;
            tilt)
                version=$(tilt version 2>/dev/null | head -n1 | cut -d' ' -f2 || echo "unknown")
                ;;
            kind)
                version=$(kind version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
                ;;
            k3d)
                version=$(k3d version 2>/dev/null | grep k3d | cut -d' ' -f3 || echo "unknown")
                ;;
            *)
                version="installed"
                ;;
        esac
        print_success "$name is installed ($version)"
        return 0
    else
        if [ "$required" = "true" ]; then
            print_failure "$name is not installed"
        else
            print_warning "$name is not installed (optional)"
        fi
        return 1
    fi
}

# Function to check file existence
check_file() {
    local file=$1
    local description=$2
    local required=${3:-true}
    
    if [ -f "$file" ]; then
        print_success "$description exists ($file)"
        return 0
    else
        if [ "$required" = "true" ]; then
            print_failure "$description not found ($file)"
        else
            print_warning "$description not found ($file) - optional"
        fi
        return 1
    fi
}

# Function to check directory existence
check_directory() {
    local dir=$1
    local description=$2
    local required=${3:-true}
    
    if [ -d "$dir" ]; then
        print_success "$description exists ($dir)"
        return 0
    else
        if [ "$required" = "true" ]; then
            print_failure "$description not found ($dir)"
        else
            print_warning "$description not found ($dir) - optional"
        fi
        return 1
    fi
}

echo "🔍 Validating Development Environment..."
echo "Timestamp: $(date)"
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"

# Check required tools
print_header "Required Tools"
check_command "docker" "Docker"
check_command "kubectl" "kubectl"
check_command "tilt" "Tilt"

# Check optional tools
print_header "Optional Tools"
check_command "kind" "kind" false
check_command "k3d" "k3d" false
check_command "jq" "jq" false
check_command "yq" "yq" false

# Check Docker status
print_header "Docker Status"
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
        
        # Check Docker resources
        docker_info=$(docker system info 2>/dev/null)
        if echo "$docker_info" | grep -q "CPUs:"; then
            cpus=$(echo "$docker_info" | grep "CPUs:" | awk '{print $2}')
            memory=$(echo "$docker_info" | grep "Total Memory:" | awk '{print $3 $4}')
            print_info "Docker resources: $cpus CPUs, $memory"
        fi
    else
        print_failure "Docker daemon is not running"
    fi
else
    print_failure "Docker is not installed"
fi

# Check Kubernetes connectivity
print_header "Kubernetes Connectivity"
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info &> /dev/null; then
        current_context=$(kubectl config current-context 2>/dev/null || echo "unknown")
        print_success "Kubernetes cluster is accessible (context: $current_context)"
        
        # Check cluster nodes
        if kubectl get nodes &> /dev/null; then
            node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
            print_info "Cluster has $node_count node(s)"
        fi
        
        # Check cluster version
        if kubectl version --short &> /dev/null; then
            server_version=$(kubectl version --short 2>/dev/null | grep "Server Version" | cut -d' ' -f3 || echo "unknown")
            print_info "Kubernetes server version: $server_version"
        fi
    else
        print_failure "Cannot connect to Kubernetes cluster"
        print_info "Try: kubectl cluster-info"
    fi
else
    print_failure "kubectl is not available"
fi

# Check Tilt configuration files
print_header "Tilt Configuration"
check_file "Tiltfile" "Main Tiltfile"
check_file ".tilt/service-config.yaml" "Service configuration"
check_file ".tilt/developer-config.yaml" "Developer configuration" false
check_file ".tilt/developer-config.yaml.template" "Developer configuration template" false

# Validate Tilt configuration
if [ -f "Tiltfile" ]; then
    if command -v tilt &> /dev/null; then
        if tilt validate &> /dev/null; then
            print_success "Tiltfile syntax is valid"
        else
            print_failure "Tiltfile has syntax errors"
            print_info "Run 'tilt validate' for details"
        fi
    fi
fi

# Check service configuration
if [ -f ".tilt/service-config.yaml" ]; then
    if command -v yq &> /dev/null; then
        if yq eval '.services' .tilt/service-config.yaml &> /dev/null; then
            service_count=$(yq eval '.services | keys | length' .tilt/service-config.yaml 2>/dev/null || echo "0")
            print_success "Service configuration is valid ($service_count services defined)"
        else
            print_failure "Service configuration has syntax errors"
        fi
    else
        print_warning "Cannot validate service configuration (yq not installed)"
    fi
fi

# Check developer namespace
print_header "Developer Environment"
if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    developer_id=$(whoami)
    namespace="dev-$developer_id"
    
    if kubectl get namespace "$namespace" &> /dev/null; then
        print_success "Developer namespace exists ($namespace)"
        
        # Check resources in namespace
        pod_count=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | wc -l)
        service_count=$(kubectl get services -n "$namespace" --no-headers 2>/dev/null | wc -l)
        print_info "Namespace resources: $pod_count pods, $service_count services"
    else
        print_warning "Developer namespace does not exist ($namespace)"
        print_info "It will be created when you run 'tilt up'"
    fi
fi

# Check resource availability
print_header "Resource Availability"
if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    # Check node resources
    if kubectl top nodes &> /dev/null; then
        print_success "Node resource metrics are available"
        kubectl top nodes 2>/dev/null | while read -r line; do
            if [[ ! "$line" =~ ^NAME ]]; then
                print_info "Node resources: $line"
            fi
        done
    else
        print_warning "Node resource metrics not available (metrics-server may not be installed)"
    fi
    
    # Check storage classes
    if kubectl get storageclass &> /dev/null; then
        storage_classes=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
        if [ "$storage_classes" -gt 0 ]; then
            print_success "Storage classes available ($storage_classes)"
        else
            print_warning "No storage classes found"
        fi
    fi
fi

# Check project structure
print_header "Project Structure"
check_directory ".tilt" "Tilt configuration directory"
check_directory "scripts" "Scripts directory" false
check_file "README.md" "Project README" false
check_file ".gitignore" "Git ignore file" false

# Check for common issues
print_header "Common Issues Check"

# Check for port conflicts
if command -v lsof &> /dev/null; then
    if lsof -i :10350 &> /dev/null; then
        print_warning "Port 10350 is in use (Tilt UI port)"
        print_info "Run 'lsof -i :10350' to see what's using it"
    else
        print_success "Tilt UI port (10350) is available"
    fi
fi

# Check disk space
if command -v df &> /dev/null; then
    disk_usage=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        print_success "Sufficient disk space available (${disk_usage}% used)"
    elif [ "$disk_usage" -lt 90 ]; then
        print_warning "Disk space getting low (${disk_usage}% used)"
    else
        print_failure "Disk space critically low (${disk_usage}% used)"
    fi
fi

# Check memory
if command -v free &> /dev/null; then
    memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$memory_usage" -lt 80 ]; then
        print_success "Sufficient memory available (${memory_usage}% used)"
    elif [ "$memory_usage" -lt 90 ]; then
        print_warning "Memory usage getting high (${memory_usage}% used)"
    else
        print_failure "Memory usage critically high (${memory_usage}% used)"
    fi
fi

# Summary
print_header "Validation Summary"
echo "✅ Checks passed: $CHECKS_PASSED"
echo "⚠️  Warnings: $CHECKS_WARNING"
echo "❌ Checks failed: $CHECKS_FAILED"

if [ $CHECKS_FAILED -eq 0 ]; then
    if [ $CHECKS_WARNING -eq 0 ]; then
        print_success "Environment validation completed successfully! 🎉"
        echo ""
        echo "You're ready to start development:"
        echo "  tilt up -- --developer_id=$(whoami)"
        echo "  Open http://localhost:10350 for Tilt UI"
    else
        print_warning "Environment validation completed with warnings"
        echo ""
        echo "You can start development, but consider addressing the warnings above"
    fi
    exit 0
else
    print_failure "Environment validation failed"
    echo ""
    echo "Please address the failed checks above before starting development"
    echo "For help, see:"
    echo "  - DEVELOPER_ONBOARDING.md"
    echo "  - TROUBLESHOOTING_GUIDE.md"
    echo "  - Run setup script: ./scripts/setup-$(uname -s | tr '[:upper:]' '[:lower:]').sh"
    exit 1
fi