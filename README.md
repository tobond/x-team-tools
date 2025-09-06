# x-team-tools

A comprehensive **Service Import/Integration Platform** powered by Tilt for local Kubernetes development. Import existing services from any repository and set up complete development environments in minutes.

## 🚀 Quick Start

**New to the project?** Get up and running in under 10 minutes:

```bash
# 1. Clone the repository
git clone <repository-url>
cd x-team-tools

# 2. Run setup script
./scripts/setup-macos.sh

# 3. Import and start services
./scripts/list-services.sh                    # See available services
./scripts/setup-environment.sh backend-only   # Start backend environment

# 4. Open Tilt UI
open http://localhost:10350
```

For detailed setup instructions, see [DEVELOPER_ONBOARDING.md](DEVELOPER_ONBOARDING.md).

## 📚 Documentation

### Essential Guides
- **[DEVELOPER_ONBOARDING.md](DEVELOPER_ONBOARDING.md)** - Complete setup guide for new developers
- **[TILT_CONFIGURATION_GUIDE.md](TILT_CONFIGURATION_GUIDE.md)** - Advanced configuration options
- **[TILT_BEST_PRACTICES.md](TILT_BEST_PRACTICES.md)** - Optimization tips and workflows
- **[TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)** - Problem diagnosis and solutions

### Team Management
- **[TEAM_CONFIGURATION.md](TEAM_CONFIGURATION.md)** - Team-wide configuration management
- **[TEAM_SETUP.md](TEAM_SETUP.md)** - Instructions for team leads and new members

### Complete Documentation
See **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** for a complete list of all guides and documentation.

## 🛠️ Key Features

### Tilt-Based Development Environment
- **Multi-language support**: Python, Java, Go, Node.js, CrewAI services
- **Live updates**: Code changes deployed in seconds
- **Local isolation**: Each developer runs their own isolated local Kubernetes cluster
- **Flexible image sources**: ECR registry, local Docker builds, or live source builds
- **Production parity**: Uses Kubernetes patterns that mirror production

### Service Import & Integration Tools
- **Multi-repository import** from GitHub, Git URLs, or local directories
- **Automatic service detection** and configuration generation
- **Environment presets** (backend-only, full-stack, staging-mirror, minimal)
- **Service discovery** with comprehensive status monitoring

### AI-Powered Development
- **Standardized AI prompts** for code review and development assistance
- **Requirements templates** with structured specification processes
- **Feature specification workflow** using Kiro AI assistant

## 🏗️ Architecture

The development environment uses a **modular Tilt architecture** with clear separation of concerns:

```
Tiltfile (150 lines)           # Main orchestration
├── .tilt/lib/config.star      # Configuration management
├── .tilt/lib/cluster.star     # Cluster safety and detection
├── .tilt/lib/services.star    # Service deployment
├── .tilt/lib/builds.star      # Build strategies and live updates
├── .tilt/lib/monitoring.star  # Monitoring and validation
└── .tilt/lib/dependencies.star # Service dependency management
```

This modular approach ensures:
- **Maintainability**: Each module handles a single responsibility
- **Testability**: Individual modules can be tested in isolation
- **Collaboration**: Multiple developers can work on different modules
- **Extensibility**: Easy to add new service types and features

## 🔧 Common Commands

### Service Import & Management
```bash
# Import existing services
./scripts/import-service.sh github:company/user-service
./scripts/import-service.sh git@github.com:company/service.git --branch develop

# Service discovery
./scripts/list-services.sh                # Show all available services
./scripts/service-info.sh service-name   # Detailed service information

# Environment management
./scripts/setup-environment.sh backend-only    # APIs + databases
./scripts/setup-environment.sh full-stack     # All services
./scripts/setup-environment.sh minimal        # Core services only

# Manual service control
tilt up service1 service2 -- --developer_id=$(whoami)
tilt down
```

### System Management
```bash
# Validate your environment
./scripts/validate-environment.sh

# Check team standards compliance  
./scripts/team/validate-team-standards.sh

# Reset environment if needed
tilt down && kubectl delete namespace dev-$(whoami)

# Import additional services
./scripts/import-service.sh ../local-service --type reference
```

### Kubernetes Operations
```bash
# Check your namespace
kubectl get all -n dev-$(whoami)

# View pod logs
kubectl logs -f deployment/service-name -n dev-$(whoami)

# Check cluster status
kubectl cluster-info
```

## 📁 Project Structure

```
x-team-tools/
├── .kiro/                      # Kiro AI assistant configuration
│   ├── specs/dev-environment/  # Development environment specification
│   └── steering/               # AI guidance documents
├── .tilt/                      # Tilt configuration
│   ├── lib/                    # Modular Tilt libraries
│   ├── team/                   # Team standards and configuration
│   ├── environments/           # Environment-specific settings
│   └── service-config.yaml     # Main service configuration
├── scripts/                    # Service import and management scripts
│   ├── import-service.sh       # Import services from repositories
│   ├── list-services.sh        # Service discovery and catalog
│   ├── service-info.sh         # Detailed service information
│   ├── setup-environment.sh    # Predefined environment setups
│   ├── setup-*.sh              # OS-specific setup scripts
│   └── team/                   # Team management scripts
├── services/                   # Imported services directory
├── prompts/                    # Standardized AI prompts
└── docs/                       # Additional documentation
```

## 🎯 Use Cases

### For Developers
- **Fast service import** from any Git repository or local directory
- **Environment presets** for common development scenarios  
- **Service discovery** - find and understand available services
- **Isolated environments** - work on any combination of services without conflicts

### For Teams
- **Multi-repository support** - work with services from different repositories
- **Consistent environments** across all team members using predefined setups
- **Service catalog** with automatic detection and configuration
- **Environment replication** - mirror staging/production locally

### For DevOps/Platform Teams
- **Modular architecture** for easy maintenance and extension
- **Resource management** with quotas and monitoring
- **Flexible import strategies** (clone, submodule, reference)
- **Comprehensive monitoring** and debugging capabilities

## 🚨 Troubleshooting

Having issues? Try these steps:

1. **Check the Tilt UI** at http://localhost:10350 for error details
2. **Run environment validation**: `./scripts/validate-environment.sh`
3. **Check basic connectivity**: `kubectl cluster-info`
4. **Quick reset**: `tilt down && tilt up`

For detailed troubleshooting, see [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md).

## 🤝 Contributing

### Adding New Services
```bash
# Import existing service from repository
./scripts/import-service.sh github:company/my-service

# Import from local directory  
./scripts/import-service.sh ../existing-service --type reference

# Verify service information
./scripts/service-info.sh my-service
```

### Updating Team Configuration
1. Edit configuration files in `.tilt/team/` or `.tilt/environments/`
2. Test changes locally: `tilt validate && tilt up`
3. Validate team standards: `./scripts/team/validate-team-standards.sh`
4. Commit and share: `git add . && git commit -m "Update team config" && git push`

### Documentation
- Follow the patterns in existing documentation
- Add new guides to [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
- Test all commands and examples before committing

## 📋 Requirements

### Required Tools
- **Docker Desktop** (or Docker Engine + kind/k3d)
- **kubectl** (Kubernetes CLI)
- **Tilt** (v0.30.0 or later)
- **Git**

### Optional Tools
- **kind** or **k3d** (lightweight Kubernetes alternatives)
- **jq** and **yq** (JSON/YAML processing)

### System Requirements
- **CPU**: 2+ cores recommended
- **Memory**: 4GB+ available for Docker
- **Storage**: 10GB+ free space
- **OS**: macOS (Intel or Apple Silicon)

## 🔗 Links

- **Tilt Documentation**: https://docs.tilt.dev/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Docker Documentation**: https://docs.docker.com/

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Need help?** Check the [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) for comprehensive guides, or run `./scripts/validate-environment.sh` for automated diagnostics.