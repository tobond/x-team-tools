# Fix Test Failures

## Usage
`/fix-tests <test-report-path> [--iterate-max=5]`

## Description
Systematically analyzes and address test failures using a coordinated multi-agent workflow with strict quality control and iterative refinement. Ultrathink.

## Parameters
- `test-report-path`: Path to test failure report (HTML, XML, or text format) - required
- `--iterate-max`: Maximum iteration cycles before escalation (default: 5)

## Examples
```
/fix-tests file:///Users/diegotobon/git/event-service/build/reports/tests/test/index.html
/fix-tests test-failures.log --iterate-max=3
```

## Workflow Stages

### Stage 1: Initialization & Coordination
**Lead Agent**: engineering-manager
- Reviews test failure report
- Assesses severity and scope of failures
- Creates master fix plan with priorities
- Assigns responsibilities to team members
- Sets quality gates and success criteria

### Stage 2: Requirements Analysis
**Lead Agent**: requirements-engineer
**Activities**:
1. Analyze each test failure in detail
2. Research related code and business logic
3. Identify root causes (not just symptoms)
4. Document expected vs actual behavior
5. Create detailed fix requirements document including:
   - Failure categorization (unit/integration/e2e)
   - Business impact assessment
   - Technical dependencies
   - Edge cases to consider
   - Success criteria for each fix

**Output**: `test-fix-requirements.md` with:
- Prioritized failure list
- Root cause analysis for each failure
- Detailed fix specifications
- Test coverage requirements
- Performance considerations

### Stage 3: Implementation
**Lead Agent**: feature-implementer
**Activities**:
1. Review requirements document thoroughly
2. Implement fixes systematically in priority order
3. For each fix:
   - Understand the business use case
   - Fix the root cause, not symptoms
   - Ensure no regression in related areas
   - Add defensive programming where needed
   - Update or create proper test cases
4. Run tests locally after each fix
5. Document any architectural decisions

**Quality Gates**:
- No quick hacks or workarounds
- Maintain existing functionality
- Follow project coding standards
- Ensure thread safety where applicable
- Proper error handling and logging
- Ensure no duplication of existing logic

### Stage 4: Quality Assurance
**Lead Agent**: qa-engineer
**Activities**:
1. Comprehensive testing of all fixes:
   - Verify original failures are resolved
   - Run full test suite (not just failed tests)
   - Test edge cases and boundary conditions
   - Performance testing if applicable
   - Integration testing with related components
2. Exploratory testing around fixed areas
3. Validate business logic correctness
4. Check for potential regressions
5. Create test execution report

**Output**: `qa-validation-report.md` including:
- Test execution results
- Coverage analysis
- Performance impact (if any)
- Remaining issues or concerns
- Recommendation (approve/iterate)

### Stage 5: Iteration Loop
**Condition**: If QA finds issues OR tests still failing
**Process**:
1. QA provides detailed feedback to requirements-engineer
2. Requirements-engineer updates specifications
3. Feature-implementer addresses specific issues
4. Return to Stage 4 (QA validation)
5. Track iteration count

**Max Iterations**: Configurable (default: 5)
**Escalation**: If max iterations reached, engineering-manager reviews for architectural issues

### Stage 6: Final Approval
**Lead Agent**: engineering-manager
**Activities**:
1. Review complete fix implementation
2. Validate all quality gates passed
3. Ensure business requirements met
4. Check performance characteristics
5. Review code quality and maintainability
6. Approve for merge or request changes

**Final Checks**:
- All originally failing tests pass
- No new test failures introduced
- Code quality standards met
- Documentation updated if needed
- Performance within acceptable limits

## Workflow State Management

The workflow maintains state in `.claude/test-fix-state.json`:
```json
{
  "report_path": "path/to/test/report",
  "current_stage": "implementation",
  "iteration_count": 2,
  "failures": {
    "total": 15,
    "fixed": 12,
    "in_progress": 3,
    "blocked": 0
  },
  "agents": {
    "current": "feature-implementer",
    "history": ["engineering-manager", "requirements-engineer"]
  },
  "quality_gates": {
    "all_tests_pass": false,
    "no_regressions": true,
    "performance_ok": true
  }
}
```

## Agent Coordination Rules

1. **No Corner Cutting**: Each agent must complete their full responsibilities
2. **Focus Maintenance**: Agents stay within their domain expertise
3. **Handoff Protocol**: Clear documentation at each stage transition
4. **Escalation Path**: Issues beyond scope go to engineering-manager
5. **Quality Over Speed**: Proper fixes over quick patches

## Success Criteria

The workflow completes successfully when:
- `./gradlew build` passes with no test failures. IMPORTANT: This includes all tests, not just those that were failing.
- All originally failing tests pass
- No regression in existing tests
- Code quality standards maintained
- Performance characteristics preserved
- Business logic correctly implemented
- Documentation updated as needed

## Next Steps

After successful completion:
1. Review fix summary with `/workflow-status`
2. Create pull request with fixes
3. Run CI/CD pipeline validation
4. Document lessons learned
5. Update test strategy if patterns found

## Related Commands
- `/workflow-status` - Check current fix progress
- `/qa-review` - Trigger manual QA validation
- `/team-status` - View agent assignments
- `/skip-phase` - Skip stage (use with caution)