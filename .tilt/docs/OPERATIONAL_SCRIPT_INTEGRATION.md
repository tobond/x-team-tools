# Operational Script Integration with Plugin Architecture

This document outlines the comprehensive integration of operational scripts with the plugin architecture framework, completed as part of Phase 3 implementation.

## Overview

The operational script integration bridges the gap between bash-based operational tooling and the Starlark-based plugin framework, enabling scripts to leverage plugin metadata and functionality while maintaining backward compatibility.

## Integration Architecture

### Plugin Bridge Interface

**File**: `scripts/lib/plugin-bridge.sh`

The plugin bridge serves as the translation layer between bash scripts and the plugin framework:

```bash
# Load plugin bridge in operational scripts
source "$(dirname "$0")/lib/plugin-bridge.sh"

# Use plugin-aware functions
SERVICE_TYPE=$(detect_service_type_with_plugins "$service_dir")
DEFAULT_PORT=$(get_default_port_for_service_type "$SERVICE_TYPE")
```

### Core Integration Functions

#### 1. Service Type Detection
```bash
# Plugin-aware service detection
detect_service_type_with_plugins() {
    # Uses plugin metadata for accurate detection
    # Falls back to legacy detection if framework unavailable
}
```

#### 2. Default Configuration Generation
```bash
# Plugin-aware default configuration
get_plugin_default_config() {
    # Generates config using plugin defaults
    # Includes service-specific ports, environment variables, health checks
}
```

#### 3. Framework Status Checking
```bash
# Check plugin framework availability
check_plugin_framework_status() {
    # Shows framework status and plugin counts
    # Helps users understand current capability level
}
```

## Updated Operational Scripts

### 1. Service Import Script (`scripts/import-service.sh`)

**Enhancements:**
- ✅ Plugin-aware service type detection
- ✅ Dynamic default port assignment using plugin metadata
- ✅ Configuration generation using plugin defaults
- ✅ Service validation using plugin validation rules
- ✅ Display of plugin-specific service information

**Before Integration:**
```bash
# Hardcoded service detection
case "$(detect_service_type "$service_dir")" in
    "python") detected_ports="8000" ;;
    "node") detected_ports="3000" ;;
    # ... hardcoded for each type
esac
```

**After Integration:**
```bash
# Plugin-aware detection and configuration
SERVICE_TYPE=$(detect_service_type_with_plugins "$SERVICE_DIR")
SERVICE_PORT=$(get_default_port_for_service_type "$SERVICE_TYPE")
get_plugin_default_config "$SERVICE_TYPE" "$SERVICE_NAME"
```

### 2. Service Listing Script (`scripts/list-services.sh`)

**Enhancements:**
- ✅ Display of plugin framework status
- ✅ Listing of available service plugins
- ✅ Plugin capability information
- ✅ Framework availability indicators

**New Features:**
```bash
# Show plugin framework status
check_plugin_framework_status

# List available service plugins
list_service_plugins
```

### 3. Service Information Script (`scripts/service-info.sh`)

**Enhancements:**
- ✅ Plugin metadata integration
- ✅ Service-specific capability information
- ✅ Live update support indicators
- ✅ Platform compatibility information

**New Information Display:**
```bash
# Plugin-specific service information
echo -e "${BLUE}🔌 PLUGIN INFORMATION${NC}"
get_service_info_from_plugins "$service_type"
```

## Plugin Framework Integration Points

### Service Type Support

The integration automatically discovers and supports all implemented service plugins:

| Service Type | Detection Method | Default Port | Live Updates |
|-------------|------------------|--------------|--------------|
| Python | requirements.txt, *.py files | 8000 | Yes |
| Java | pom.xml, build.gradle files | 8080 | Yes |
| Node.js | package.json | 3000 | Yes |
| Go | go.mod files | 8080 | Yes |
| PostgreSQL | External service | 5432 | No |
| Redis | External service | 6379 | No |

### Fallback Behavior

The integration includes comprehensive fallback mechanisms:

1. **Framework Not Available**: Falls back to legacy hardcoded detection
2. **Plugin Not Found**: Uses generic external service handling
3. **Validation Failures**: Provides informative warnings but continues operation

### Configuration Generation

Plugin-aware configuration generation includes:

- **Service-specific defaults** from plugin metadata
- **Appropriate resource limits** based on service type
- **Correct health check endpoints** (e.g., `/actuator/health` for Java)
- **Framework-specific environment variables**

## Benefits of Integration

### 1. Dynamic Service Support
- **Automatic discovery** of new service types through plugins
- **No script modifications** required when adding new service types
- **Consistent behavior** across all operational tools

### 2. Enhanced User Experience
- **Rich service information** displayed during import
- **Plugin capability awareness** in service listings
- **Informed configuration decisions** based on plugin metadata

### 3. Backward Compatibility
- **Graceful degradation** when plugin framework unavailable
- **Legacy service support** through fallback mechanisms
- **No breaking changes** to existing workflows

### 4. Operational Consistency
- **Unified service information** across all scripts
- **Consistent default configurations** based on plugin standards
- **Validation alignment** with plugin framework rules

## Usage Examples

### Service Import with Plugin Integration
```bash
$ ./scripts/import-service.sh github:company/python-api

✅ Plugin Framework: Available
   Framework Directory: .tilt/framework
   Plugins Directory: .tilt/plugins
   Service Plugins: 4
   External Plugins: 2
   Total Plugins: 6

🔍 Discovering plugins...
  ✅ Loaded python service plugin
  ✅ Loaded java service plugin
  ✅ Loaded nodejs service plugin
  ✅ Loaded go service plugin
  ✅ Loaded postgres external service plugin
  ✅ Loaded redis external service plugin

[INFO] Detected service type: python
[INFO] Detected port: 8000

[INFO] Service Information:
  Python Application - Python web applications with FastAPI, Flask, Django
  Default Port: 8000
  Supported Platforms: linux, darwin, windows
  Live Updates: Yes

[SUCCESS] Service 'python-api' imported successfully!
```

### Service Listing with Plugin Information
```bash
$ ./scripts/list-services.sh

📦 X-TEAM-TOOLS SERVICE CATALOG
================================

✅ Plugin Framework: Available
   Framework Directory: .tilt/framework
   Plugins Directory: .tilt/plugins
   Service Plugins: 4
   External Plugins: 2
   Total Plugins: 6

🔌 AVAILABLE SERVICE PLUGINS
==============================
Application Services:
  • python
  • java
  • nodejs
  • go

External Services:
  • postgres
  • redis

Build Strategies:
  • live_update
```

### Service Information with Plugin Metadata
```bash
$ ./scripts/service-info.sh my-python-service

🔌 PLUGIN INFORMATION
Python Application - Python web applications with FastAPI, Flask, Django
Default Port: 8000
Supported Platforms: linux, darwin, windows
Live Updates: Yes
```

## Testing and Validation

The integration includes comprehensive testing:

```bash
$ python3 test_operational_scripts.py

======================================================================
✅ ALL OPERATIONAL SCRIPT INTEGRATION TESTS PASSED

🎯 Operational Script Integration Features:
  • Plugin-aware service type detection
  • Dynamic default port assignment
  • Plugin metadata in service information
  • Framework status checking
  • Graceful fallback to legacy mode
  • Support for all implemented service types
======================================================================
```

## Technical Implementation Details

### Plugin Directory Scanning
```bash
# Dynamic service type discovery
for plugin_file in "$PLUGINS_SERVICES_DIR"/*.star; do
    if [ -f "$plugin_file" ]; then
        local service_type=$(basename "$plugin_file" .star)
        service_types="$service_types $service_type"
    fi
done
```

### Configuration Template Generation
```bash
# Plugin-aware configuration generation
get_plugin_default_config() {
    local service_type="$1"
    local service_name="$2"
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
```

### Error Handling and Fallbacks
```bash
# Graceful fallback to legacy mode
if ! plugin_framework_available; then
    echo -e "${YELLOW}[WARNING]${NC} Plugin framework not available, using legacy mode"
    _legacy_detect_service_type "$service_dir"
    return
fi
```

## Future Enhancements

### Phase 3 Continuation
1. **Environment Plugin Integration**: Update `setup-environment.sh` to use environment plugins
2. **Build Strategy Integration**: Integrate build strategy selection in scripts
3. **Validation Enhancement**: Real-time validation using plugin validation functions
4. **Configuration Migration**: Tools to migrate legacy configurations to plugin-aware formats

### Advanced Features
1. **Interactive Service Creation**: Guided service setup using plugin capabilities
2. **Plugin Management Commands**: Install, update, and manage plugins through scripts
3. **Configuration Validation**: Pre-deployment validation using plugin rules
4. **Service Dependency Analysis**: Automatic dependency detection and resolution

## Summary

The operational script integration successfully bridges bash-based tooling with the plugin architecture, providing:

- **Complete plugin awareness** in all operational scripts
- **Dynamic service support** without script modifications
- **Enhanced user experience** with rich plugin metadata
- **Robust fallback mechanisms** for backward compatibility
- **Comprehensive testing** ensuring reliability

This integration completes a major component of Phase 3, enabling the operational tooling to fully leverage the extensible plugin architecture while maintaining the familiar bash-based interface that users expect.