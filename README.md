# x-team-tools

A collection of common useful tooling for development teams, including scripts, AI prompts, templates, and a comprehensive Tilt-based local Kubernetes development environment.

## 🚀 Quick Start

**New to the project?** Get up and running in under 10 minutes:

```bash
# 1. Clone the repository
git clone <repository-url>
cd x-team-tools

# 2. Run setup script
./scripts/setup-macos.sh

# 3. Start your development environment
tilt up -- --developer_id=$(whoami)

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
- **Developer isolation**: Each developer gets their own Kubernetes namespace
- **Flexible image sources**: ECR registry, local Docker builds, or live source builds
- **Production parity**: Uses Kubernetes patterns that mirror production

### Team Collaboration Tools
- **Standardized service templates** for consistent project structure
- **Team configuration management** with version control integration
- **Automated environment validation** and troubleshooting tools
- **Git hooks** for configuration validation and team updates

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

### Development Workflow
```bash
# Start development environment
tilt up -- --developer_id=$(whoami)

# Start specific services
tilt up -- --services=service1,service2

# Build some services locally, use ECR for others
tilt up -- --build_local=service1 --services=service1,service2,service3

# Stop development environment
tilt down

# View service logs
tilt logs service-name
```

### Environment Management
```bash
# Validate your environment
./scripts/validate-environment.sh

# Check team standards compliance
./scripts/team/validate-team-standards.sh

# Create new service from template
./scripts/team/create-service.sh my-service python

# Reset environment if needed
tilt down && kubectl delete namespace dev-$(whoami) && tilt up
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
│   ├── templates/              # Service templates
│   └── service-config.yaml     # Main service configuration
├── scripts/                    # Setup and management scripts
│   ├── setup-*.sh              # OS-specific setup scripts
│   └── team/                   # Team management scripts
├── prompts/                    # Standardized AI prompts
└── docs/                       # Additional documentation
```

## 🎯 Use Cases

### For Developers
- **Fast development cycles** with live updates (< 30 seconds from code change to running)
- **Isolated environments** - work on any combination of services without conflicts
- **Production-like testing** using Kubernetes patterns
- **Easy service switching** between local builds and ECR images

### For Teams
- **Consistent environments** across all team members
- **Standardized service creation** using templates
- **Team configuration management** with version control
- **Automated validation** of environment setup and standards

### For DevOps/Platform Teams
- **Modular architecture** for easy maintenance and extension
- **Resource management** with quotas and monitoring
- **Security best practices** built into service templates
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
# Use the team service creation script
./scripts/team/create-service.sh my-new-service python

# Or manually add to .tilt/service-config.yaml
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