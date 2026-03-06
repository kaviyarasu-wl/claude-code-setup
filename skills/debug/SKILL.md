---
name: debug
description: Systematic debugging for Laravel + React. Use for tracing errors, analyzing logs, identifying root causes, and fixing bugs methodically.
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(npm run:*), Bash(php artisan:*), Bash(python:*), Bash(tail:*), Bash(grep:*)
model: opus
---

# Debug Skill

## Overview

Systematic approach to debugging Laravel backend and React frontend issues. Uses hypothesis-driven methodology to identify root causes efficiently.

## Debugging Methodology

### 1. Reproduce
- Identify exact steps to reproduce
- Note environment (local, staging, prod)
- Capture error messages verbatim

### 2. Isolate
- Narrow down to specific component/layer
- Check: Frontend? Backend? Database? External service?

### 3. Hypothesize
- Form 2-3 likely causes based on symptoms
- Rank by probability

### 4. Test
- Test each hypothesis systematically
- Add targeted logging/debugging
- Verify with minimal changes

### 5. Fix & Verify
- Implement fix
- Verify reproduction steps now pass
- Check for regression

## Laravel Debugging

### Log Analysis

```php
// Check Laravel logs
// storage/logs/laravel.log

// Add contextual logging
Log::info('Processing order', [
    'order_id' => $order->id,
    'user_id' => $user->id,
    'items' => $order->items->count(),
]);

// Debug specific request
Log::debug('Request data', [
    'input' => $request->all(),
    'headers' => $request->headers->all(),
    'user' => $request->user()?->id,
]);
```

### Telescope Integration

```php
// Check Telescope at /telescope
// - Requests: See full request/response cycle
// - Exceptions: Stack traces with context
// - Queries: N+1 detection, slow queries
// - Jobs: Failed job payloads
// - Cache: Hits/misses
```

### Tinker Debugging

```bash
php artisan tinker

# Test Eloquent queries
>>> User::where('email', 'test@example.com')->toSql();
>>> User::with('orders')->find(1);

# Test service classes
>>> app(OrderService::class)->calculateTotal($order);

# Check config values
>>> config('services.stripe.key');
```

### Common Laravel Issues

#### N+1 Query Problem
```php
// BAD: N+1 queries
$users = User::all();
foreach ($users as $user) {
    echo $user->department->name; // Query per user!
}

// GOOD: Eager loading
$users = User::with('department')->get();

// Detect with Telescope or:
DB::enableQueryLog();
// ... code ...
dd(DB::getQueryLog());
```

#### Queue Job Failures
```bash
# Check failed jobs
php artisan queue:failed

# Retry specific job
php artisan queue:retry <job-id>

# Check job payload
php artisan tinker
>>> DB::table('failed_jobs')->first();
```

#### Authentication Issues
```php
// Debug Sanctum
Log::debug('Auth check', [
    'guard' => config('sanctum.guard'),
    'user' => auth()->user(),
    'token' => $request->bearerToken(),
]);

// Common fixes:
// 1. Check SANCTUM_STATEFUL_DOMAINS in .env
// 2. Verify SESSION_DOMAIN matches frontend domain
// 3. Check CORS configuration
```

#### Validation Debugging
```php
// See what's being validated
$validator = Validator::make($request->all(), $rules);
dd($validator->errors()->toArray());

// Check Form Request authorization
// Did authorize() return false?
```

## React Debugging

### Console Debugging

```typescript
// Structured logging
console.log('[ComponentName]', { props, state, computedValue });

// Performance timing
console.time('expensive-operation');
// ... operation ...
console.timeEnd('expensive-operation');

// Trace call stack
console.trace('How did we get here?');
```

### React DevTools

```typescript
// Add display name for DevTools
const MyComponent = React.memo(function MyComponent(props) {
  // ...
});

// Use React DevTools Profiler
// - Record renders
// - Identify slow components
// - Check what caused re-render
```

### Hook Dependency Issues

```typescript
// BAD: Infinite loop
useEffect(() => {
  setData(fetchData()); // setData triggers re-render, effect runs again
}, [data]); // data changes every render

// GOOD: Stable dependencies
useEffect(() => {
  fetchData().then(setData);
}, []); // Empty deps = run once

// Debug deps with useEffect logging
useEffect(() => {
  console.log('[Effect] Deps changed:', { userId, filters });
  // ...
}, [userId, filters]);
```

### State Debugging

```typescript
// Track state changes
const [state, setState] = useState(initial);

const setStateWithLog = useCallback((newState) => {
  console.log('[State Update]', { from: state, to: newState });
  setState(newState);
}, [state]);

// Use React Query DevTools for server state
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
```

### Common React Issues

#### Hydration Mismatch (SSR/Inertia)
```typescript
// BAD: Different content server vs client
function Component() {
  return <div>{typeof window !== 'undefined' ? 'Client' : 'Server'}</div>;
}

// GOOD: useEffect for client-only
function Component() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  if (!mounted) return null;
  return <div>Client Only Content</div>;
}
```

#### Memory Leaks
```typescript
// BAD: No cleanup
useEffect(() => {
  const interval = setInterval(fetchData, 5000);
  // Missing cleanup!
}, []);

// GOOD: Cleanup function
useEffect(() => {
  const interval = setInterval(fetchData, 5000);
  return () => clearInterval(interval);
}, []);

// With async operations
useEffect(() => {
  let cancelled = false;
  fetchData().then(data => {
    if (!cancelled) setData(data);
  });
  return () => { cancelled = true; };
}, []);
```

## CORS Debugging

```php
// Laravel: config/cors.php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_origins' => [env('FRONTEND_URL', 'http://localhost:3000')],
    'allowed_methods' => ['*'],
    'allowed_headers' => ['*'],
    'supports_credentials' => true, // Important for Sanctum!
];
```

```typescript
// React: Ensure credentials included
fetch('/api/user', {
  credentials: 'include', // Send cookies
});

// Axios
axios.defaults.withCredentials = true;
```

## Debug Checklist

### Backend (Laravel)
- [ ] Check `storage/logs/laravel.log`
- [ ] Enable `APP_DEBUG=true` locally
- [ ] Use Telescope for request inspection
- [ ] Check database queries with `DB::enableQueryLog()`
- [ ] Verify environment variables
- [ ] Check queue worker is running

### Frontend (React)
- [ ] Check browser console for errors
- [ ] Inspect Network tab for API calls
- [ ] Use React DevTools for component state
- [ ] Check for hydration mismatches
- [ ] Verify environment variables (VITE_*)

### Integration
- [ ] Check CORS configuration
- [ ] Verify authentication headers
- [ ] Test API endpoints with Postman/curl
- [ ] Check session/cookie domains

## Usage

```
/debug "500 error on /api/orders"
/debug "React component not re-rendering"
/debug --logs storage/logs/laravel.log
/debug --trace "Undefined property $user"
```
