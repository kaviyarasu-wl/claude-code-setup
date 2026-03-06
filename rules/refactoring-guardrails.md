---
paths: "**/*"
---

# Refactoring Guardrails

## Auto-Refactor Triggers

| Smell | Warn | MUST Fix | Pattern |
|-------|------|----------|---------|
| Long function | >50 | >75 | Extract methods |
| Large class | >400 | >600 | Split (SRP) |
| Many params | >3 | >4 | Parameter object |
| Deep nesting | >2 | >3 | Guard clauses |
| High complexity | >10 | >15 | Strategy/lookup |
| Duplicate code | >4 | >6 | Extract utility |
| Magic numbers | any | any | Named constant |

## Safety Rules

**Before**: Tests pass, commit current state
**During**: One refactor at a time, no behavior changes
**After**: All tests pass, commit with `refactor:` type

**Never**: Combine refactoring with features, skip tests, refactor without VCS
