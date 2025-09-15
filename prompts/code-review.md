# Code Review Prompt

Perform a systematic code review as a senior engineer. First, analyze the diff between the provided changes and the main branch to understand what's being modified. 
Review ONLY these changes. Your review must identify issues in order of criticality and provide specific, actionable fixes. 
Do not suggest features or refactoring beyond the changed lines unless they fix critical bugs.

## Review Process

### 1. Diff Analysis
- Identify all files changed vs master branch
- List added/modified/deleted functions and classes
- Note the scope and impact of changes
- Ultrathink to Understand the intent behind modifications

### 2. Understand Context
- Read ALL changes in the diff before commenting
- Map how modified code flows with unchanged code
- Review tests to understand expected behavior (if any)
- Note questions without making assumptions, verify your reasoning. 

### 3. Systematic Analysis
Examine changed code for:
- **Correctness**: Logic errors, edge cases, boundary conditions, race conditions
- **Security**: Input validation, auth checks, injection vulnerabilities, secrets exposure
- **Performance**: Algorithm complexity, query efficiency, memory leaks, unnecessary operations
- **Reliability**: Error handling, logging, timeouts, recovery mechanisms
- **Quality**: Code duplication, naming, function size, SOLID principles
- **Testing**: Coverage of critical paths, edge cases, integration points

### 4. Output Format

```
## Changes Summary
[Files modified: X | Lines added: Y | Lines removed: Z]
[One sentence describing the change intent]

## Critical Issues (Must Fix - Will break production)
C1. [Issue]: [File:Line] - [Problem] → [Specific fix]

## Major Issues (Should Fix - Performance/maintainability)
M1. [Issue]: [File:Line] - [Problem] → [Recommendation]

## Minor Issues (Consider - Style/optimization)
m1. [Issue]: [File:Line] → [Suggestion]

## Questions
Q1. [File:Line] - [What needs clarification]

## Good Practices
- [What was done well in the changes]
```

## Prioritization
- **Critical**: Bugs, security holes, data loss risks
- **Major**: Performance issues, tech debt, principle violations
- **Minor**: Style, naming, small optimizations

## Remember
Review only the diff. Be specific with line numbers. Propose solutions, not just problems.
