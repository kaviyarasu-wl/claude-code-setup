# Security Checklist

## Pre-Deployment Security Review

### Authentication & Authorization
- [ ] All endpoints require authentication (unless public)
- [ ] Authorization checked for each action
- [ ] Session tokens are secure (HttpOnly, Secure, SameSite)
- [ ] Password requirements enforced
- [ ] Account lockout after failed attempts
- [ ] MFA available for sensitive operations

### Input Validation
- [ ] All user input validated server-side
- [ ] Input length limits enforced
- [ ] Special characters handled properly
- [ ] File uploads restricted and scanned
- [ ] Content-Type validated

### Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] TLS 1.2+ for all connections
- [ ] PII minimized and protected
- [ ] Passwords hashed with bcrypt/argon2
- [ ] No sensitive data in logs
- [ ] No sensitive data in URLs

### API Security
- [ ] Rate limiting implemented
- [ ] CORS properly configured
- [ ] API versioning in place
- [ ] Input/output validation
- [ ] Proper error handling (no stack traces)

### Infrastructure
- [ ] Security headers configured
- [ ] CSP policy defined
- [ ] No debug mode in production
- [ ] Secrets in environment/vault
- [ ] Minimal exposed ports
- [ ] Firewall rules configured

## Secret Patterns to Detect

```yaml
Patterns:
  AWS:
    - Access Key: 'AKIA[0-9A-Z]{16}'
    - Secret Key: '[0-9a-zA-Z/+]{40}'

  Google:
    - API Key: 'AIza[0-9A-Za-z\\-_]{35}'
    - OAuth: '[0-9]+-[0-9A-Za-z_]{32}\\.apps\\.googleusercontent\\.com'

  GitHub:
    - Token: 'gh[pousr]_[A-Za-z0-9_]{36}'
    - OAuth: 'gho_[A-Za-z0-9]{36}'

  Stripe:
    - Secret: 'sk_live_[0-9a-zA-Z]{24}'
    - Publishable: 'pk_live_[0-9a-zA-Z]{24}'

  Database:
    - Connection String: '(mongodb|postgres|mysql)://[^\\s]+'
    - Password in URL: '://[^:]+:[^@]+@'

  Generic:
    - Private Key: '-----BEGIN .* PRIVATE KEY-----'
    - JWT: 'eyJ[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_=]+\\.?[A-Za-z0-9-_.+/=]*'
    - Basic Auth: 'Basic [A-Za-z0-9+/=]{20,}'
```

## Security Headers

```nginx
# Required headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self'" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

## Vulnerability Severity Levels

| Level | CVSS | Response Time | Examples |
|-------|------|---------------|----------|
| Critical | 9.0-10.0 | Immediate | RCE, SQL injection, exposed secrets |
| High | 7.0-8.9 | 24 hours | Auth bypass, SSRF, XXE |
| Medium | 4.0-6.9 | 1 week | XSS, CSRF, info disclosure |
| Low | 0.1-3.9 | 1 month | Verbose errors, missing headers |

## Common Vulnerable Patterns

### Injection
```typescript
// SQL Injection
query(`SELECT * FROM users WHERE id = ${id}`);

// Command Injection
exec(`convert ${filename} output.png`);

// LDAP Injection
filter = `(uid=${username})`;

// NoSQL Injection
db.users.find({ user: req.body.user });
```

### Authentication
```typescript
// Weak comparison
if (password == storedPassword)

// Timing attack vulnerable
if (token !== expectedToken)

// Missing rate limit
async function login(credentials) { }
```

### Data Exposure
```typescript
// Logging sensitive data
console.log('User login:', { email, password });

// Returning too much data
return user; // includes password hash

// Error disclosure
catch (e) { res.send(e.stack); }
```
