---
name: code-review
description: Deep code review for files or directories. Use for reviewing implementations, finding anti-patterns, evaluating code quality, or auditing specific code sections.
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(git show:*)
---

# Code Review Skill

## Overview

In-depth code analysis for quality, patterns, security, and maintainability.

## Process

1. **Read Target Files**
   - Analyze file structure and organization
   - Understand component relationships

2. **Apply Language-Specific Standards**
   - TypeScript/JavaScript: ESLint rules, React best practices
   - Python: PEP 8, type hints, Pythonic patterns
   - Go: Effective Go, error handling patterns
   - Rust: Ownership, lifetime patterns

3. **Check for Anti-Patterns**
   - God objects/functions
   - Circular dependencies
   - Premature optimization
   - Over-engineering

4. **Evaluate Architecture**
   - SOLID principles
   - Separation of concerns
   - Dependency injection
   - Testability

5. **Generate Report** with prioritized findings

## Review Dimensions

### Readability
- Clear naming
- Logical organization
- Appropriate comments
- Consistent formatting

### Maintainability
- Low coupling
- High cohesion
- Single responsibility
- Open/closed principle
- **5-Minute Test**: Can a junior dev understand the main flow quickly?
- **Dependency depth**: Import chains < 3 levels deep
- **Complexity per function**: Cyclomatic complexity < 15
- **Duplication**: Cross-file duplicate logic detection

### Reliability
- Error handling
- Edge cases
- Input validation
- Null safety

### Security
- Injection vulnerabilities
- Authentication/Authorization
- Data exposure
- Cryptography usage

### Performance
- Algorithm efficiency
- Memory management
- I/O optimization
- Caching strategy

## Output Format

```markdown
## Code Review: [Path]

### Overview
[Brief description of what the code does]

### Strengths
- Point 1
- Point 2

### Issues

#### High Priority
1. **[Issue Name]** (line X)
   - Problem: [description]
   - Impact: [why it matters]
   - Fix: [suggested solution]

#### Medium Priority
...

#### Low Priority
...

### Maintainability Assessment

**5-Minute Comprehension Test**: [Pass/Fail]
- Can a junior developer understand the main flow quickly?
- Are there confusing abstractions or overly clever code?

**Dependency Analysis**:
- Deepest import chain: [X] levels [Flag if > 3]
- Circular dependencies: [Yes/No]
- Unnecessary coupling: [List if found]

**Complexity Metrics**:
- Highest cyclomatic complexity: [X] in [function name] [Flag if > 15]
- Functions > 75 lines: [List or "None"]
- Classes > 600 lines: [List or "None"]

**Code Duplication**:
- Duplicate blocks found: [Count + locations]
- Suggested extractions: [Recommendations]

### Recommendations
1. [Actionable suggestion with priority]
2. [Actionable suggestion with priority]

### Metrics
- Complexity: [Low/Medium/High]
- Test Coverage: [Estimated %]
- Technical Debt: [Low/Medium/High]
- **Maintainability: [A-F]** (A=exemplary, B=good, C=acceptable, D=needs work, F=critical)
```

## Usage

```
/code-review src/services/auth.ts
/code-review src/components/
```
