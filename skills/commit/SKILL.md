---
name: commit
description: Create well-structured git commits following conventional commits. Use when committing changes, preparing releases, or organizing git history.
allowed-tools: Read, Grep, Glob, Bash(git status), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*)
---

# Commit Skill

## Overview

Create standardized, well-structured commits following Conventional Commits specification.

## Process

1. **Analyze Changes**
   ```bash
   git status
   git diff --staged
   git diff
   ```

2. **Categorize Changes** by type and scope

3. **Generate Commit Message** following conventions

4. **Create Commit** with proper format

## Conventional Commits Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(cart): correct total calculation` |
| `docs` | Documentation | `docs(api): update endpoint docs` |
| `style` | Formatting (no code change) | `style: fix indentation` |
| `refactor` | Code restructuring | `refactor(db): optimize queries` |
| `test` | Adding/updating tests | `test(auth): add login tests` |
| `chore` | Maintenance | `chore: update dependencies` |
| `perf` | Performance improvement | `perf(api): cache responses` |
| `ci` | CI/CD changes | `ci: add deploy workflow` |
| `build` | Build system changes | `build: update webpack config` |
| `revert` | Revert previous commit | `revert: feat(auth): add OAuth2` |

### Scope (Optional)

Indicates the affected area:
- Component name: `auth`, `cart`, `dashboard`
- Layer: `api`, `db`, `ui`
- Feature: `login`, `checkout`, `search`

### Description Rules

- Use imperative mood: "add" not "added" or "adds"
- Don't capitalize first letter
- No period at end
- Max 72 characters

### Body (Optional)

- Explain **why**, not **what**
- Wrap at 72 characters
- Separate from subject with blank line

### Footer (Optional)

- `BREAKING CHANGE:` for breaking changes
- `Fixes #123` for issue references
- `Reviewed-by:` for reviewers

## Examples

### Simple Feature
```
feat(auth): add password reset functionality

Users can now reset their password via email link.
The reset token expires after 24 hours.

Fixes #234
```

### Breaking Change
```
feat(api)!: change response format to JSON:API

BREAKING CHANGE: All API responses now follow JSON:API spec.
Clients need to update their response parsing logic.

Migration guide: docs/migration/v2.md
```

### Bug Fix
```
fix(cart): prevent negative quantities

Validate quantity input to ensure it's always positive.
Previously, negative values caused incorrect totals.

Fixes #456
```

## Usage

```
/commit
/commit feat(auth): add login
```
