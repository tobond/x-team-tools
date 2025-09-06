# Requirements Document

## Introduction

This feature will provide a robust local development environment system using Tilt that enables developers to **import and integrate existing services** from various sources (Git repositories, local directories) of any type (Python, Java, Go, Node.js, etc.) including CrewAI services. The system provides fast feedback loops and near-instant deployment to a local Kubernetes environment, with automatic service discovery, configuration generation, and comprehensive service management tools. Each developer will have a completely isolated environment for working with imported services.

**Architecture Note**: The system follows a **Service Import/Integration Platform** paradigm with a modular architecture where the main Tiltfile (192 lines) orchestrates focused modules for configuration, cluster management, manifest generation, service deployment, dependency management, and monitoring. The platform emphasizes importing and integrating existing services rather than creating new ones, with comprehensive automation scripts for service discovery, import, and management.

## Requirements

### Requirement 1

**User Story:** As a developer working on any type of application (Python, Java, Go, Node.js, etc.), I want to deploy my code changes instantly to a local Kubernetes environment, so that I can test my changes quickly without waiting for CI/CD pipelines.

#### Acceptance Criteria

1. WHEN a developer saves code changes THEN the system SHALL automatically rebuild and redeploy the affected service within 30 seconds
2. WHEN a deployment fails THEN the system SHALL display clear error messages and maintain the previous working version
3. WHEN multiple services are changed simultaneously THEN the system SHALL handle parallel deployments without conflicts
4. IF a service has dependencies THEN the system SHALL deploy them in the correct order

### Requirement 2

**User Story:** As a developer, I want to use images from multiple sources (ECR, local Docker, and live builds), so that I can mix production-ready components with my development code.

#### Acceptance Criteria

1. WHEN configuring a service THEN the developer SHALL be able to specify ECR image references
2. WHEN configuring a service THEN the developer SHALL be able to specify local Docker images
3. WHEN configuring a service THEN the developer SHALL be able to specify live build from source code
4. WHEN switching between image sources THEN the system SHALL update deployments without manual intervention
5. IF an ECR image is specified THEN the system SHALL authenticate and pull from the registry automatically

### Requirement 3

**User Story:** As a developer, I want the local environment to use Kubernetes patterns that mirror production configuration, so that I can catch environment-specific issues early in development.

#### Acceptance Criteria

1. WHEN deploying services THEN the system SHALL generate Kubernetes manifests that follow production deployment patterns
2. WHEN services communicate THEN they SHALL use the same networking patterns as production
3. WHEN accessing external dependencies THEN the system SHALL provide mock or proxy services
4. IF production uses specific Kubernetes features THEN the local environment SHALL support the same features
5. WHEN service configurations are updated THEN the local environment SHALL automatically regenerate manifests

### Requirement 4

**User Story:** As a developer, I want to easily manage and monitor my local development environment through Tilt's web UI, so that I can understand what's running and troubleshoot issues quickly.

#### Acceptance Criteria

1. WHEN the development environment is running THEN Tilt SHALL provide a web UI showing service status and logs
2. WHEN a service fails THEN Tilt SHALL display logs and error information in the UI with clear error highlighting
3. WHEN services are deployed THEN Tilt SHALL show real-time deployment progress and build status
4. WHEN accessing service endpoints THEN Tilt SHALL provide easy port-forwarding and endpoint access
5. IF resource usage is high THEN Tilt SHALL display warnings and resource consumption metrics

### Requirement 5

**User Story:** As a developer, I want to configure which services run locally versus using ECR images, so that I can focus on specific components while using stable versions of others.

#### Acceptance Criteria

1. WHEN starting the development environment THEN the developer SHALL be able to select which services to build locally via Tilt configuration
2. WHEN a service is configured for ECR THEN Tilt SHALL pull and deploy the specified ECR image version
3. WHEN switching between local build and ECR image THEN Tilt SHALL handle the transition seamlessly
4. IF multiple developers work on different services THEN each SHALL be able to configure their own service mix independently

### Requirement 6

**User Story:** As a developer, I want Tilt to integrate with my existing development tools, so that I don't need to change my workflow significantly.

#### Acceptance Criteria

1. WHEN using VS Code or other IDEs THEN Tilt SHALL provide debugging capabilities through port-forwarding
2. WHEN code changes are made THEN Tilt SHALL automatically detect changes and trigger rebuilds
3. WHEN using Docker builds THEN Tilt SHALL integrate with existing Dockerfiles and build processes
4. IF the developer uses specific build tools THEN Tilt SHALL support custom build commands and scripts

### Requirement 7

**User Story:** As a team lead, I want to ensure consistent development environments across the team with standardized service import and management processes, so that "works on my machine" issues are minimized.

#### Acceptance Criteria

1. WHEN a new developer joins THEN they SHALL be able to import and run existing services with automated setup scripts
2. WHEN service configurations or import processes change THEN all team members SHALL receive updates through version control
3. WHEN developers work on their local clusters THEN each SHALL have their own completely isolated environment by default
4. IF service import or environment setup fails THEN the system SHALL provide clear error messages and automated troubleshooting guidance
5. WHEN importing services THEN the system SHALL automatically detect service types, ports, and generate appropriate configurations

### Requirement 8

**User Story:** As a developer, I want to import and deploy any mix of multiple existing applications simultaneously (Python, Java, Go, Node.js, CrewAI services, etc.), so that I can work on complex workflows that span multiple applications and technology stacks.

#### Acceptance Criteria

1. WHEN importing multiple services THEN Tilt SHALL support deploying any combination of imported services from various sources
2. WHEN imported services have interdependencies THEN Tilt SHALL handle deployment ordering and service discovery automatically
3. WHEN scaling the number of imported services THEN the local Kubernetes cluster SHALL handle resource allocation efficiently
4. IF an imported service fails THEN other services SHALL continue running independently
5. WHEN importing services THEN the system SHALL organize them in a `services/` directory structure for clear separation

### Requirement 9

**User Story:** As a developer, I want to work with realistic data and external service integrations in my isolated environment, so that my local testing reflects real-world scenarios.

#### Acceptance Criteria

1. WHEN external APIs are required THEN Tilt SHALL deploy configurable mock services using generated Kubernetes manifests
2. WHEN database access is needed THEN Tilt SHALL support local database instances with test data in isolated namespaces
3. WHEN message queues are used THEN Tilt SHALL provide local queue implementations deployed via generated manifests
4. IF production secrets are needed THEN Tilt SHALL provide secure local secret management for the developer's local environment

### Requirement 10 (NEW)

**User Story:** As a developer, I want comprehensive service import and management tools, so that I can easily discover, import, configure, and monitor existing services.

#### Acceptance Criteria

1. WHEN importing a service THEN the system SHALL provide `import-service.sh` script that supports multiple repository formats (GitHub URLs, Git URLs, local paths)
2. WHEN managing services THEN the system SHALL provide `list-services.sh` script showing service status, type, ports, and location
3. WHEN investigating services THEN the system SHALL provide `service-info.sh` script with detailed service configuration and health information
4. WHEN setting up environments THEN the system SHALL provide `setup-environment.sh` script with predefined environment configurations (full-stack, backend-only, minimal, staging-mirror, feature-branch)
5. WHEN importing services THEN the system SHALL auto-detect service types, generate appropriate Dockerfiles if missing, and configure health checks