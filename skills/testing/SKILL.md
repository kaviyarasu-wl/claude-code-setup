---
name: testing
description: Generate or improve tests. Use when creating unit tests, integration tests, improving coverage, setting up test infrastructure, or adding E2E tests.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(npm test:*), Bash(npm run test:*), Bash(jest:*), Bash(pytest:*)
---

# Testing Skill

## Overview

Generate comprehensive tests for code including unit, integration, and E2E tests.

## Process

1. **Analyze Target Code**
   - Identify functions/methods to test
   - Map dependencies and side effects
   - Find edge cases and error conditions

2. **Select Test Type**
   - Unit: isolated function testing
   - Integration: component interaction
   - E2E: full user workflow

3. **Generate Tests** following best practices

4. **Verify Coverage** and suggest improvements

## Test Types

### Unit Tests
- Test single function/method in isolation
- Mock external dependencies
- Fast execution (< 100ms per test)
- High coverage of business logic

### Integration Tests
- Test component interactions
- Use real dependencies when practical
- Test API contracts
- Database integration

### E2E Tests
- Test complete user workflows
- Browser/API automation
- Critical path coverage
- Smoke tests for deployment

## Test Structure (AAA Pattern)

```typescript
describe('ComponentName', () => {
  describe('methodName', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange - Setup test data and mocks
      const input = { ... };
      const mockDep = jest.fn();

      // Act - Execute the code under test
      const result = component.method(input);

      // Assert - Verify the outcome
      expect(result).toEqual(expected);
      expect(mockDep).toHaveBeenCalledWith(...);
    });
  });
});
```

## Test Cases to Cover

### Happy Path
- Normal input, expected output
- Valid user actions
- Successful API responses

### Edge Cases
- Empty inputs
- Boundary values (0, -1, MAX_INT)
- Large datasets
- Unicode/special characters

### Error Cases
- Invalid inputs
- Network failures
- Timeout scenarios
- Permission denied

### Concurrency
- Race conditions
- Parallel execution
- Lock contention

## Mocking Guidelines

### When to Mock
- External APIs
- Database connections
- File system operations
- Time-dependent code
- Random number generation

### When NOT to Mock
- Pure functions
- Value objects
- Simple utilities
- The code under test itself

## Output Format

```typescript
// tests/services/auth.test.ts

import { AuthService } from '../src/services/auth';
import { mockUserRepository } from './mocks/userRepository';

describe('AuthService', () => {
  let authService: AuthService;

  beforeEach(() => {
    authService = new AuthService(mockUserRepository);
  });

  describe('login', () => {
    it('should return token for valid credentials', async () => {
      // Arrange
      const credentials = { email: 'test@example.com', password: 'valid' };
      mockUserRepository.findByEmail.mockResolvedValue({ id: '1', ... });

      // Act
      const result = await authService.login(credentials);

      // Assert
      expect(result.token).toBeDefined();
      expect(result.token).toMatch(/^eyJ/); // JWT format
    });

    it('should throw UnauthorizedError for invalid password', async () => {
      // Arrange
      const credentials = { email: 'test@example.com', password: 'wrong' };

      // Act & Assert
      await expect(authService.login(credentials))
        .rejects.toThrow(UnauthorizedError);
    });
  });
});
```

## Usage

```
/test src/services/auth.ts
/test src/components/Button.tsx --type=unit
/test src/api/ --type=integration
```
