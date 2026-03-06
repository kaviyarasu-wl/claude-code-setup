# PR Review Checklist

## Code Quality

- [ ] Code follows project style guide
- [ ] No unnecessary complexity
- [ ] Functions are focused (single responsibility)
- [ ] Variable/function names are descriptive
- [ ] No magic numbers (use constants)
- [ ] No commented-out code
- [ ] No TODO comments without tickets
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate (not excessive)

## Security

- [ ] No hardcoded secrets or credentials
- [ ] Input validation on all user inputs
- [ ] SQL queries use parameterized statements
- [ ] No eval() or similar dangerous functions
- [ ] Authentication checks where needed
- [ ] Authorization checks where needed
- [ ] Sensitive data is encrypted/hashed
- [ ] No sensitive data in logs
- [ ] Dependencies are up to date (no known CVEs)

## Performance

- [ ] No N+1 queries
- [ ] Appropriate indexing for queries
- [ ] Large datasets are paginated
- [ ] Caching used where appropriate
- [ ] No memory leaks
- [ ] Resources properly cleaned up
- [ ] Async operations used where beneficial

## Testing

- [ ] Unit tests for new functionality
- [ ] Integration tests where needed
- [ ] Edge cases covered
- [ ] Error cases tested
- [ ] Mocks used appropriately
- [ ] Test names are descriptive
- [ ] No flaky tests introduced

## Documentation

- [ ] Public APIs are documented
- [ ] Complex logic has comments
- [ ] README updated if needed
- [ ] CHANGELOG updated
- [ ] Breaking changes documented
- [ ] Migration guide if needed

## Architecture

- [ ] Follows existing patterns
- [ ] No circular dependencies
- [ ] Proper separation of concerns
- [ ] Database migrations are reversible
- [ ] Feature flags for risky changes

## Process

- [ ] PR title is descriptive
- [ ] PR description explains the why
- [ ] Linked to relevant issue/ticket
- [ ] Screenshots for UI changes
- [ ] Self-reviewed before submitting
