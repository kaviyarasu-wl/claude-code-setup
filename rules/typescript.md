---
paths: "**/*.ts, **/*.tsx, **/*.js, **/*.jsx"
---

# TypeScript/JavaScript Standards

## Configuration
- Strict mode enabled (`"strict": true`)
- ESLint + Prettier formatting
- Target ES2020+ for modern features

## Code Style
- Prefer `const` over `let`, never use `var`
- Use async/await over callbacks and raw promises
- Destructure objects and arrays when beneficial
- Use optional chaining (`?.`) and nullish coalescing (`??`)

## Type Safety
- No `any` types without explicit justification
- Use `unknown` for truly unknown types
- Define explicit return types for public functions
- Use discriminated unions for complex state

## React (when applicable)
- Prefer functional components with hooks
- Use `React.FC` sparingly, prefer explicit props typing
- Extract custom hooks for reusable logic
- Memoize expensive computations with `useMemo`/`useCallback`

## Imports
- Use absolute imports configured via tsconfig paths
- Group imports: external, internal, types, styles
- Avoid circular dependencies

## Error Handling
- Use try/catch for async operations
- Create typed error classes for domain errors
- Never swallow errors silently
