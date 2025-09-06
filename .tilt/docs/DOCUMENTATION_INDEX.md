# Documentation Index

Welcome to the x-team-tools development environment documentation. This index helps you find the right documentation for your needs.

## Quick Start

**New to the project?** Start here:
1. [DEVELOPER_ONBOARDING.md](DEVELOPER_ONBOARDING.md) - Get up and running in 10 minutes
2. Run setup script: `./scripts/setup-macos.sh`
3. Start development: `tilt up -- --developer_id=$(whoami)`

## Documentation Categories

### 🚀 Getting Started

| Document | Purpose | Audience |
|----------|---------|----------|
| [DEVELOPER_ONBOARDING.md](DEVELOPER_ONBOARDING.md) | Complete setup guide and first steps | New developers |
| [TEAM_SETUP.md](TEAM_SETUP.md) | Team-specific setup instructions | New team members |
| `./scripts/setup-macos.sh` | Automated macOS environment setup | All developers |

### ⚙️ Configuration

| Document | Purpose | Audience |
|----------|---------|----------|
| [TILT_CONFIGURATION_GUIDE.md](TILT_CONFIGURATION_GUIDE.md) | Advanced configuration options | Experienced developers |
| [TEAM_CONFIGURATION.md](TEAM_CONFIGURATION.md) | Team-wide configuration management | Team leads, DevOps |
| `.tilt/developer-config.yaml.template` | Personal configuration template | All developers |
| `.tilt/service-config.yaml` | Service definitions | All developers |

### 📚 Best Practices & Guides

| Document | Purpose | Audience |
|----------|---------|----------|
| [TILT_BEST_PRACTICES.md](TILT_BEST_PRACTICES.md) | Optimization and workflow tips | All developers |
| [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) | Problem diagnosis and solutions | All developers |
| Existing Guides | Specialized topics | Relevant developers |
| - [SERVICE_CONFIGURATION_GUIDE.md](SERVICE_CONFIGURATION_GUIDE.md) | Service setup and customization | |
| - [MULTI_SERVICE_ORCHESTRATION_GUIDE.md](MULTI_SERVICE_ORCHESTRATION_GUIDE.md) | Managing multiple services | |
| - [K8S_MANIFEST_GENERATION_GUIDE.md](K8S_MANIFEST_GENERATION_GUIDE.md) | Kubernetes manifest creation | |
| - [LIVE_UPDATE_GUIDE.md](LIVE_UPDATE_GUIDE.md) | Fast development cycles | |
| - [MONITORING_AND_DEBUGGING_GUIDE.md](MONITORING_AND_DEBUGGING_GUIDE.md) | Observability and debugging | |
| - [EXTERNAL_SERVICES_GUIDE.md](EXTERNAL_SERVICES_GUIDE.md) | External service integration | |

### 🔧 Tools & Scripts

| Tool | Purpose | Usage |
|------|---------|-------|
| `./scripts/validate-environment.sh` | Environment validation | `./scripts/validate-environment.sh` |
| `./scripts/setup-team-config.sh` | Setup team configuration | `./scripts/setup-team-config.sh` |
| `./scripts/setup-macos.sh` | macOS environment setup | `./scripts/setup-macos.sh` |

### 🏗️ Architecture & Design

| Document | Purpose | Audience |
|----------|---------|----------|
| [TILT_ARCHITECTURE.md](TILT_ARCHITECTURE.md) | System architecture overview | Architects, senior developers |
| [.kiro/specs/dev-environment/design.md](.kiro/specs/dev-environment/design.md) | Detailed technical design | Technical leads |
| [.kiro/specs/dev-environment/requirements.md](.kiro/specs/dev-environment/requirements.md) | System requirements | Product managers, architects |

## Common Use Cases

### I'm New to the Project
1. Read [DEVELOPER_ONBOARDING.md](DEVELOPER_ONBOARDING.md)
2. Run setup script: `./scripts/setup-macos.sh`
3. Follow the "First Time Setup" section
4. Join team Slack/chat for support

### I Want to Import an Existing Service
1. Use `./scripts/import-service.sh https://github.com/user/my-service`
2. Configure service in `.tilt/service-config.yaml` if needed
3. Test with `tilt up -- --services=my-service --build_local=my-service`
4. See [TILT_CONFIGURATION_GUIDE.md](TILT_CONFIGURATION_GUIDE.md) for advanced options

### I'm Having Issues
1. Check [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) for common solutions
2. Run `./scripts/validate-environment.sh` for diagnostics
3. Check the Tilt UI at http://localhost:10350 for error details
4. Ask for help in team channels

### I Want to Optimize Performance
1. Read [TILT_BEST_PRACTICES.md](TILT_BEST_PRACTICES.md)
2. Review [LIVE_UPDATE_GUIDE.md](LIVE_UPDATE_GUIDE.md) for fast development
3. Check [MONITORING_AND_DEBUGGING_GUIDE.md](MONITORING_AND_DEBUGGING_GUIDE.md) for observability

### I'm Setting Up Team Standards
1. Read [TEAM_CONFIGURATION.md](TEAM_CONFIGURATION.md)
2. Run `./scripts/setup-team-config.sh`
3. Customize `.tilt/team/standards.yaml`
4. Import and configure services as needed

### I Need Advanced Configuration
1. Study [TILT_CONFIGURATION_GUIDE.md](TILT_CONFIGURATION_GUIDE.md)
2. Review existing service configurations
3. Check environment-specific settings in `.tilt/environments/`
4. Test changes with `tilt validate`

## Documentation Maintenance

### For Documentation Contributors

#### Adding New Documentation
1. Follow the naming convention: `TOPIC_GUIDE.md` or `TOPIC_DOCUMENTATION.md`
2. Add entry to this index
3. Include cross-references to related documents
4. Test all commands and examples

#### Updating Existing Documentation
1. Keep examples current with latest tool versions
2. Update cross-references when moving content
3. Validate all commands still work
4. Update the "Last Updated" section if present

#### Documentation Standards
- Use clear, actionable headings
- Include code examples that can be copy-pasted
- Provide troubleshooting sections
- Cross-reference related documentation
- Use consistent formatting and terminology

### Documentation Feedback

Found an issue or have suggestions?
1. Check if it's covered in [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)
2. Create an issue in the repository
3. Suggest improvements via pull request
4. Ask in team channels for clarification

## Quick Reference

### Essential Commands
```bash
# Environment setup
./scripts/setup-macos.sh                    # Setup on macOS
./scripts/validate-environment.sh           # Validate setup

# Development workflow
tilt up -- --developer_id=$(whoami)        # Start development
tilt down                                   # Stop development
tilt logs <service-name>                    # View service logs

# Service management
./scripts/import-service.sh https://github.com/user/service  # Import service
./scripts/list-services.sh                          # List all services
./scripts/service-info.sh service-name              # Get service details

# Troubleshooting
kubectl get pods -n dev-$(whoami)          # Check pod status
kubectl logs deployment/<service> -n dev-$(whoami)  # View pod logs
docker system prune -f                     # Clean up Docker
```

### Important Files
- `Tiltfile` - Main orchestration configuration
- `.tilt/service-config.yaml` - Service definitions
- `.tilt/developer-config.yaml` - Your personal settings
- `.tilt/team/standards.yaml` - Team standards and requirements

### Key URLs
- Tilt UI: http://localhost:10350
- Tilt Documentation: https://docs.tilt.dev/
- Kubernetes Documentation: https://kubernetes.io/docs/

---

**Last Updated**: Task 12 Implementation - Documentation and Setup Automation
**Version**: 1.0.0