---
paths: "**/*.py"
---

# Python Standards

## Configuration
- Python 3.9+ required
- Use Black + isort for formatting
- Follow PEP 8 style guide

## Type Hints
- Type hints required for public APIs
- Use `typing` module for complex types
- Use `TypeVar` for generic functions
- Prefer `|` syntax for unions (Python 3.10+)

## Code Style
- Use f-strings for string formatting
- Prefer list/dict comprehensions when readable
- Use context managers (`with`) for resource management
- Keep functions under 50 lines

## Documentation
- Docstrings for all public modules, classes, functions
- Use Google-style or NumPy-style docstrings consistently
- Include type information in docstrings when not using hints

## Imports
- Standard library, third-party, local (separated by blank lines)
- Avoid wildcard imports (`from x import *`)
- Use explicit relative imports within packages

## Error Handling
- Use specific exception types
- Create custom exceptions for domain errors
- Never use bare `except:` clauses
- Log exceptions with context

## Testing
- Use pytest as test framework
- Name test files `test_*.py` or `*_test.py`
- Use fixtures for common setup
- Aim for 80%+ coverage
