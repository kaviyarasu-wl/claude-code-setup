# Lock-Free Algorithms

## Overview

Lock-free data structures and algorithms for high-performance concurrent systems. These patterns eliminate mutex contention and enable true parallelism in multi-core systems.

## Progress Guarantees

| Guarantee | Definition | Use Case |
|-----------|------------|----------|
| Wait-free | Every operation completes in bounded steps | Real-time systems |
| Lock-free | At least one thread makes progress | High-throughput systems |
| Obstruction-free | Progress when running in isolation | General concurrent systems |

---

## Compare-And-Swap (CAS) Fundamentals

### CAS Operation

```c
// Atomic compare-and-swap (pseudo-assembly)
bool CAS(int* addr, int expected, int desired) {
    // Atomically:
    if (*addr == expected) {
        *addr = desired;
        return true;
    }
    return false;
}
```

### CAS in Modern Languages

```cpp
// C++ std::atomic
#include <atomic>

std::atomic<int> counter{0};

void increment() {
    int expected = counter.load(std::memory_order_relaxed);
    while (!counter.compare_exchange_weak(
        expected,
        expected + 1,
        std::memory_order_release,
        std::memory_order_relaxed
    )) {
        // CAS failed, expected now contains current value
        // Loop retries with updated expected
    }
}
```

```rust
// Rust std::sync::atomic
use std::sync::atomic::{AtomicUsize, Ordering};

static COUNTER: AtomicUsize = AtomicUsize::new(0);

fn increment() {
    COUNTER.fetch_add(1, Ordering::SeqCst);
}

fn cas_increment() {
    let mut current = COUNTER.load(Ordering::Relaxed);
    loop {
        match COUNTER.compare_exchange_weak(
            current,
            current + 1,
            Ordering::Release,
            Ordering::Relaxed,
        ) {
            Ok(_) => break,
            Err(actual) => current = actual,
        }
    }
}
```

---

## Lock-Free Queue (Michael-Scott Algorithm)

```cpp
#include <atomic>
#include <memory>

template<typename T>
class LockFreeQueue {
    struct Node {
        T data;
        std::atomic<Node*> next;

        Node() : next(nullptr) {}
        Node(T value) : data(std::move(value)), next(nullptr) {}
    };

    std::atomic<Node*> head;
    std::atomic<Node*> tail;

public:
    LockFreeQueue() {
        Node* dummy = new Node();
        head.store(dummy);
        tail.store(dummy);
    }

    void enqueue(T value) {
        Node* new_node = new Node(std::move(value));

        while (true) {
            Node* last = tail.load(std::memory_order_acquire);
            Node* next = last->next.load(std::memory_order_acquire);

            if (last == tail.load(std::memory_order_acquire)) {
                if (next == nullptr) {
                    // Try to link new node at end
                    if (last->next.compare_exchange_weak(
                            next, new_node,
                            std::memory_order_release,
                            std::memory_order_relaxed)) {
                        // Success, try to update tail
                        tail.compare_exchange_strong(
                            last, new_node,
                            std::memory_order_release,
                            std::memory_order_relaxed);
                        return;
                    }
                } else {
                    // Tail was not pointing to last node, help advance it
                    tail.compare_exchange_weak(
                        last, next,
                        std::memory_order_release,
                        std::memory_order_relaxed);
                }
            }
        }
    }

    bool dequeue(T& result) {
        while (true) {
            Node* first = head.load(std::memory_order_acquire);
            Node* last = tail.load(std::memory_order_acquire);
            Node* next = first->next.load(std::memory_order_acquire);

            if (first == head.load(std::memory_order_acquire)) {
                if (first == last) {
                    if (next == nullptr) {
                        return false; // Queue is empty
                    }
                    // Tail is behind, help advance it
                    tail.compare_exchange_weak(
                        last, next,
                        std::memory_order_release,
                        std::memory_order_relaxed);
                } else {
                    result = next->data;
                    if (head.compare_exchange_weak(
                            first, next,
                            std::memory_order_release,
                            std::memory_order_relaxed)) {
                        // Successfully dequeued
                        // Note: Need safe memory reclamation (hazard pointers)
                        return true;
                    }
                }
            }
        }
    }
};
```

---

## ABA Problem and Solutions

### The Problem

```
Thread 1: Read A from location X
Thread 1: (preempted)
Thread 2: Change X from A to B
Thread 2: Change X from B to A
Thread 1: CAS(X, A, C) succeeds! (But state may have changed)
```

### Solution: Tagged Pointers

```cpp
#include <atomic>
#include <cstdint>

struct TaggedPointer {
    uintptr_t ptr : 48;  // 48-bit pointer (x86-64)
    uintptr_t tag : 16;  // 16-bit counter

    TaggedPointer(void* p = nullptr, uint16_t t = 0)
        : ptr(reinterpret_cast<uintptr_t>(p)), tag(t) {}

    void* get_ptr() const {
        return reinterpret_cast<void*>(ptr);
    }
};

static_assert(sizeof(TaggedPointer) == sizeof(uint64_t));

class LockFreeStack {
    std::atomic<TaggedPointer> top;

public:
    void push(Node* node) {
        TaggedPointer old_top = top.load(std::memory_order_relaxed);
        TaggedPointer new_top;

        do {
            node->next = static_cast<Node*>(old_top.get_ptr());
            new_top = TaggedPointer(node, old_top.tag + 1);
        } while (!top.compare_exchange_weak(
            old_top, new_top,
            std::memory_order_release,
            std::memory_order_relaxed));
    }
};
```

---

## Memory Ordering

### Ordering Levels

```cpp
// Relaxed: No ordering guarantees (only atomicity)
x.store(1, std::memory_order_relaxed);

// Release: All prior writes visible to acquiring thread
x.store(1, std::memory_order_release);

// Acquire: All subsequent reads see releasing thread's writes
int val = x.load(std::memory_order_acquire);

// Sequential Consistency: Total order across all threads
x.store(1, std::memory_order_seq_cst);
```

### Release-Acquire Pattern

```cpp
std::atomic<bool> ready{false};
int data = 0;

// Producer thread
void producer() {
    data = 42;  // Non-atomic write
    ready.store(true, std::memory_order_release);  // Release
}

// Consumer thread
void consumer() {
    while (!ready.load(std::memory_order_acquire)) {  // Acquire
        // Spin
    }
    // Guaranteed to see data == 42
    assert(data == 42);
}
```

---

## Hazard Pointers for Safe Memory Reclamation

```cpp
class HazardPointerDomain {
    static constexpr size_t MAX_HAZARD_POINTERS = 100;

    struct HazardPointer {
        std::atomic<std::thread::id> owner;
        std::atomic<void*> pointer;
    };

    HazardPointer hazard_pointers[MAX_HAZARD_POINTERS];
    std::atomic<void*> retired_list;

public:
    class Guard {
        HazardPointer* hp;
    public:
        Guard(HazardPointerDomain& domain) {
            hp = domain.acquire();
        }
        ~Guard() {
            hp->pointer.store(nullptr, std::memory_order_release);
            hp->owner.store(std::thread::id{}, std::memory_order_release);
        }

        template<typename T>
        T* protect(std::atomic<T*>& src) {
            T* ptr;
            do {
                ptr = src.load(std::memory_order_relaxed);
                hp->pointer.store(ptr, std::memory_order_release);
            } while (ptr != src.load(std::memory_order_acquire));
            return ptr;
        }
    };

    void retire(void* ptr) {
        // Add to retired list
        // Periodically scan hazard pointers and free safe nodes
    }
};
```

---

## Lock-Free Hash Map (Simplified)

```cpp
template<typename K, typename V, size_t BUCKETS = 1024>
class LockFreeHashMap {
    struct Node {
        K key;
        std::atomic<V> value;
        std::atomic<Node*> next;
    };

    std::atomic<Node*> buckets[BUCKETS];

    size_t hash(const K& key) const {
        return std::hash<K>{}(key) % BUCKETS;
    }

public:
    bool insert(const K& key, V value) {
        size_t bucket = hash(key);
        Node* new_node = new Node{key, value, nullptr};

        Node* head = buckets[bucket].load(std::memory_order_acquire);
        do {
            new_node->next.store(head, std::memory_order_relaxed);
        } while (!buckets[bucket].compare_exchange_weak(
            head, new_node,
            std::memory_order_release,
            std::memory_order_relaxed));

        return true;
    }

    std::optional<V> find(const K& key) {
        size_t bucket = hash(key);
        Node* current = buckets[bucket].load(std::memory_order_acquire);

        while (current != nullptr) {
            if (current->key == key) {
                return current->value.load(std::memory_order_acquire);
            }
            current = current->next.load(std::memory_order_acquire);
        }
        return std::nullopt;
    }
};
```

---

## Performance Considerations

| Aspect | Lock-Based | Lock-Free |
|--------|------------|-----------|
| Contention | Blocks threads | Retries with CAS |
| Priority inversion | Possible | Not possible |
| Deadlock | Possible | Not possible |
| Complexity | Lower | Higher |
| Memory overhead | Lower | Higher (hazard pointers) |
| Best for | Low contention | High contention |

## Related Documentation

- For SIMD optimization: `simd-optimization.md`
- For kernel bypass: `kernel-bypass.md`
