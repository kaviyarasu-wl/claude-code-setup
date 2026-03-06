# Code Review Standards

## Language-Specific Guidelines

### TypeScript/JavaScript

**Must Have:**
- Strict TypeScript mode enabled
- No `any` types (use `unknown` if needed)
- Async/await over callbacks
- Proper error boundaries in React
- Immutable state updates

**Avoid:**
- `var` declarations
- Nested ternaries
- `==` instead of `===`
- Console.log in production code
- Synchronous file operations

### Python

**Must Have:**
- Type hints for function signatures
- Docstrings for public functions
- Context managers for resources
- List comprehensions where readable
- f-strings for formatting

**Avoid:**
- Bare except clauses
- Mutable default arguments
- Global variables
- `from module import *`
- print() for logging

### Go

**Must Have:**
- Error handling for all returns
- Defer for cleanup
- Context for cancellation
- Interfaces for abstraction
- Proper package organization

**Avoid:**
- Panic for expected errors
- Init functions (except registration)
- Package-level variables
- Naked returns
- Empty interface unless necessary

## Complexity Thresholds

| Metric | Acceptable | Warning | Critical |
|--------|------------|---------|----------|
| Cyclomatic Complexity | < 10 | 10-20 | > 20 |
| Function Length | < 50 lines | 50-100 | > 100 |
| File Length | < 500 lines | 500-1000 | > 1000 |
| Nesting Depth | < 4 levels | 4-6 | > 6 |
| Parameters | < 5 | 5-7 | > 7 |

## Common Anti-Patterns

### God Object
- Single class/module doing too much
- Fix: Split into focused components

### Feature Envy
- Method using more data from other class
- Fix: Move method to appropriate class

### Shotgun Surgery
- One change requires many file edits
- Fix: Consolidate related logic

### Primitive Obsession
- Using primitives instead of domain types
- Fix: Create value objects

### Long Parameter List
- Too many function parameters
- Fix: Use parameter objects
