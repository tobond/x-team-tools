# Business-Focused System Validation Workflow

## Overview

This workflow validates that systems deliver core business value with complete, aligned workflows across all components. Focus is on functional completeness, business requirement fulfillment, and service integration rather than edge cases or performance optimization.

## Configuration Section

Fill in these variables for your specific system:

```yaml
system_name: "[Your System/Service Name]"
system_type: "[e.g., microservices, monolith, frontend app, API]"
tech_stack: "[e.g., Java/Spring Boot, Node.js, Python/Django, React]"
build_command: "[e.g., ./gradlew build, npm run build]"
test_command: "[e.g., ./gradlew test, npm test]"

# Business Focus Areas
business_objectives:
  - "[Primary business goal]"
  - "[Secondary business goal]"
core_user_workflows:
  - "[End-to-end user journey 1]"
  - "[End-to-end user journey 2]"
key_integrations:
  - "[Service A <-> Service B integration]"
  - "[External API integration]"
critical_business_rules:
  - "[Business rule 1]"
  - "[Business rule 2]"
success_metrics:
  - "[How success is measured]"
  - "[Key business indicators]"
```

## Validation Phases

### Phase 1: Business Requirements & Architecture Alignment

#### @requirements-engineer
Validate that all business requirements are properly captured and implementable.

**Requirements Validation:**
- [ ] All business objectives clearly defined and measurable
- [ ] Core user workflows documented end-to-end
- [ ] Business rules properly specified
- [ ] Success criteria and acceptance criteria defined
- [ ] Integration requirements with other services documented
- [ ] Data flow requirements between services mapped

#### @system-architect
Review system design for business value delivery and service alignment.

**Business-Focused Architecture Review:**
- [ ] System design supports all core user workflows
- [ ] Service boundaries align with business domains
- [ ] API contracts enable complete business processes
- [ ] Integration points support required business flows
- [ ] Data models support all business rules
- [ ] Component responsibilities clearly defined and non-overlapping

##### Expected outcome: 
Ultrathink and detail plan of execution for user review. Do not proceed with implementation without direct feedback from the user. 
Create a detail plan of your findings and document the plan. 

### Phase 2: Implementation Completeness & Integration

#### @feature-implementer
Verify that all core business features are fully implemented and working.

**Implementation Completeness:**
- [ ] All core user workflows implemented end-to-end
- [ ] Business rules properly enforced in code
- [ ] Required integrations between services functional
- [ ] Data flows work correctly across service boundaries
- [ ] Configuration supports all required environments
- [ ] No placeholder implementations in core features
- [ ] All API endpoints required for workflows exist and function

#### @code-reviewer
Review code for production readiness and maintainability.

**Core Quality Review:**
- [ ] Code compiles and runs without errors
- [ ] No TODO comments in core business logic
- [ ] Error handling for critical business operations
- [ ] Consistent patterns across services
- [ ] Clear separation of business logic from infrastructure
- [ ] Code supports required business workflows

### Phase 3: Business Workflow & Service Integration Validation

#### @qa-engineer
Validate complete user workflows and business processes.

**End-to-End Workflow Validation:**
- [ ] All core user journeys work from start to finish
- [ ] Cross-service workflows function correctly
- [ ] Business rules are enforced consistently
- [ ] User can complete all intended actions
- [ ] Data flows correctly between services
- [ ] Integration points work as expected
- [ ] Error scenarios are handled gracefully


##### Expected outcome:
Stop here, document the changes, findings, action items for user review. 
Do not proceed with the next step without verifying with the user that the changes implemented are production ready. 

### Phase 4: Core Functionality Testing & Basic Reliability

#### @test-engineer
Ensure core business functionality is properly tested.

**Business-Focused Testing:**
- [ ] All core user workflows have automated tests
- [ ] Integration tests cover service-to-service workflows
- [ ] Business rule enforcement is tested
- [ ] Happy path scenarios work correctly
- [ ] Critical error scenarios are handled
- [ ] Data consistency across services is validated
- [ ] API contracts between services are tested

#### @security-auditor *(basic security only)*
Verify essential security for production deployment.

**Core Security Validation:**
- [ ] Authentication/authorization works for all workflows
- [ ] API endpoints are properly secured
- [ ] Sensitive data is not exposed
- [ ] Input validation prevents basic attacks
- [ ] Configuration secrets are managed properly
- [ ] Cross-service communication is secure

### Phase 5: Deployment & Business Value Validation


#### @engineering-manager
Validate business readiness and value delivery.

**Business Value Assessment:**
- [ ] All specified business objectives can be achieved
- [ ] Core user workflows deliver expected value
- [ ] System integration supports business processes
- [ ] Success metrics can be measured and tracked
- [ ] Business stakeholder requirements are met
- [ ] Revenue/value generation pathways are functional

### Phase 6: Final Business Readiness Review

#### @engineering-manager
Provide final assessment focused on business value delivery and readiness.

**Business Readiness Review:**
- [ ] Compile findings with focus on business impact
- [ ] Assess completion of core business requirements
- [ ] Identify blockers preventing business value delivery
- [ ] Validate end-to-end workflow completeness
- [ ] Confirm service alignment and integration
- [ ] Make GO/NO-GO decision based on business readiness

## Severity Levels

### Issue Classification (Business-Focused)
- **CRITICAL**: Core business workflows broken, prevents business value delivery, system unusable
- **HIGH**: Important business features missing/broken, service integration failures, incomplete workflows
- **MEDIUM**: Secondary features incomplete, minor workflow issues, configuration problems
- **LOW**: Nice-to-have features missing, minor UI issues, optimization opportunities

## Expected Deliverables

### 1. Executive Summary
```
System: [Name]
Assessment Date: [Date] 
Overall Status: [NOT READY | CONDITIONALLY READY | READY]
Critical Issues: [Count]
High Priority Issues: [Count]
Estimated Fix Time: [Hours/Days]
```

### 2. Detailed Findings Report
For each issue found:
```
ISSUE: [Clear description]
SEVERITY: [CRITICAL|HIGH|MEDIUM|LOW]
COMPONENT: [Affected component/service]
IMPACT: [Business/technical impact]
REMEDIATION: [Required fix with specifics]
EFFORT: [Estimated hours/days]
OWNER: [Suggested team/person]
```

### 3. Business Readiness Checklist
**MANDATORY (Must be 100% before production):**
- [ ] All core business workflows functional end-to-end
- [ ] Required service integrations working
- [ ] Business rules properly enforced
- [ ] User can achieve all primary business objectives
- [ ] Critical data flows between services working
- [ ] System deployable to production environment

**RECOMMENDED (Should be >90%):**
- [ ] Secondary business features implemented
- [ ] Error handling for business scenarios
- [ ] Basic monitoring for business operations
- [ ] Configuration supports all environments
- [ ] Service contracts properly defined
- [ ] Integration tests cover business workflows

**NICE TO HAVE:**
- [ ] Advanced features and optimizations
- [ ] Enhanced user experience improvements
- [ ] Additional monitoring and observability
- [ ] Performance optimizations beyond basic requirements

## Business Risk Assessment

**Focus on finding issues that would prevent:**
- 🎯 **Business Objectives**: Core business goals cannot be achieved
- 🔄 **Complete Workflows**: Users cannot complete intended business processes
- 🔗 **Service Integration**: Services don't work together to deliver business value  
- 📋 **Business Rules**: Required business logic is missing or incorrect
- 💼 **Value Delivery**: System doesn't deliver expected business outcomes
- 🚀 **Go-to-Market**: Product cannot be launched to achieve business goals

## Customization Guidelines

### For Different System Types

**Microservices**: 
- Focus on service boundaries, API contracts, distributed tracing
- Emphasize inter-service communication testing
- Validate service discovery and load balancing

**Frontend Applications**: 
- Prioritize UX testing, browser compatibility, accessibility
- Include performance budgets and Core Web Vitals
- Test responsive design and mobile compatibility

**APIs**: 
- Focus on contract testing, versioning, rate limiting
- Validate authentication/authorization thoroughly  
- Test error responses and status codes

**Data Pipelines**: 
- Emphasize data quality, transformation accuracy
- Validate batch and stream processing
- Include data lineage and monitoring

**Mobile Apps**: 
- Include device testing, offline functionality
- Test app store compliance requirements
- Validate push notifications and deep linking

### For Different Industries

**Financial Services**: 
- Add compliance checks (PCI-DSS, SOX)
- Include audit trails and transaction integrity
- Validate fraud detection and risk management

**Healthcare**: 
- Include HIPAA compliance validation
- Focus on data privacy and patient safety
- Validate backup and disaster recovery

**E-commerce**: 
- Emphasize payment security and inventory accuracy
- Include performance under load (traffic spikes)
- Validate recommendation algorithms

**B2B SaaS**: 
- Focus on multi-tenancy and data isolation
- Include SLA compliance validation
- Test API rate limiting and quotas

## Usage Instructions

### Step 1: Configure
Fill in the configuration section with your specific system details:
- System name, type, and technology stack
- Build and test commands
- Critical features and performance targets
- Compliance requirements

### Step 2: Customize Phases
Adjust validation phases based on your system:
- Skip irrelevant agents (e.g., @data-analyst-validator for simple CRUD APIs)
- Add domain-specific checks
- Modify focus areas for each agent

### Step 3: Execute Validation
Run each phase sequentially with the specified agents:
```
Phase 1: Requirements & Architecture → @requirements-engineer, @system-architect
Phase 2: Implementation & Integration → @feature-implementer, @code-reviewer  
Phase 3: Workflows & Business Logic → @qa-engineer, @data-analyst-validator
Phase 4: Core Testing & Security → @test-engineer, @security-auditor
Phase 5: Deployment & Value → @devops-engineer, @engineering-manager
Phase 6: Final Business Readiness → @engineering-manager
```

### Step 4: Compile Results
Gather all findings into the specified output format and prioritize by severity.

### Step 5: Make Decision
Use the production readiness checklist to make a GO/NO-GO decision.

## Example Usage Prompt

```
Using the Business-Focused System Validation Workflow:

SYSTEM CONFIGURATION:
- Name: [Your System Name]
- Type: [System Type]
- Business Objectives: [Primary business goals]
- Core User Workflows: [End-to-end user journeys]
- Key Integrations: [Service-to-service integrations]
- Critical Business Rules: [Must-have business logic]
- Success Metrics: [How you measure business success]

Please execute validation workflow phases 1-6 focusing on:
- Complete end-to-end workflow functionality
- Service integration and alignment  
- Business value delivery
- Core feature completeness

Provide findings prioritized by business impact with GO/NO-GO recommendation.
```

## Implementation Notes

### Business-Focused Coordination Principles
1. **Business Value First**: Prioritize findings that impact business objectives
2. **Complete Workflows**: Focus on end-to-end user journeys over individual features
3. **Service Alignment**: Ensure services work together to deliver business value
4. **Implementation Over Design**: Validate what's actually built, not just planned

### Quality Assurance
- **Business Impact Focus**: Prioritize issues by business value impact
- **Workflow Completeness**: Ensure users can complete all intended business processes
- **Integration Validation**: Verify services work together as intended
- **Value Delivery**: Confirm system delivers expected business outcomes

### Success Metrics
The validation is successful when:
- Core business workflows function end-to-end
- All critical business requirements are met
- Service integrations support business processes
- System ready to deliver intended business value
- Clear path to business objective achievement established

---

*This template can be adapted for any system type, technology stack, or industry. Customize the configuration section and focus areas to match your specific validation needs.*
