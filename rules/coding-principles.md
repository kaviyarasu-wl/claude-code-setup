---
paths: "**/*"
---

# Coding Principles

## Naming Rules

- **Functions**: verb phrases (`calculateTotal`, not `calc`)
- **Variables**: noun phrases (`remainingAttempts`, not `r`)
- **Booleans**: `is/has/can/should` prefix (`isActive`, not `active`)
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Classes**: noun phrases (`OrderRepository`, not `OrderStuff`)
- **Avoid**: `data`, `info`, `temp`, `result`, `manager`, `handler`

## Composition Over Inheritance

Prefer composition when:
- Inheritance depth > 2
- Reusing behavior across unrelated classes
