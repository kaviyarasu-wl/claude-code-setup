# Testing Patterns Reference

## Framework-Specific Patterns

### Jest (JavaScript/TypeScript)

```typescript
// Setup and teardown
beforeAll(async () => { /* run once before all tests */ });
afterAll(async () => { /* run once after all tests */ });
beforeEach(() => { /* run before each test */ });
afterEach(() => { /* run after each test */ });

// Mocking
jest.mock('./module');
jest.spyOn(object, 'method');
jest.fn().mockReturnValue(value);
jest.fn().mockResolvedValue(value);
jest.fn().mockRejectedValue(error);

// Assertions
expect(value).toBe(expected);
expect(value).toEqual(expected);
expect(value).toBeTruthy();
expect(value).toContain(item);
expect(fn).toHaveBeenCalled();
expect(fn).toHaveBeenCalledWith(arg1, arg2);
expect(fn).toHaveBeenCalledTimes(n);
expect(promise).resolves.toBe(expected);
expect(promise).rejects.toThrow(Error);
```

### Pytest (Python)

```python
# Fixtures
@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture(scope='session')
def database():
    # Setup
    yield db
    # Teardown

# Parametrize
@pytest.mark.parametrize('input,expected', [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert double(input) == expected

# Mocking
from unittest.mock import Mock, patch

@patch('module.external_call')
def test_with_mock(mock_call):
    mock_call.return_value = 'mocked'
    result = function_under_test()
    assert result == expected
```

### Go Testing

```go
func TestFunction(t *testing.T) {
    // Table-driven tests
    tests := []struct {
        name     string
        input    int
        expected int
    }{
        {"positive", 1, 2},
        {"zero", 0, 0},
        {"negative", -1, -2},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Double(tt.input)
            if result != tt.expected {
                t.Errorf("got %d, want %d", result, tt.expected)
            }
        })
    }
}

// Subtests
func TestService(t *testing.T) {
    t.Run("Create", func(t *testing.T) { /* ... */ })
    t.Run("Read", func(t *testing.T) { /* ... */ })
    t.Run("Update", func(t *testing.T) { /* ... */ })
    t.Run("Delete", func(t *testing.T) { /* ... */ })
}
```

## Common Patterns

### Test Data Builder

```typescript
class UserBuilder {
  private user: Partial<User> = {
    id: 'default-id',
    email: 'test@example.com',
    name: 'Test User',
  };

  withId(id: string) {
    this.user.id = id;
    return this;
  }

  withEmail(email: string) {
    this.user.email = email;
    return this;
  }

  build(): User {
    return this.user as User;
  }
}

// Usage
const user = new UserBuilder().withEmail('custom@example.com').build();
```

### Object Mother

```typescript
const TestUsers = {
  admin: () => ({ id: '1', role: 'admin', email: 'admin@example.com' }),
  regular: () => ({ id: '2', role: 'user', email: 'user@example.com' }),
  guest: () => ({ id: '3', role: 'guest', email: 'guest@example.com' }),
};
```

### Fake Implementation

```typescript
class FakeUserRepository implements UserRepository {
  private users: Map<string, User> = new Map();

  async findById(id: string): Promise<User | null> {
    return this.users.get(id) || null;
  }

  async save(user: User): Promise<void> {
    this.users.set(user.id, user);
  }

  // Test helper
  addUser(user: User) {
    this.users.set(user.id, user);
  }
}
```

## Coverage Guidelines

| Category | Target | Minimum |
|----------|--------|---------|
| Business Logic | 90% | 80% |
| API Handlers | 80% | 70% |
| UI Components | 70% | 50% |
| Utilities | 95% | 90% |
| Overall | 80% | 70% |

## Anti-Patterns to Avoid

- Testing implementation details
- Brittle tests that break on refactor
- Slow tests (> 1s for unit tests)
- Tests that depend on order
- Testing framework code
- Over-mocking (testing mocks, not code)
- Asserting too much in one test
