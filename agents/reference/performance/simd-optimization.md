# SIMD Optimization

## Overview

Single Instruction, Multiple Data (SIMD) optimization patterns for processing multiple data elements in parallel. Essential for high-performance computing, image processing, and data parsing.

## SIMD Instruction Sets

| Platform | Instruction Set | Vector Width | Key Operations |
|----------|-----------------|--------------|----------------|
| x86/x64 | SSE4.2 | 128-bit | Basic vectors |
| x86/x64 | AVX2 | 256-bit | Integer + Float |
| x86/x64 | AVX-512 | 512-bit | Advanced masking |
| ARM | NEON | 128-bit | Mobile/embedded |
| ARM | SVE | Variable | Scalable vectors |

---

## Data Alignment

### Aligned Memory Allocation

```cpp
#include <immintrin.h>
#include <cstdlib>

// Allocate 32-byte aligned memory for AVX2
void* aligned_alloc_avx(size_t size) {
    void* ptr = nullptr;
    if (posix_memalign(&ptr, 32, size) != 0) {
        return nullptr;
    }
    return ptr;
}

// C++17 aligned allocation
#include <memory>

template<typename T>
using AlignedVector = std::vector<T, std::pmr::polymorphic_allocator<T>>;

// Or use alignas
struct alignas(32) AlignedData {
    float values[8];  // Exactly one AVX register
};
```

### Alignment Checking

```cpp
bool is_aligned(const void* ptr, size_t alignment) {
    return (reinterpret_cast<uintptr_t>(ptr) & (alignment - 1)) == 0;
}

// Runtime check before SIMD operations
void process(const float* data, size_t n) {
    if (is_aligned(data, 32)) {
        process_avx(data, n);  // Use aligned loads
    } else {
        process_avx_unaligned(data, n);  // Use unaligned loads
    }
}
```

---

## AVX2 Vector Operations

### Basic Vector Math

```cpp
#include <immintrin.h>

void vector_add_avx(const float* a, const float* b, float* result, size_t n) {
    size_t i = 0;

    // Process 8 floats at a time with AVX
    for (; i + 8 <= n; i += 8) {
        __m256 va = _mm256_load_ps(&a[i]);      // Load 8 floats
        __m256 vb = _mm256_load_ps(&b[i]);      // Load 8 floats
        __m256 vr = _mm256_add_ps(va, vb);      // Add 8 pairs
        _mm256_store_ps(&result[i], vr);        // Store 8 results
    }

    // Handle remaining elements
    for (; i < n; i++) {
        result[i] = a[i] + b[i];
    }
}

// Fused multiply-add (FMA)
void fma_example(const float* a, const float* b, const float* c, float* result, size_t n) {
    for (size_t i = 0; i + 8 <= n; i += 8) {
        __m256 va = _mm256_load_ps(&a[i]);
        __m256 vb = _mm256_load_ps(&b[i]);
        __m256 vc = _mm256_load_ps(&c[i]);
        // result = a * b + c (single instruction!)
        __m256 vr = _mm256_fmadd_ps(va, vb, vc);
        _mm256_store_ps(&result[i], vr);
    }
}
```

### Horizontal Operations

```cpp
// Sum all elements in a vector
float horizontal_sum_avx(__m256 v) {
    // [a0 a1 a2 a3 a4 a5 a6 a7]
    __m128 hi = _mm256_extractf128_ps(v, 1);  // [a4 a5 a6 a7]
    __m128 lo = _mm256_castps256_ps128(v);    // [a0 a1 a2 a3]
    __m128 sum = _mm_add_ps(hi, lo);          // [a0+a4 a1+a5 a2+a6 a3+a7]
    sum = _mm_hadd_ps(sum, sum);              // [a0+a4+a1+a5 a2+a6+a3+a7 ...]
    sum = _mm_hadd_ps(sum, sum);              // [total ...]
    return _mm_cvtss_f32(sum);
}

// Find maximum
float horizontal_max_avx(__m256 v) {
    __m128 hi = _mm256_extractf128_ps(v, 1);
    __m128 lo = _mm256_castps256_ps128(v);
    __m128 max = _mm_max_ps(hi, lo);
    max = _mm_max_ps(max, _mm_shuffle_ps(max, max, _MM_SHUFFLE(1,0,3,2)));
    max = _mm_max_ps(max, _mm_shuffle_ps(max, max, _MM_SHUFFLE(2,3,0,1)));
    return _mm_cvtss_f32(max);
}
```

---

## SIMD-Friendly Data Layouts

### Array of Structures (AoS) vs Structure of Arrays (SoA)

```cpp
// BAD: Array of Structures (cache unfriendly for SIMD)
struct Particle_AoS {
    float x, y, z;
    float vx, vy, vz;
    float mass;
};
std::vector<Particle_AoS> particles_aos;

// GOOD: Structure of Arrays (SIMD friendly)
struct Particles_SoA {
    std::vector<float> x, y, z;
    std::vector<float> vx, vy, vz;
    std::vector<float> mass;
};

// Process positions with SIMD
void update_positions_soa(Particles_SoA& p, float dt, size_t n) {
    __m256 vdt = _mm256_set1_ps(dt);

    for (size_t i = 0; i + 8 <= n; i += 8) {
        // Load 8 particles' x positions and velocities
        __m256 vx = _mm256_load_ps(&p.x[i]);
        __m256 vvx = _mm256_load_ps(&p.vx[i]);

        // x = x + vx * dt
        vx = _mm256_fmadd_ps(vvx, vdt, vx);
        _mm256_store_ps(&p.x[i], vx);

        // Repeat for y, z...
    }
}
```

---

## JSON Parsing with SIMD (simdjson-style)

```cpp
// Find quote characters in 64 bytes at once
uint64_t find_quotes_avx2(const char* input) {
    __m256i chunk1 = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(input));
    __m256i chunk2 = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(input + 32));

    __m256i quote = _mm256_set1_epi8('"');

    __m256i cmp1 = _mm256_cmpeq_epi8(chunk1, quote);
    __m256i cmp2 = _mm256_cmpeq_epi8(chunk2, quote);

    uint32_t mask1 = _mm256_movemask_epi8(cmp1);
    uint32_t mask2 = _mm256_movemask_epi8(cmp2);

    return mask1 | (static_cast<uint64_t>(mask2) << 32);
}

// Find structural characters ({}[],:)
uint64_t find_structural_avx2(const char* input) {
    __m256i chunk = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(input));

    __m256i open_brace = _mm256_set1_epi8('{');
    __m256i close_brace = _mm256_set1_epi8('}');
    __m256i open_bracket = _mm256_set1_epi8('[');
    __m256i close_bracket = _mm256_set1_epi8(']');
    __m256i colon = _mm256_set1_epi8(':');
    __m256i comma = _mm256_set1_epi8(',');

    __m256i result = _mm256_cmpeq_epi8(chunk, open_brace);
    result = _mm256_or_si256(result, _mm256_cmpeq_epi8(chunk, close_brace));
    result = _mm256_or_si256(result, _mm256_cmpeq_epi8(chunk, open_bracket));
    result = _mm256_or_si256(result, _mm256_cmpeq_epi8(chunk, close_bracket));
    result = _mm256_or_si256(result, _mm256_cmpeq_epi8(chunk, colon));
    result = _mm256_or_si256(result, _mm256_cmpeq_epi8(chunk, comma));

    return _mm256_movemask_epi8(result);
}
```

---

## Compiler Auto-Vectorization

### Hints for Auto-Vectorization

```cpp
// Tell compiler about alignment
void process(float* __restrict__ a, float* __restrict__ b, float* __restrict__ c, size_t n) {
    a = static_cast<float*>(__builtin_assume_aligned(a, 32));
    b = static_cast<float*>(__builtin_assume_aligned(b, 32));
    c = static_cast<float*>(__builtin_assume_aligned(c, 32));

    #pragma omp simd
    for (size_t i = 0; i < n; i++) {
        c[i] = a[i] + b[i];
    }
}

// GCC/Clang optimization pragmas
#pragma GCC optimize("O3,unroll-loops")
#pragma clang loop vectorize(enable) interleave(enable)
```

### Compiler Flags

```bash
# GCC/Clang
-O3 -march=native -mavx2 -mfma -funroll-loops

# Check what SIMD is used
-fopt-info-vec-optimized  # GCC
-Rpass=loop-vectorize     # Clang
```

---

## Performance Comparison

| Operation | Scalar | SSE4 (4x) | AVX2 (8x) | AVX-512 (16x) |
|-----------|--------|-----------|-----------|---------------|
| Float add | 1x | 4x | 8x | 16x |
| Memory bound | 1x | ~2x | ~3x | ~4x |
| Practical | 1x | 2-3x | 4-6x | 6-10x |

## Related Documentation

- For lock-free algorithms: `lock-free-algorithms.md`
- For kernel bypass: `kernel-bypass.md`
