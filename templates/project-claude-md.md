# Project-Level CLAUDE.md Template

Copy this file to your project root as `CLAUDE.md` and fill in the sections.

---

# [Project Name]

## Language Standards

Uncomment the relevant rule(s) for this project:

```markdown
<!-- @~/.claude/rules/typescript.md -->
<!-- @~/.claude/rules/python.md -->
<!-- @~/.claude/rules/go.md -->
<!-- @~/.claude/rules/laravel.md -->
```

## Overview

**Description**: [What this project does in 1-2 sentences]

**Tech Stack**:
- Backend: [e.g., Laravel 12, PHP 8.5]
- Frontend: [e.g., React 18, TypeScript 5]
- Database: [e.g., PostgreSQL 15, Redis]

## Architecture

### Directory Structure
```
[Map out key directories and their purposes]
```

### Key Decisions

| Decision | Rationale |
|----------|-----------|
| [e.g., Use Actions pattern] | [Why this approach] |

## Domain Terminology

| Term | Meaning |
|------|---------|
| [Term] | [Definition] |

## Critical Code Paths

### [Flow Name]
1. [Step with file:line]
2. [Step with file:line]

## Existing Utilities (REUSE)

| Utility | Location | Purpose |
|---------|----------|---------|
| [Name] | `path/to/file` | [What it does] |

## Known Pitfalls

| Issue | Solution |
|-------|----------|
| [What goes wrong] | [How to fix] |

## Testing

```bash
# Run tests
[test command]
```

## Project-Specific Rules

[Add any rules unique to this project]
