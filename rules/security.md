---
paths: "**/*"
---

# Security Standards

## Input/Output

- Validate ALL user inputs (allowlist > denylist)
- Escape output by context (HTML/SQL/JS)
- Parameterized queries only

## Secrets

- Environment variables, never in code
- `.env` gitignored
- Secret managers in production

## Authentication

- bcrypt/Argon2 for passwords
- Rate limit auth endpoints
- Invalidate tokens on logout
- Secure session management

## OWASP Prevention

| Vulnerability | Prevention |
|--------------|------------|
| Injection | Parameterized queries |
| XSS | Escape output, CSP headers |
| CSRF | Tokens, SameSite cookies |
| Broken Auth | MFA, secure sessions |
