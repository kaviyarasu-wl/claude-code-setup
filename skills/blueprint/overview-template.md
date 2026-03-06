# Overview Template

Reference template for generating `00-overview.md` in each blueprint output.

---

## Template

```markdown
# Feature: {FEATURE_NAME}

## Summary

{2-3 sentence description of the feature being built, its purpose, and its value to users.}

## Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| {e.g., Backend} | {e.g., Laravel} | {e.g., 12.x} |
| {e.g., Frontend} | {e.g., React} | {e.g., 18.x} |
| {e.g., Database} | {e.g., PostgreSQL} | {e.g., 16.x} |
| {e.g., Cache} | {e.g., Redis} | {e.g., 7.x} |

## Scope

### In Scope
- {Item 1}
- {Item 2}
- {Item 3}

### Out of Scope
- {Item 1}
- {Item 2}

## Task List

| # | Task | Category | Complexity | Dependencies | Est. Files |
|---|------|----------|------------|--------------|------------|
| 01 | {Task name} | {schema} | {Low/Medium/High} | None | {N} |
| 02 | {Task name} | {backend} | {complexity} | 01 | {N} |
| 03 | {Task name} | {backend} | {complexity} | 01 | {N} |
| 04 | {Task name} | {frontend} | {complexity} | 02, 03 | {N} |
| 05 | {Task name} | {testing} | {complexity} | 04 | {N} |

## Dependency Graph

### Visual (Mermaid)

` ` `mermaid
graph TD
    T01["01: Task Name"] --> T02["02: Task Name"]
    T01 --> T03["03: Task Name"]
    T02 --> T04["04: Task Name"]
    T03 --> T04
    T04 --> T05["05: Task Name"]

    style T01 fill:#e1f5fe
    style T05 fill:#e8f5e9
` ` `

### Execution Order

**Phase 1** (Foundation):
1. Task 01 - {name} — No dependencies

**Phase 2** (Parallel):
2. Task 02 - {name} — Depends on: 01
3. Task 03 - {name} — Depends on: 01

**Phase 3** (Integration):
4. Task 04 - {name} — Depends on: 02, 03

**Phase 4** (Verification):
5. Task 05 - {name} — Depends on: 04

> Tasks in the same phase can be executed in parallel.
> Work top-to-bottom for sequential execution.

## Key Decisions

1. **{Decision Title}**: {Brief rationale for the approach chosen}
2. **{Decision Title}**: {Brief rationale}

## Related Existing Code

| File | Relevance |
|------|-----------|
| `{path/to/file}` | {Why this file matters — e.g., "Model to extend with new relationship"} |
| `{path/to/file}` | {Relevance — e.g., "Existing service to integrate with"} |
| `{path/to/file}` | {Relevance — e.g., "Test pattern to follow"} |

## Risk Factors

| Risk | Impact | Mitigation |
|------|--------|------------|
| {Risk description} | {High/Medium/Low} | {Mitigation strategy} |
| {Risk description} | {Impact} | {Mitigation} |

## Metadata

- **Generated**: {YYYY-MM-DD}
- **Blueprint Version**: 1.0
- **Total Tasks**: {N}
- **Estimated Complexity**: {Low/Medium/High/Very High}
```

---

## Usage Notes

- The Mermaid diagram should use `graph TD` (top-down) for readability
- Color the first task(s) with `fill:#e1f5fe` (blue) and final task(s) with `fill:#e8f5e9` (green)
- Phase grouping must match the Mermaid diagram — tasks at the same horizontal level = same phase
- For features with >15 tasks, add milestone markers between phase groups
- The "Related Existing Code" table should only include files that are directly relevant (not every file scanned)
- Risk factors should focus on technical risks, not business risks
