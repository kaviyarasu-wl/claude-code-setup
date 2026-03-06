# Laravel/PHP Standards

## Configuration
- PHP 8.5 required
- Laravel 12 framework
- PSR-12 coding style
- Strict types in all files (`declare(strict_types=1)`)

## PHP 8.5 Features (Always Use)
- **Property hooks** for getters/setters
- **Asymmetric visibility** (`public private(set)`)
- **`#[Override]` attribute** for method overrides
- **Constructor property promotion**
- **Named arguments** for clarity
- **Match expressions** over switch
- **Enums** for status fields and constants

## Architecture Patterns
- Use **Actions** (`app/Actions/`) for complex business logic
- Use **Repositories** (`app/Repositories/`) for data access layer
- Use **Services** (`app/Services/`) for external API integrations
- Use **Traits** for shared model functionality
- Controllers should be thin - delegate to Actions/Services

## Eloquent Conventions
- Use relationships over raw joins
- Eager load with `with()` to prevent N+1 queries
- Use `findOrFail()` instead of `find()` when record must exist
- Soft deletes for user-facing data
- UUID primary keys for API resources
- Always define `$fillable` or `$guarded`

## Validation
- Use Form Requests for complex validation
- Never validate in controllers directly for non-trivial rules
- Use custom rule objects for reusable validation logic
- Validate API input before any database operations

## API Development
- Use API Resources for response transformation
- Version APIs via URL prefix (`/api/v1/`)
- Return proper HTTP status codes
- Use pagination for list endpoints
- Implement rate limiting on public endpoints

## Laravel 12 Features
- **Reverb** for WebSockets (real-time)
- **Precognition** for real-time validation
- **Horizon** for queue monitoring
- **Octane** for high-performance serving
- **Pennant** for feature flags

## Database
- All schema changes via migrations
- Use database transactions for multi-table operations
- Index foreign keys and frequently queried columns
- Use `DB::transaction()` for atomic operations
- Seeders for sample/test data only

## Testing
- Feature tests for API endpoints in `tests/Feature/`
- Unit tests for Actions/Services in `tests/Unit/`
- Use `RefreshDatabase` trait for database tests
- Use factories for test data generation
- Aim for 80%+ coverage on business logic
- Use **Pest** as preferred test framework

## Security
- Never trust user input - always validate
- Use Eloquent bindings to prevent SQL injection
- Escape output with `{{ }}` in Blade
- Use Sanctum for API authentication
- Hash passwords with `bcrypt` or `argon2`
- Validate file uploads (type, size, content)

## Queue & Jobs
- Use queues for time-consuming operations
- Make jobs idempotent (safe to retry)
- Set appropriate timeout and retry limits
- Log job failures with context

## Error Handling
- Use custom exceptions for domain errors
- Log errors with context for debugging
- Return user-friendly API error responses
- Never expose internal errors to users

## Code Style
```php
<?php

declare(strict_types=1);

namespace App\Domain\Feature;

// PHP 8.5 property hooks
class User
{
    public string $fullName {
        get => $this->firstName . ' ' . $this->lastName;
    }

    // Asymmetric visibility
    public private(set) string $email;
}

// Constructor property promotion
public function __construct(
    private readonly UserRepository $users,
    private readonly PaymentService $payments,
) {}

// Type declarations on all methods
public function process(Request $request): JsonResponse
{
    // Named arguments for clarity
    return response()->json(
        data: $result,
        status: Response::HTTP_OK
    );
}
```

## Common Patterns
- Use Enums for status fields and constants
- Use DTOs for complex data structures
- Use Events/Listeners for side effects
- Use Policies for authorization
- Use Middleware for cross-cutting concerns
