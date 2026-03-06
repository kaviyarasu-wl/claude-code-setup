---
name: refactor
description: Code refactoring for Laravel + React. Extract patterns, modernize code, apply SOLID principles, and eliminate code smells.
allowed-tools: Read, Grep, Glob, Write, Edit
model: opus
---

# Refactor Skill

## Overview

Systematic code refactoring for Laravel backends and React frontends. Focuses on extracting patterns, modernizing legacy code, and improving maintainability without changing behavior.

## Refactoring Principles

1. **One change at a time** - Never combine multiple refactors
2. **Tests first** - Ensure tests pass before and after
3. **Small commits** - Each refactor = one commit
4. **No behavior change** - Refactoring ≠ adding features

## Laravel Refactoring Patterns

### Extract Action Class

**Before: Fat Controller**
```php
class OrderController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'items' => 'required|array',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        $order = Order::create([
            'user_id' => auth()->id(),
            'status' => 'pending',
        ]);

        $total = 0;
        foreach ($validated['items'] as $item) {
            $product = Product::find($item['product_id']);
            $subtotal = $product->price * $item['quantity'];
            $total += $subtotal;

            $order->items()->create([
                'product_id' => $product->id,
                'quantity' => $item['quantity'],
                'price' => $product->price,
                'subtotal' => $subtotal,
            ]);

            $product->decrement('stock', $item['quantity']);
        }

        $order->update(['total' => $total]);

        // Send notification, log, etc...

        return new OrderResource($order);
    }
}
```

**After: Thin Controller + Action**
```php
// app/Actions/CreateOrderAction.php
class CreateOrderAction
{
    public function execute(array $items, User $user): Order
    {
        return DB::transaction(function () use ($items, $user) {
            $order = Order::create([
                'user_id' => $user->id,
                'status' => OrderStatus::Pending,
            ]);

            $total = $this->createOrderItems($order, $items);
            $order->update(['total' => $total]);

            return $order;
        });
    }

    private function createOrderItems(Order $order, array $items): float
    {
        $total = 0;

        foreach ($items as $item) {
            $product = Product::findOrFail($item['product_id']);
            $subtotal = $product->price * $item['quantity'];
            $total += $subtotal;

            $order->items()->create([
                'product_id' => $product->id,
                'quantity' => $item['quantity'],
                'price' => $product->price,
                'subtotal' => $subtotal,
            ]);

            $product->decrement('stock', $item['quantity']);
        }

        return $total;
    }
}

// Controller becomes thin
class OrderController extends Controller
{
    public function store(
        StoreOrderRequest $request,
        CreateOrderAction $action
    ): OrderResource {
        $order = $action->execute(
            $request->validated('items'),
            $request->user()
        );

        return new OrderResource($order);
    }
}
```

### Extract Repository

**Before: Model queries in controller**
```php
public function index(Request $request)
{
    $users = User::query()
        ->when($request->search, fn($q, $s) => $q->where('name', 'like', "%{$s}%"))
        ->when($request->role, fn($q, $r) => $q->where('role_id', $r))
        ->when($request->active, fn($q) => $q->where('is_active', true))
        ->with(['role', 'department'])
        ->orderBy($request->sort ?? 'created_at', $request->direction ?? 'desc')
        ->paginate($request->per_page ?? 15);

    return UserResource::collection($users);
}
```

**After: Repository pattern**
```php
// app/Repositories/UserRepository.php
class UserRepository
{
    public function __construct(
        private User $model
    ) {}

    public function search(UserSearchCriteria $criteria): LengthAwarePaginator
    {
        return $this->model->query()
            ->when($criteria->search, $this->applySearch(...))
            ->when($criteria->roleId, $this->filterByRole(...))
            ->when($criteria->activeOnly, $this->filterActive(...))
            ->with(['role', 'department'])
            ->orderBy($criteria->sortBy, $criteria->sortDirection)
            ->paginate($criteria->perPage);
    }

    private function applySearch(Builder $query, string $search): void
    {
        $query->where(function ($q) use ($search) {
            $q->where('name', 'like', "%{$search}%")
              ->orWhere('email', 'like', "%{$search}%");
        });
    }

    private function filterByRole(Builder $query, int $roleId): void
    {
        $query->where('role_id', $roleId);
    }

    private function filterActive(Builder $query): void
    {
        $query->where('is_active', true);
    }
}

// DTO for search criteria
readonly class UserSearchCriteria
{
    public function __construct(
        public ?string $search = null,
        public ?int $roleId = null,
        public bool $activeOnly = false,
        public string $sortBy = 'created_at',
        public string $sortDirection = 'desc',
        public int $perPage = 15,
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            search: $request->input('search'),
            roleId: $request->input('role'),
            activeOnly: $request->boolean('active'),
            sortBy: $request->input('sort', 'created_at'),
            sortDirection: $request->input('direction', 'desc'),
            perPage: $request->input('per_page', 15),
        );
    }
}
```

### PHP 8.5 Modernization

**Before: Traditional getters/setters**
```php
class User extends Model
{
    public function getFullNameAttribute(): string
    {
        return $this->first_name . ' ' . $this->last_name;
    }

    public function setPasswordAttribute(string $value): void
    {
        $this->attributes['password'] = Hash::make($value);
    }
}
```

**After: Property hooks (PHP 8.5)**
```php
class User extends Model
{
    public string $fullName {
        get => $this->first_name . ' ' . $this->last_name;
    }

    public string $password {
        set => Hash::make($value);
    }
}
```

**Before: Constructor assignment**
```php
class OrderService
{
    private OrderRepository $orders;
    private PaymentGateway $payments;
    private Logger $logger;

    public function __construct(
        OrderRepository $orders,
        PaymentGateway $payments,
        Logger $logger
    ) {
        $this->orders = $orders;
        $this->payments = $payments;
        $this->logger = $logger;
    }
}
```

**After: Constructor promotion**
```php
class OrderService
{
    public function __construct(
        private readonly OrderRepository $orders,
        private readonly PaymentGateway $payments,
        private readonly Logger $logger,
    ) {}
}
```

## React Refactoring Patterns

### Extract Custom Hook

**Before: Logic in component**
```tsx
function UserList() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [page, setPage] = useState(1);

  useEffect(() => {
    setLoading(true);
    fetch(`/api/users?page=${page}`)
      .then(res => res.json())
      .then(data => {
        setUsers(data.data);
        setLoading(false);
      })
      .catch(err => {
        setError(err);
        setLoading(false);
      });
  }, [page]);

  // ... render logic
}
```

**After: Custom hook**
```tsx
// hooks/useUsers.ts
function useUsers(page: number = 1) {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);

    fetch(`/api/users?page=${page}`)
      .then(res => res.json())
      .then(data => {
        if (!cancelled) {
          setUsers(data.data);
          setLoading(false);
        }
      })
      .catch(err => {
        if (!cancelled) {
          setError(err);
          setLoading(false);
        }
      });

    return () => { cancelled = true; };
  }, [page]);

  return { users, loading, error };
}

// Component becomes clean
function UserList() {
  const [page, setPage] = useState(1);
  const { users, loading, error } = useUsers(page);

  // ... render logic only
}
```

### Extract Presentational Component

**Before: Mixed logic and presentation**
```tsx
function OrderCard({ orderId }: { orderId: string }) {
  const { data: order, isLoading } = useQuery(['order', orderId], fetchOrder);
  const cancelMutation = useMutation(cancelOrder);

  if (isLoading) return <Skeleton />;

  const statusColor = {
    pending: 'yellow',
    processing: 'blue',
    shipped: 'purple',
    delivered: 'green',
    cancelled: 'red',
  }[order.status];

  return (
    <div className="p-4 border rounded">
      <div className="flex justify-between">
        <h3>{order.id}</h3>
        <span className={`badge-${statusColor}`}>{order.status}</span>
      </div>
      <p>{order.items.length} items</p>
      <p className="font-bold">${order.total}</p>
      {order.status === 'pending' && (
        <button onClick={() => cancelMutation.mutate(orderId)}>
          Cancel Order
        </button>
      )}
    </div>
  );
}
```

**After: Container + Presentational**
```tsx
// Presentational (pure, testable)
interface OrderCardViewProps {
  order: Order;
  onCancel?: () => void;
  isCancelling?: boolean;
}

function OrderCardView({ order, onCancel, isCancelling }: OrderCardViewProps) {
  const statusColor = getStatusColor(order.status);

  return (
    <div className="p-4 border rounded">
      <div className="flex justify-between">
        <h3>{order.id}</h3>
        <StatusBadge status={order.status} color={statusColor} />
      </div>
      <p>{order.items.length} items</p>
      <p className="font-bold">${order.total}</p>
      {order.status === 'pending' && onCancel && (
        <button onClick={onCancel} disabled={isCancelling}>
          {isCancelling ? 'Cancelling...' : 'Cancel Order'}
        </button>
      )}
    </div>
  );
}

// Container (data fetching)
function OrderCard({ orderId }: { orderId: string }) {
  const { data: order, isLoading } = useQuery(['order', orderId], fetchOrder);
  const cancelMutation = useMutation(cancelOrder);

  if (isLoading) return <OrderCardSkeleton />;

  return (
    <OrderCardView
      order={order}
      onCancel={() => cancelMutation.mutate(orderId)}
      isCancelling={cancelMutation.isLoading}
    />
  );
}
```

### Extract State to Context/Store

**Before: Prop drilling**
```tsx
function App() {
  const [user, setUser] = useState<User | null>(null);

  return (
    <Layout user={user}>
      <Sidebar user={user} />
      <Main user={user} setUser={setUser}>
        <Profile user={user} setUser={setUser} />
      </Main>
    </Layout>
  );
}
```

**After: Context**
```tsx
// context/AuthContext.tsx
interface AuthContextType {
  user: User | null;
  login: (credentials: Credentials) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = async (credentials: Credentials) => {
    const user = await authApi.login(credentials);
    setUser(user);
  };

  const logout = () => {
    authApi.logout();
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be within AuthProvider');
  return context;
}

// Components use hook
function Profile() {
  const { user, logout } = useAuth();
  // ...
}
```

## Code Smell Detection

| Smell | Detection | Refactor |
|-------|-----------|----------|
| Long method (>30 lines) | Line count | Extract method |
| Fat controller | Many responsibilities | Extract action/service |
| God class | Too many dependencies | Split into focused classes |
| Primitive obsession | Repeated validation | Value object/DTO |
| Feature envy | Method uses other object's data | Move method |
| Duplicate code | Similar blocks | Extract shared function |
| Prop drilling | Props passed 3+ levels | Context/store |
| Inline handlers | Functions in JSX | Extract to const/callback |

## Refactoring Checklist

- [ ] Tests pass before refactoring
- [ ] One refactor at a time
- [ ] No behavior changes
- [ ] Tests pass after refactoring
- [ ] Code review requested

## Usage

```
/refactor OrderController --extract-action
/refactor UserService --repository
/refactor src/components/Dashboard.tsx --extract-hooks
/refactor app/Models/User.php --php85
/refactor --detect-smells src/
```
