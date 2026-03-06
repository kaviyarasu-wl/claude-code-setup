# Documentation Templates

## CONTRIBUTING.md

```markdown
# Contributing to [Project]

Thank you for your interest in contributing!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/PROJECT`
3. Install dependencies: `npm install`
4. Create a branch: `git checkout -b feature/your-feature`

## Development Workflow

1. Make your changes
2. Run tests: `npm test`
3. Run linting: `npm run lint`
4. Commit using conventional commits
5. Push and create a Pull Request

## Code Style

- Follow existing code patterns
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

## Pull Request Process

1. Update README.md if needed
2. Update CHANGELOG.md
3. Get approval from maintainers
4. Squash and merge

## Code of Conduct

Be respectful and inclusive. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
```

## CHANGELOG.md

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- New feature X

### Changed
- Updated dependency Y

### Fixed
- Bug in component Z

## [1.0.0] - 2024-01-15

### Added
- Initial release
- Core functionality
- API endpoints
- Documentation
```

## Component Documentation

```markdown
# ComponentName

## Overview
Brief description of what this component does.

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `title` | `string` | Yes | - | The title text |
| `variant` | `'primary' \| 'secondary'` | No | `'primary'` | Visual style |
| `onClick` | `() => void` | No | - | Click handler |

## Usage

\`\`\`tsx
<ComponentName
  title="Hello"
  variant="primary"
  onClick={() => console.log('clicked')}
/>
\`\`\`

## Examples

### Basic Usage
\`\`\`tsx
<ComponentName title="Basic" />
\`\`\`

### With Custom Handler
\`\`\`tsx
<ComponentName
  title="Clickable"
  onClick={handleClick}
/>
\`\`\`

## Accessibility

- Supports keyboard navigation
- ARIA labels included
- Focus visible states
```

## API Endpoint Documentation

```markdown
# Create User

Creates a new user account.

## Endpoint

`POST /api/v1/users`

## Authentication

Requires `Authorization: Bearer <token>` header.

## Request Body

\`\`\`json
{
  "email": "user@example.com",
  "name": "John Doe",
  "role": "user"
}
\`\`\`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | Yes | Valid email address |
| `name` | string | Yes | User's full name |
| `role` | string | No | User role (default: "user") |

## Response

### Success (201 Created)

\`\`\`json
{
  "id": "usr_123abc",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "user",
  "createdAt": "2024-01-15T10:30:00Z"
}
\`\`\`

### Errors

| Status | Code | Description |
|--------|------|-------------|
| 400 | `INVALID_EMAIL` | Email format invalid |
| 409 | `EMAIL_EXISTS` | Email already registered |
| 422 | `VALIDATION_ERROR` | Request validation failed |

## Example

\`\`\`bash
curl -X POST https://api.example.com/api/v1/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "name": "John Doe"}'
\`\`\`
```

## Migration Guide Template

```markdown
# Migrating from v1 to v2

## Overview

This guide helps you upgrade from version 1.x to 2.0.

## Breaking Changes

### API Changes

#### Before (v1)
\`\`\`typescript
client.fetch({ url: '/api/data' });
\`\`\`

#### After (v2)
\`\`\`typescript
client.request({ endpoint: '/api/data' });
\`\`\`

### Configuration Changes

| v1 Option | v2 Option | Notes |
|-----------|-----------|-------|
| `apiUrl` | `baseUrl` | Renamed |
| `timeout` | `requestTimeout` | In milliseconds now |

## Step-by-Step Migration

1. Update package: `npm install package@2`
2. Update imports
3. Rename configuration options
4. Update API calls
5. Run tests

## Deprecation Warnings

The following will be removed in v3:
- `oldMethod()` - Use `newMethod()` instead
```
