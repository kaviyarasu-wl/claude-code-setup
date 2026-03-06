---
name: api
description: Scaffold REST APIs. Use for creating endpoints, controllers, validation, resources, and API documentation. Laravel + React focused.
allowed-tools: Read, Grep, Glob, Write, Edit
---

# API Scaffold Skill

## Overview

Rapidly scaffold production-ready API endpoints with proper validation, authentication, error handling, and documentation. Primary focus on Laravel backend + React frontend consumption.

## Process

1. **Analyze Requirements**
   - Identify resource/entity
   - Determine CRUD operations needed
   - Map relationships
   - Define validation rules

2. **Generate Laravel Backend**
   - Migration (if new table)
   - Model with relationships
   - Form Request for validation
   - Controller with actions
   - API Resource for transformation
   - Routes registration

3. **Generate React Frontend** (optional)
   - TypeScript interfaces
   - API hooks (React Query/SWR)
   - Form validation schema

4. **Document API**
   - OpenAPI/Swagger annotations
   - Example requests/responses

## Laravel API Structure

### Controller Pattern

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Actions\CreateUserAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreUserRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class UserController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $users = User::query()
            ->with(['role', 'department'])
            ->paginate();

        return UserResource::collection($users);
    }

    public function store(
        StoreUserRequest $request,
        CreateUserAction $action
    ): JsonResponse {
        $user = $action->execute($request->validated());

        return UserResource::make($user)
            ->response()
            ->setStatusCode(201);
    }

    public function show(User $user): UserResource
    {
        return UserResource::make($user->load(['role', 'department']));
    }

    public function update(
        UpdateUserRequest $request,
        User $user,
        UpdateUserAction $action
    ): UserResource {
        $user = $action->execute($user, $request->validated());

        return UserResource::make($user);
    }

    public function destroy(User $user): JsonResponse
    {
        $user->delete();

        return response()->json(null, 204);
    }
}
```

### Form Request Validation

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', User::class);
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::defaults()],
            'role_id' => ['required', 'exists:roles,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'This email is already registered.',
        ];
    }
}
```

### API Resource

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'avatar_url' => $this->avatar_url,
            'role' => RoleResource::make($this->whenLoaded('role')),
            'department' => DepartmentResource::make($this->whenLoaded('department')),
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
```

### Action Class Pattern

```php
<?php

declare(strict_types=1);

namespace App\Actions;

use App\Models\User;
use Illuminate\Support\Facades\Hash;

class CreateUserAction
{
    public function execute(array $data): User
    {
        return User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role_id' => $data['role_id'],
        ]);
    }
}
```

### Route Registration

```php
// routes/api.php
use App\Http\Controllers\Api\V1\UserController;

Route::prefix('v1')->group(function () {
    Route::middleware('auth:sanctum')->group(function () {
        Route::apiResource('users', UserController::class);
    });
});
```

## React Integration

### TypeScript Interface

```typescript
// types/api.ts
export interface User {
  id: string;
  name: string;
  email: string;
  avatar_url: string | null;
  role?: Role;
  department?: Department;
  created_at: string;
  updated_at: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
  };
  links: {
    first: string;
    last: string;
    prev: string | null;
    next: string | null;
  };
}
```

### React Query Hook

```typescript
// hooks/useUsers.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { User, PaginatedResponse } from '@/types/api';

export function useUsers(page = 1) {
  return useQuery({
    queryKey: ['users', page],
    queryFn: () => api.get<PaginatedResponse<User>>(`/api/v1/users?page=${page}`),
  });
}

export function useUser(id: string) {
  return useQuery({
    queryKey: ['users', id],
    queryFn: () => api.get<{ data: User }>(`/api/v1/users/${id}`),
    enabled: !!id,
  });
}

export function useCreateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateUserInput) => api.post('/api/v1/users', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
}
```

## HTTP Status Codes

| Status | Use Case |
|--------|----------|
| 200 | Successful GET, PUT, PATCH |
| 201 | Successful POST (resource created) |
| 204 | Successful DELETE (no content) |
| 400 | Bad request (malformed JSON) |
| 401 | Unauthenticated |
| 403 | Forbidden (no permission) |
| 404 | Resource not found |
| 422 | Validation errors |
| 429 | Rate limited |
| 500 | Server error |

## Error Response Format

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."],
    "password": ["The password must be at least 8 characters."]
  }
}
```

## Usage

```
/api users --crud
/api products --only=index,show
/api orders --with-react
/api auth/login --custom
```
