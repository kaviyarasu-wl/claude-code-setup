# Task Template

Reference template for generating individual task documents (`NN-task-name.md`) in each blueprint output.

---

## Template

```markdown
# Task {NN}: {TASK_NAME}

**Category**: {schema | backend | frontend | integration | infrastructure | testing | documentation}
**Complexity**: {Low | Medium | High}
**Dependencies**: {Task numbers that must complete first, or "None"}
**Blocks**: {Task numbers that depend on this task, or "None"}

---

## Spec

### Goal

{One clear sentence describing what this task accomplishes and why it matters for the feature.}

### Files to Create

| File | Purpose |
|------|---------|
| `{full/path/to/new/file}` | {What this file does} |
| `{full/path/to/new/file}` | {What this file does} |

### Files to Modify

| File | Changes |
|------|---------|
| `{full/path/to/existing/file}` | {Brief description of what changes and why} |
| `{full/path/to/existing/file}` | {Brief description} |

### Implementation Steps

1. {Step 1 — specific, actionable instruction with technical detail}
   - {Sub-step if needed}
   - {Sub-step if needed}
2. {Step 2 — reference specific patterns from the codebase}
3. {Step 3}
4. {Step N}

### Acceptance Criteria

- [ ] {Verifiable condition 1 — measurable and testable}
- [ ] {Verifiable condition 2}
- [ ] {Verifiable condition 3}
- [ ] {All tests pass}

### Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| {Edge case 1 — e.g., empty input} | {How the system should handle it} |
| {Edge case 2 — e.g., concurrent access} | {Expected behavior} |
| {Edge case 3 — e.g., network failure} | {Expected behavior} |

### Testing Requirements

- **Unit Tests**: {What to test — specific functions/methods, expected inputs/outputs}
- **Integration Tests**: {What interactions to verify — API calls, DB queries, service communication}
- **Coverage Target**: {Percentage — typically 80%+ for business logic}

### Notes

{Additional context from the codebase scan or clarification phase. Reference specific existing patterns, files, utilities, or conventions the implementer should follow. Mention any related decisions from the overview.}

---

## Prompt

> **Ready-to-use Claude Code prompt. Copy and paste directly to execute this task.**

Implement {task goal} for the {feature name} feature.

## Context
- This project uses {tech stack with versions}
- Architecture pattern: {pattern detected from codebase}
- Relevant existing code:
  - `{path/to/related/file}` — {what it does and how it relates}
  - `{path/to/related/file}` — {what it does}
- This task depends on tasks [{dependencies}] being completed first
- Follow the existing conventions in this codebase: {specific conventions observed}

## What to Build
{Detailed description of what needs to be implemented, derived from the Goal and Implementation Steps above.}

## Files to Create
{List each file with full path and description of its contents}

- `{full/path/to/file}` — {description}

## Files to Modify
{List each file with full path and what to change}

- `{full/path/to/file}` — {what to change and why}

## Implementation Details
{Step-by-step instructions with enough detail to implement without ambiguity. Reference specific existing code patterns, base classes, utilities, or conventions from the codebase.}

1. {Detailed step 1}
2. {Detailed step 2}
3. {Detailed step N}

## Acceptance Criteria
{Copy from spec section — these must all pass after implementation}

- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] {Criterion 3}

## Testing
{What tests to write, where to put them, what framework to use, what patterns to follow from existing tests}

- Write unit tests in `{test/path/}` using {test framework}
- Follow the test pattern in `{path/to/existing/test}` as reference
- Cover: {specific scenarios}
- Target: {coverage percentage}

## Edge Cases to Handle
{Copy from spec section}

- {Edge case 1}: {handling strategy}
- {Edge case 2}: {handling strategy}

## Verification
After implementation, verify:
1. {How to manually test — specific commands or actions}
2. Run tests: `{test command}`
3. Check that acceptance criteria are all met

---

**Parent Feature**: [{FEATURE_NAME}](./00-overview.md)
**Previous Task**: [{PREV_TASK_NAME}](./{PREV_FILE}) | **Next Task**: [{NEXT_TASK_NAME}](./{NEXT_FILE})
```

---

## Usage Notes

- The Prompt section must be **completely self-contained** — it should include all context needed to implement without reading any other document
- Never use "see task X" or "as described in the overview" in the Prompt section
- File paths in the prompt must be absolute from project root
- The Verification section should include actual runnable commands (test commands, curl examples, etc.)
- Navigation footer links enable sequential task execution
- For the first task, Previous Task link should be omitted
- For the last task, Next Task link should be omitted
- Each prompt should explicitly instruct to verify acceptance criteria after implementation
