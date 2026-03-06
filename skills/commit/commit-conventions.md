# Commit Conventions Reference

## Message Structure

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

## Subject Line Rules

1. **Limit to 72 characters** - fits in git log
2. **Use imperative mood** - "add" not "added"
3. **No period at end** - save the character
4. **Capitalize type, not subject** - `feat:` not `Feat:`

## Body Guidelines

- Explain the **motivation** for the change
- Contrast with previous behavior
- Use bullet points for multiple items
- Wrap lines at 72 characters

## Footer Conventions

### Issue References
```
Fixes #123
Closes #456
Resolves #789
```

### Breaking Changes
```
BREAKING CHANGE: <description>

<migration instructions>
```

### Reviewers
```
Reviewed-by: Name <email@example.com>
Acked-by: Name <email@example.com>
```

## Atomic Commits

Each commit should:
- Represent one logical change
- Build successfully
- Pass all tests
- Be revertable independently

## Bad vs Good Examples

### Bad
```
fixed stuff
```

### Good
```
fix(auth): handle expired session gracefully

Previously, expired sessions caused a crash. Now users
are redirected to login with a friendly message.
```

### Bad
```
WIP
```

### Good
```
feat(search): add fuzzy matching algorithm

Implements Levenshtein distance for typo tolerance.
Threshold set to 2 characters difference.
```

### Bad
```
review fixes
```

### Good
```
refactor(api): rename userId to accountId

Aligns with domain terminology used in business logic.
Updates all references in controllers and services.
```

## Commit Frequency

- Commit early and often
- Each commit should be deployable
- Squash WIP commits before PR
- Keep PR commits logical and reviewable
