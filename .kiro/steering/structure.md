# Project Structure

## Repository Organization

```
x-team-tools/
├── .github/                    # GitHub workflows and templates
├── .kiro/                      # Kiro AI assistant configuration
│   └── steering/               # AI guidance documents
├── prompts/                    # Standardized AI prompts
│   └── code-review.md          # Code review prompt template
├── specs/                      # Feature specifications and requirements
│   ├── dev-environment/        # Development environment specification
│   │   ├── design.md           # Technical design document
│   │   ├── requirements.md     # Feature requirements
│   │   ├── proposal.md         # Initial proposal
│   │   └── tasks.md            # Implementation tasks
│   └── requirements.md         # Requirements template and process guide
└── cortex.yaml                 # Service metadata and configuration
```

## Directory Conventions

### `/prompts/`
Contains standardized AI prompts and templates for common development tasks:
- Code review prompts with systematic analysis frameworks
- Development assistance templates
- Quality assurance guidelines

### `/specs/`
Feature specifications following a structured approach:
- **Individual feature folders**: Each major feature gets its own subdirectory
- **Standard documents**: `requirements.md`, `design.md`, `proposal.md`, `tasks.md`
- **Template file**: Root-level `requirements.md` serves as the process guide and template

### `/specs/dev-environment/`
Complete specification for the Tilt-based development environment:
- Architectural design with Mermaid diagrams
- Detailed requirements with acceptance criteria
- Implementation tasks and technical specifications

## File Naming Conventions

- **Specifications**: Use descriptive folder names with hyphens (e.g., `dev-environment`)
- **Documentation**: Use lowercase with hyphens (e.g., `code-review.md`)
- **Configuration**: Follow tool conventions (e.g., `cortex.yaml`, `Tiltfile`)

## Documentation Standards

- All documentation in Markdown format
- Use structured templates for consistency
- Include acceptance criteria for requirements
- Provide code examples and command references
- Use Mermaid diagrams for architectural documentation

## Configuration Management

- **cortex.yaml**: Service metadata, domain classification, and organizational tags
- **Tilt configuration**: Located in `.tilt/` directory (when implemented)
- **Developer settings**: Isolated per-developer configuration support