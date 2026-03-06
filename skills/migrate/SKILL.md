---
name: migrate
description: Database migrations and schema design. Use for creating tables, relationships, indexes, seeders, and data migrations. Laravel-focused.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(php artisan:*), Bash(npx prisma:*)
---

# Migrate Skill

## Overview

Generate production-ready database migrations with proper indexes, relationships, and rollback safety. Primary focus on Laravel migrations with Eloquent conventions.

## Process

1. **Analyze Requirements**
   - Identify entities and attributes
   - Map relationships (1:1, 1:N, M:N)
   - Determine indexes needed
   - Plan soft deletes, timestamps

2. **Generate Migration**
   - Create migration file
   - Define schema with Blueprint
   - Add indexes and constraints
   - Ensure reversible (down method)

3. **Generate Model** (optional)
   - Eloquent model with relationships
   - Fillable/guarded attributes
   - Casts for data types

4. **Generate Factory & Seeder** (optional)

## Laravel Migration Patterns

### Basic Table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->ulid('ulid')->unique();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2);
            $table->integer('stock')->default(0);
            $table->boolean('is_active')->default(true);
            $table->json('metadata')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index('is_active');
            $table->index(['is_active', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
```

### Foreign Key Relationships

```php
// One-to-Many: User has many Posts
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
    $table->string('title');
    $table->text('content');
    $table->timestamps();
});

// Many-to-Many: Posts have many Tags
Schema::create('post_tag', function (Blueprint $table) {
    $table->foreignId('post_id')->constrained()->cascadeOnDelete();
    $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
    $table->primary(['post_id', 'tag_id']);
    $table->timestamps();
});

// One-to-One: User has one Profile
Schema::create('profiles', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
    $table->string('bio')->nullable();
    $table->string('avatar_url')->nullable();
    $table->timestamps();
});
```

### Polymorphic Relationships

```php
// Morphable comments (for Posts, Videos, etc.)
Schema::create('comments', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->morphs('commentable'); // Creates commentable_type, commentable_id
    $table->text('body');
    $table->timestamps();

    $table->index(['commentable_type', 'commentable_id']);
});

// Many-to-Many Polymorphic (Taggables)
Schema::create('taggables', function (Blueprint $table) {
    $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
    $table->morphs('taggable');
    $table->primary(['tag_id', 'taggable_type', 'taggable_id']);
});
```

### UUID/ULID Primary Keys

```php
Schema::create('orders', function (Blueprint $table) {
    // UUID primary key
    $table->uuid('id')->primary();
    // OR ULID (sortable, URL-safe)
    $table->ulid('id')->primary();

    $table->foreignUuid('user_id')->constrained();
    $table->decimal('total', 12, 2);
    $table->timestamps();
});
```

### Enums with PHP Enums

```php
// Migration
Schema::create('orders', function (Blueprint $table) {
    $table->id();
    $table->string('status')->default('pending');
    // ...
});

// PHP Enum
enum OrderStatus: string
{
    case Pending = 'pending';
    case Processing = 'processing';
    case Shipped = 'shipped';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';
}

// Model Cast
protected $casts = [
    'status' => OrderStatus::class,
];
```

### Modifying Existing Tables

```php
// Add columns
Schema::table('users', function (Blueprint $table) {
    $table->string('phone')->nullable()->after('email');
    $table->boolean('is_verified')->default(false)->after('phone');
});

// Drop columns
Schema::table('users', function (Blueprint $table) {
    $table->dropColumn(['phone', 'is_verified']);
});

// Rename column
Schema::table('users', function (Blueprint $table) {
    $table->renameColumn('name', 'full_name');
});

// Change column type (requires doctrine/dbal)
Schema::table('products', function (Blueprint $table) {
    $table->text('description')->change(); // was string
});
```

## Eloquent Model

```php
<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, HasUlids, SoftDeletes;

    protected $fillable = [
        'user_id',
        'status',
        'total',
        'notes',
        'metadata',
    ];

    protected $casts = [
        'status' => OrderStatus::class,
        'total' => 'decimal:2',
        'metadata' => 'array',
    ];

    // Relationships
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', OrderStatus::Pending);
    }

    public function scopeRecent($query, int $days = 30)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }
}
```

## Factory

```php
<?php

namespace Database\Factories;

use App\Enums\OrderStatus;
use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class OrderFactory extends Factory
{
    protected $model = Order::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'status' => fake()->randomElement(OrderStatus::cases()),
            'total' => fake()->randomFloat(2, 10, 1000),
            'notes' => fake()->optional()->sentence(),
            'metadata' => null,
        ];
    }

    // States
    public function pending(): static
    {
        return $this->state(fn () => ['status' => OrderStatus::Pending]);
    }

    public function shipped(): static
    {
        return $this->state(fn () => ['status' => OrderStatus::Shipped]);
    }

    public function withItems(int $count = 3): static
    {
        return $this->has(OrderItem::factory()->count($count));
    }
}
```

## Seeder

```php
<?php

namespace Database\Seeders;

use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Seeder;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        // Create users with orders
        User::factory(10)
            ->has(Order::factory(5)->withItems(3))
            ->create();

        // Create specific test data
        $admin = User::factory()->create([
            'email' => 'admin@example.com',
        ]);

        Order::factory()
            ->for($admin)
            ->pending()
            ->withItems(2)
            ->create();
    }
}
```

## Data Migration (Safe Patterns)

```php
// Large table updates - use chunking
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('full_name')->nullable()->after('name');
    });

    // Migrate data in chunks
    DB::table('users')
        ->orderBy('id')
        ->chunk(1000, function ($users) {
            foreach ($users as $user) {
                DB::table('users')
                    ->where('id', $user->id)
                    ->update(['full_name' => $user->first_name . ' ' . $user->last_name]);
            }
        });
}

// With progress (for artisan command)
public function up(): void
{
    $total = DB::table('users')->count();
    $bar = $this->output->createProgressBar($total);

    DB::table('users')->chunkById(500, function ($users) use ($bar) {
        // Process...
        $bar->advance($users->count());
    });

    $bar->finish();
}
```

## Index Guidelines

```php
// Single column index - for WHERE clauses
$table->index('email');

// Composite index - order matters! Most selective first
$table->index(['status', 'created_at']);

// Unique constraint + index
$table->unique('slug');

// Partial/Conditional index (raw)
DB::statement('CREATE INDEX orders_pending ON orders(created_at) WHERE status = \'pending\'');

// Full-text search (MySQL)
$table->fullText(['title', 'description']);
```

## Rollback Safety Checklist

- [ ] `down()` method reverses all changes
- [ ] New columns are nullable OR have defaults
- [ ] No data loss in rollback
- [ ] Foreign keys cascade appropriately
- [ ] Indexes can be recreated

## Usage

```
/migrate users           # Generate users table migration
/migrate posts --model   # Migration + Model + Factory
/migrate orders --full   # Migration + Model + Factory + Seeder
/migrate add-phone-to-users  # Modify existing table
/migrate posts_tags --pivot  # Pivot table for M:N
```
