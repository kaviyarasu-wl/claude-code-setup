---
name: documentation
description: Generate or update documentation. Use for README files, API docs, code comments, ADRs, user guides, or technical documentation.
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Documentation Skill

## Overview

Generate comprehensive documentation for projects, APIs, and code.

## Documentation Types

### README Files
- Project overview
- Installation instructions
- Usage examples
- Configuration options
- Contributing guidelines

### API Documentation
- OpenAPI/Swagger specs
- Endpoint descriptions
- Request/response examples
- Authentication details

### Code Comments
- JSDoc/PyDoc/GoDoc
- Complex logic explanation
- Public API documentation

### Architecture Decision Records (ADR)
- Context and problem
- Decision and rationale
- Consequences

### User Guides
- Step-by-step tutorials
- Feature explanations
- Troubleshooting

## README Template

```markdown
# Project Name

Brief description of what this project does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

\`\`\`bash
npm install project-name
\`\`\`

## Quick Start

\`\`\`typescript
import { Project } from 'project-name';

const instance = new Project();
instance.doSomething();
\`\`\`

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `option1` | string | `'default'` | Description |

## API Reference

### `methodName(param)`

Description of what the method does.

**Parameters:**
- `param` (Type): Description

**Returns:** Type - Description

**Example:**
\`\`\`typescript
const result = instance.methodName('value');
\`\`\`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT
```

## JSDoc Format

```typescript
/**
 * Authenticates a user with the given credentials.
 *
 * @param {Object} credentials - The user credentials
 * @param {string} credentials.email - User's email address
 * @param {string} credentials.password - User's password
 * @returns {Promise<AuthResult>} The authentication result with token
 * @throws {UnauthorizedError} If credentials are invalid
 * @throws {RateLimitError} If too many attempts
 *
 * @example
 * const result = await authService.login({
 *   email: 'user@example.com',
 *   password: 'secret'
 * });
 * console.log(result.token);
 */
async login(credentials: Credentials): Promise<AuthResult> {
  // ...
}
```

## OpenAPI Snippet

```yaml
/users/{id}:
  get:
    summary: Get user by ID
    description: Returns a single user
    operationId: getUserById
    tags:
      - Users
    parameters:
      - name: id
        in: path
        required: true
        schema:
          type: string
          format: uuid
    responses:
      '200':
        description: Successful response
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/User'
      '404':
        description: User not found
```

## ADR Template

```markdown
# ADR-001: Use PostgreSQL for Primary Database

## Status
Accepted

## Context
We need to choose a primary database for the application.
Requirements include ACID compliance, JSON support, and scalability.

## Decision
We will use PostgreSQL as our primary database.

## Rationale
- ACID compliance for data integrity
- Excellent JSON/JSONB support
- Strong ecosystem and tooling
- Proven scalability with proper indexing
- Team expertise

## Consequences
### Positive
- Reliable data storage
- Flexible schema with JSONB

### Negative
- More complex than NoSQL for simple cases
- Requires schema migrations

### Risks
- Performance tuning needed for large scale
```

## Usage

```
/docs src/services/
/docs README
/docs --type=api src/api/
/docs --type=adr "Use Redis for caching"
```
