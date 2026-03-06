---
paths: "**/*"
---

# Testing Standards

## Coverage

- 80% minimum for new code
- 90% for critical paths

## Required Tests per Public Function

1. **Happy path**: valid inputs, expected success
2. **Edge case**: empty, null, zero, max values
3. **Error case**: invalid inputs, exceptions

## Naming

`test_<function>_<scenario>_<expected>`
Example: `test_checkout_emptyCart_throwsValidationError`

## Rules

- Arrange-Act-Assert pattern
- One concept per test
- No conditionals in tests
- Unit <100ms, integration <1s
- Mock externals, not internals
- Independent: no order dependency
