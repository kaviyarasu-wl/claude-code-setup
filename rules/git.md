---
paths: "**/*"
---

# Git Standards

## Branch Naming

`<type>/<ticket>-<description>`
Types: `feature`, `fix`, `hotfix`, `refactor`, `release`

## Commit Format

```
<type>(<scope>): <description>

[body: explain why, not what]

[footer: BREAKING CHANGE, Fixes #123]
```

Types: `feat|fix|docs|style|refactor|test|chore|perf|ci|build`

## Rules

- Imperative mood ("add" not "added")
- Max 72 chars subject
- No period at end
- PRs <400 lines
