---
paths: "**/*.go"
---

# Go Standards

## Configuration
- Go 1.21+ required
- Use gofmt and golint
- Enable Go modules

## Code Style
- Follow Effective Go guidelines
- Use short variable names in small scopes
- CamelCase for exported, camelCase for unexported
- Keep packages focused and cohesive

## Error Handling
- Handle ALL errors explicitly
- Return errors, don't panic
- Use `errors.Is()` and `errors.As()` for comparison
- Wrap errors with context: `fmt.Errorf("operation: %w", err)`

## Concurrency
- Use channels for communication
- Prefer `sync.WaitGroup` for goroutine coordination
- Use `context.Context` for cancellation
- Avoid goroutine leaks - ensure cleanup

## Interfaces
- Define interfaces where they're used, not implemented
- Keep interfaces small (1-3 methods)
- Accept interfaces, return structs

## Testing
- Name test files `*_test.go`
- Use table-driven tests for multiple cases
- Use `testify/assert` for assertions
- Mock external dependencies

## Project Structure
- `/cmd` - Main applications
- `/internal` - Private code
- `/pkg` - Public libraries
- `/api` - API definitions
