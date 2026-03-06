---
name: security-scan
description: Scan code for security vulnerabilities. Use when checking for secrets, SQL injection, XSS, OWASP Top 10 violations, or auditing code security.
allowed-tools: Read, Grep, Glob, Bash(npm audit:*), Bash(git log:*), Bash(git diff:*)
model: opus
---

# Security Scan Skill

## Overview

Comprehensive security scanning for vulnerabilities, secrets, and OWASP Top 10 issues.

## Process

1. **Scan for Secrets**
   - API keys, tokens
   - Passwords, credentials
   - Private keys
   - Connection strings

2. **Check OWASP Top 10**
   - Injection (SQL, Command, LDAP)
   - Broken Authentication
   - Sensitive Data Exposure
   - XSS
   - Security Misconfiguration
   - And more...

3. **Analyze Dependencies**
   - Known CVEs
   - Outdated packages
   - Vulnerable transitive deps

4. **Generate Report** with severity ratings

## Security Checks

### Secrets Detection

```regex
# API Keys
(?i)(api[_-]?key|apikey)['\"]?\s*[:=]\s*['\"]?[\w-]{20,}

# AWS Keys
AKIA[0-9A-Z]{16}

# Generic Secrets
(?i)(password|secret|token|credential)['\"]?\s*[:=]\s*['\"][^'\"]+['\"]

# Private Keys
-----BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY-----
```

### SQL Injection

```typescript
// VULNERABLE
const query = `SELECT * FROM users WHERE id = ${userId}`;
db.query(`SELECT * FROM users WHERE name = '${name}'`);

// SAFE
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);
```

### XSS Prevention

```typescript
// VULNERABLE
element.innerHTML = userInput;
document.write(userInput);

// SAFE
element.textContent = userInput;
DOMPurify.sanitize(userInput);
```

### Command Injection

```typescript
// VULNERABLE
exec(`ls ${userPath}`);
child_process.exec('rm -rf ' + filename);

// SAFE
execFile('ls', [sanitizedPath]);
spawn('rm', ['-rf', filename], { shell: false });
```

## OWASP Top 10 Checklist

### A01: Broken Access Control
- [ ] Authorization checks on all endpoints
- [ ] No direct object references
- [ ] Proper CORS configuration
- [ ] Directory listing disabled

### A02: Cryptographic Failures
- [ ] TLS for all connections
- [ ] Strong encryption algorithms
- [ ] Proper key management
- [ ] No sensitive data in URLs

### A03: Injection
- [ ] Parameterized queries
- [ ] Input validation
- [ ] Output encoding
- [ ] No dynamic code execution

### A04: Insecure Design
- [ ] Threat modeling done
- [ ] Secure defaults
- [ ] Fail securely
- [ ] Least privilege

### A05: Security Misconfiguration
- [ ] Hardened configurations
- [ ] No default credentials
- [ ] Error handling doesn't leak info
- [ ] Security headers set

### A06: Vulnerable Components
- [ ] Dependencies up to date
- [ ] No known CVEs
- [ ] Minimal dependencies
- [ ] Regular audits

### A07: Authentication Failures
- [ ] Strong password policy
- [ ] Rate limiting
- [ ] Secure session management
- [ ] MFA available

### A08: Data Integrity Failures
- [ ] Signed updates
- [ ] Integrity verification
- [ ] Secure CI/CD pipeline
- [ ] No unsafe deserialization

### A09: Logging Failures
- [ ] Security events logged
- [ ] No sensitive data in logs
- [ ] Log integrity protected
- [ ] Alerting configured

### A10: SSRF
- [ ] URL validation
- [ ] Allowlists for external calls
- [ ] No raw URLs from users
- [ ] Network segmentation

## Output Format

```markdown
## Security Scan Report

### Summary
- Critical: X
- High: X
- Medium: X
- Low: X

### Critical Issues

#### [SEC-001] Hardcoded API Key
**File:** `src/config.ts:42`
**Severity:** Critical
**Category:** Secrets Exposure

**Description:**
AWS API key found hardcoded in source code.

**Evidence:**
\`\`\`typescript
const API_KEY = 'AKIA...';  // Line 42
\`\`\`

**Recommendation:**
Move to environment variables or secrets manager.

**References:**
- CWE-798: Use of Hard-coded Credentials

---

### Recommendations
1. Rotate exposed credentials immediately
2. Implement secrets management
3. Add pre-commit hooks for secret scanning
```

## Usage

```
/security src/
/security src/api/auth.ts
/security --type=secrets
/security --type=owasp
```
