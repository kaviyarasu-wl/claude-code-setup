---
name: review-pr
description: Review pull requests with comprehensive quality, security, and performance checklist. Use when reviewing PRs, checking code changes, validating merge readiness, or auditing pull requests.
allowed-tools: Read, Grep, Glob, Bash(gh pr:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*)
---

# PR Review Skill

## Overview

Comprehensive pull request review with quality gates for code, security, performance, and testing.

## Process

1. **Fetch PR Details**
   ```bash
   gh pr view [PR_NUMBER] --json title,body,files,commits,additions,deletions
   gh pr diff [PR_NUMBER]
   ```

2. **Apply Review Checklist** from `pr-checklist.md`

3. **Generate Structured Review** with findings by category

4. **Submit Review** or request changes

## Review Categories

### Code Quality
- SOLID principles adherence
- DRY - no duplicate code
- KISS - simple solutions preferred
- Clear naming conventions
- Appropriate abstraction levels

### Security (OWASP Top 10)
- Input validation
- Authentication/Authorization
- Sensitive data exposure
- SQL/Command injection
- XSS vulnerabilities

### Performance
- Algorithm complexity (Big-O)
- Database query efficiency
- Caching considerations
- Resource cleanup

### Testing
- Unit test coverage
- Integration tests
- Edge case handling
- Error scenarios

### Documentation
- Code comments where needed
- API documentation updated
- README changes if applicable

## Output Format

```markdown
## PR Review: [Title]

### Summary
[1-2 sentence overview]

### Findings

#### Critical (Must Fix)
- [ ] Finding 1
- [ ] Finding 2

#### Warnings (Should Fix)
- [ ] Finding 1

#### Suggestions (Consider)
- [ ] Finding 1

### Verdict
[ ] Approved
[ ] Approved with suggestions
[ ] Changes requested
```

## Usage

```
/review-pr 123
/review-pr https://github.com/owner/repo/pull/123
```
