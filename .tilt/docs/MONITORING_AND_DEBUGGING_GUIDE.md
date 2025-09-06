# Monitoring and Debugging Guide

This guide covers the comprehensive monitoring and debugging capabilities implemented in the Tilt-based development environment.

## Overview

The monitoring system provides real-time visibility into your local development environment with the following key capabilities:

- **Real-time Service Monitoring**: Live status updates for all deployed services
- **Resource Usage Tracking**: CPU, memory, and storage consumption monitoring
- **Endpoint Management**: Automatic port forwarding and connectivity testing
- **Debugging Tools**: Comprehensive troubleshooting and diagnostic resources
- **Log Aggregation**: Centralized log viewing across all services
- **Health Checks**: Automated service health validation

## Monitoring Resources

### 1. Monitoring Dashboard (`monitoring-dashboard`)

**Purpose**: Provides a comprehensive overview of your entire development environment

**Features**:
- Cluster overview and health status
- Namespace resource summary
- Real-time resource usage metrics
- Recent events and warnings
- Service endpoint listing

**Usage**: Click the `monitoring-dashboard` resource in Tilt UI for a complete environment overview.

### 2. Service Health Check (`service-health-check`)

**Purpose**: Validates the health status of all deployed services

**Features**:
- Pod status validation (Running, Ready, etc.)
- Resource usage per service
- Recent events for each service
- Overall environment health assessment

**Usage**: Click `service-health-check` to validate all services are healthy.

### 3. Resource Monitor (`resource-monitor`)

**Purpose**: Tracks resource consumption and identifies performance issues

**Features**:
- Node-level resource usage
- Pod-level CPU and memory consumption
- Storage usage and persistent volume status
- Resource quota monitoring
- High usage warnings (>80% CPU/Memory)

**Usage**: Click `resource-monitor` to check resource consumption and identify bottlenecks.

### 4. Service Dashboard (`service-dashboard`)

**Purpose**: Provides detailed status for each individual service

**Features**:
- Service-specific status and health
- Build strategy information (Local vs ECR)
- Port and endpoint information
- Resource usage per service
- Quick action links

**Usage**: Automatically updates to show real-time service status. Click for detailed view.

### 5. Endpoint Dashboard (`endpoint-dashboard`)

**Purpose**: Manages service endpoints and connectivity

**Features**:
- Web service endpoints with health check URLs
- Data service connection information
- Connectivity testing for all ports
- Connection command examples
- Port forwarding status

**Usage**: Click `endpoint-dashboard` to view all service endpoints and test connectivity.

## Debugging Resources

### 1. Debug Environment (`debug-environment`)

**Purpose**: Comprehensive environment diagnostics and troubleshooting

**Features**:
- Cluster diagnostics and context validation
- Failed and pending resource identification
- Warning event aggregation
- Quick fix suggestions
- Environment reset guidance

**Usage**: Click `debug-environment` when experiencing issues for diagnostic information.

### 2. Logs Aggregator (`logs-aggregator`)

**Purpose**: Centralized log viewing across all services

**Features**:
- Recent logs from all deployed services
- Pod identification and status
- Real-time log streaming commands
- Service-specific log access

**Usage**: Click `logs-aggregator` to view recent logs from all services.

### 3. Individual Service Monitors (`<service-name>-monitor`)

**Purpose**: Detailed monitoring for specific services

**Features**:
- Pod status and detailed information
- Service endpoint details
- Resource usage metrics
- Recent log entries
- Troubleshooting command suggestions

**Usage**: Click `<service-name>-monitor` for detailed service-specific information.

### 4. Service Endpoints (`<service-name>-endpoints`)

**Purpose**: Service-specific endpoint management

**Features**:
- Service-specific endpoint information
- Port accessibility testing
- Connection status validation
- Service-type specific connection details

**Usage**: Click `<service-name>-endpoints` to check specific service connectivity.

## K8s Resource Configuration

### Enhanced Resource Grouping

Services are automatically grouped in the Tilt UI using comprehensive labels:

- **Category Labels**: `infrastructure` vs `application`
- **Tier Labels**: `data`, `service`, `generic`
- **Type Labels**: Service technology (`python`, `java`, `go`, `nodejs`, etc.)
- **Build Labels**: `local` vs `ecr` build strategy
- **Developer Labels**: Per-developer isolation

### Trigger Modes

Resources use intelligent trigger mode configuration:

- **Infrastructure Services** (postgres, redis): `TRIGGER_MODE_MANUAL` for stability
- **Application Services**: `TRIGGER_MODE_AUTO` for fast iteration
- **Monitoring Resources**: `TRIGGER_MODE_MANUAL` for on-demand execution

### Port Forwarding

Automatic port forwarding is configured for all services:

- **Web Services**: HTTP endpoints with health check paths
- **Data Services**: Database and cache connections
- **Custom Services**: Application-specific port configurations

## Usage Examples

### Quick Health Check

1. Click `service-health-check` in Tilt UI
2. Review overall status and any warnings
3. Check individual service status

### Troubleshooting a Failed Service

1. Click `debug-environment` to identify issues
2. Click `<service-name>-monitor` for specific service details
3. Click `logs-aggregator` to view recent logs
4. Use suggested troubleshooting commands

### Monitoring Resource Usage

1. Click `resource-monitor` for cluster-wide usage
2. Check for high usage warnings
3. Review individual service resource consumption
4. Scale or optimize as needed

### Accessing Service Endpoints

1. Click `endpoint-dashboard` for all endpoints
2. Test connectivity for specific services
3. Use provided connection commands
4. Access services via port-forwarded URLs

## Best Practices

### Regular Monitoring

- Check `monitoring-dashboard` regularly for environment overview
- Use `service-health-check` before starting development work
- Monitor `resource-monitor` to prevent resource exhaustion

### Debugging Workflow

1. Start with `debug-environment` for overall diagnostics
2. Use service-specific monitors for detailed investigation
3. Check logs with `logs-aggregator`
4. Test connectivity with endpoint dashboards

### Performance Optimization

- Monitor resource usage regularly
- Identify high-usage services and optimize
- Use manual trigger modes for stable infrastructure services
- Scale local cluster resources as needed

## Troubleshooting Common Issues

### Service Not Starting

1. Check `debug-environment` for failed pods
2. Review `<service-name>-monitor` for specific errors
3. Check logs with `logs-aggregator`
4. Verify resource availability with `resource-monitor`

### Connectivity Issues

1. Use `endpoint-dashboard` to test port accessibility
2. Check `<service-name>-endpoints` for specific service
3. Verify port forwarding in Tilt UI
4. Test with provided connection commands

### High Resource Usage

1. Check `resource-monitor` for usage warnings
2. Identify high-usage services
3. Consider scaling cluster resources
4. Optimize service configurations

### Environment Reset

1. Use `cleanup-environment` to reset namespace
2. Restart Tilt to recreate environment
3. Verify with `monitoring-dashboard`

## Testing the Implementation

Run the monitoring capabilities test:

```bash
python3 .tilt/test-monitoring-capabilities.py
```

This validates that all monitoring resources are properly configured and functional.

## Integration with Tilt UI

All monitoring resources are designed to work seamlessly with Tilt's web UI:

- Resources are grouped by category using labels
- Manual trigger modes allow on-demand execution
- Real-time updates provide live environment status
- Port forwarding is automatically managed
- Logs and status are easily accessible

The monitoring system transforms the Tilt UI into a comprehensive development environment dashboard, providing all the visibility and control needed for effective local development.