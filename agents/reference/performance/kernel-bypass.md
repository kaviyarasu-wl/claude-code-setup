# Kernel Bypass Techniques

## Overview

Kernel bypass techniques for achieving extreme I/O performance by eliminating kernel overhead. Essential for high-frequency trading, network appliances, and storage systems requiring microsecond latencies.

## Techniques Comparison

| Technique | Use Case | Latency | Throughput | Complexity |
|-----------|----------|---------|------------|------------|
| DPDK | Network I/O | ~1-2μs | 100M+ pps | High |
| io_uring | Async I/O | ~2-5μs | Very High | Medium |
| eBPF | Observability | ~1μs | Kernel speed | Medium |
| SPDK | Storage I/O | ~1μs | 10M+ IOPS | High |

---

## DPDK (Data Plane Development Kit)

### Basic Packet Processing

```c
#include <rte_eal.h>
#include <rte_ethdev.h>
#include <rte_mbuf.h>

#define RX_RING_SIZE 1024
#define TX_RING_SIZE 1024
#define NUM_MBUFS 8191
#define MBUF_CACHE_SIZE 250
#define BURST_SIZE 32

static struct rte_mempool *mbuf_pool;

int main(int argc, char *argv[]) {
    // Initialize EAL (Environment Abstraction Layer)
    int ret = rte_eal_init(argc, argv);
    if (ret < 0)
        rte_exit(EXIT_FAILURE, "EAL init failed\n");

    // Create memory pool for packet buffers
    mbuf_pool = rte_pktmbuf_pool_create(
        "MBUF_POOL",
        NUM_MBUFS,
        MBUF_CACHE_SIZE,
        0,
        RTE_MBUF_DEFAULT_BUF_SIZE,
        rte_socket_id()
    );

    // Configure port
    uint16_t port_id = 0;
    struct rte_eth_conf port_conf = {
        .rxmode = {
            .mq_mode = RTE_ETH_MQ_RX_RSS,
            .offloads = RTE_ETH_RX_OFFLOAD_CHECKSUM,
        },
        .txmode = {
            .mq_mode = RTE_ETH_MQ_TX_NONE,
            .offloads = RTE_ETH_TX_OFFLOAD_CHECKSUM,
        },
    };

    rte_eth_dev_configure(port_id, 1, 1, &port_conf);

    // Setup RX/TX queues
    rte_eth_rx_queue_setup(port_id, 0, RX_RING_SIZE,
        rte_eth_dev_socket_id(port_id), NULL, mbuf_pool);
    rte_eth_tx_queue_setup(port_id, 0, TX_RING_SIZE,
        rte_eth_dev_socket_id(port_id), NULL);

    // Start port
    rte_eth_dev_start(port_id);
    rte_eth_promiscuous_enable(port_id);

    // Main processing loop
    struct rte_mbuf *bufs[BURST_SIZE];

    while (1) {
        // Receive burst of packets
        uint16_t nb_rx = rte_eth_rx_burst(port_id, 0, bufs, BURST_SIZE);

        if (unlikely(nb_rx == 0))
            continue;

        // Process packets
        for (uint16_t i = 0; i < nb_rx; i++) {
            process_packet(bufs[i]);
        }

        // Send packets (or drop)
        uint16_t nb_tx = rte_eth_tx_burst(port_id, 0, bufs, nb_rx);

        // Free unsent packets
        for (uint16_t i = nb_tx; i < nb_rx; i++) {
            rte_pktmbuf_free(bufs[i]);
        }
    }

    return 0;
}
```

---

## io_uring (Linux 5.1+)

### Async File I/O

```c
#include <liburing.h>
#include <fcntl.h>
#include <string.h>

#define QUEUE_DEPTH 256
#define BLOCK_SIZE 4096

struct io_data {
    int fd;
    off_t offset;
    size_t len;
    char *buf;
};

int main() {
    struct io_uring ring;
    int ret;

    // Initialize io_uring
    ret = io_uring_queue_init(QUEUE_DEPTH, &ring, 0);
    if (ret < 0) {
        fprintf(stderr, "io_uring_queue_init: %s\n", strerror(-ret));
        return 1;
    }

    int fd = open("datafile", O_RDONLY | O_DIRECT);

    // Submit multiple read requests
    for (int i = 0; i < 10; i++) {
        struct io_uring_sqe *sqe = io_uring_get_sqe(&ring);

        struct io_data *data = malloc(sizeof(*data));
        posix_memalign((void**)&data->buf, BLOCK_SIZE, BLOCK_SIZE);
        data->fd = fd;
        data->offset = i * BLOCK_SIZE;
        data->len = BLOCK_SIZE;

        io_uring_prep_read(sqe, fd, data->buf, data->len, data->offset);
        io_uring_sqe_set_data(sqe, data);
    }

    // Submit all requests at once
    io_uring_submit(&ring);

    // Reap completions
    struct io_uring_cqe *cqe;
    for (int i = 0; i < 10; i++) {
        ret = io_uring_wait_cqe(&ring, &cqe);
        if (ret < 0) break;

        struct io_data *data = io_uring_cqe_get_data(cqe);

        if (cqe->res < 0) {
            fprintf(stderr, "Read failed: %s\n", strerror(-cqe->res));
        } else {
            printf("Read %d bytes at offset %ld\n", cqe->res, data->offset);
        }

        free(data->buf);
        free(data);
        io_uring_cqe_seen(&ring, cqe);
    }

    io_uring_queue_exit(&ring);
    close(fd);
    return 0;
}
```

### Registered Buffers (Zero-Copy)

```c
// Pre-register buffers for zero-copy I/O
struct iovec iovecs[NUM_BUFFERS];

for (int i = 0; i < NUM_BUFFERS; i++) {
    posix_memalign(&iovecs[i].iov_base, 4096, BUFFER_SIZE);
    iovecs[i].iov_len = BUFFER_SIZE;
}

io_uring_register_buffers(&ring, iovecs, NUM_BUFFERS);

// Use registered buffer in read
struct io_uring_sqe *sqe = io_uring_get_sqe(&ring);
io_uring_prep_read_fixed(sqe, fd, iovecs[0].iov_base, BUFFER_SIZE, 0, 0);
```

---

## eBPF (Extended Berkeley Packet Filter)

### XDP (eXpress Data Path) for Fast Packet Processing

```c
// xdp_prog.c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>

SEC("xdp")
int xdp_filter(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    // Parse Ethernet header
    struct ethhdr *eth = data;
    if ((void *)(eth + 1) > data_end)
        return XDP_PASS;

    // Only process IPv4
    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return XDP_PASS;

    // Parse IP header
    struct iphdr *ip = (void *)(eth + 1);
    if ((void *)(ip + 1) > data_end)
        return XDP_PASS;

    // Only process TCP
    if (ip->protocol != IPPROTO_TCP)
        return XDP_PASS;

    // Parse TCP header
    struct tcphdr *tcp = (void *)ip + (ip->ihl * 4);
    if ((void *)(tcp + 1) > data_end)
        return XDP_PASS;

    // Drop packets to port 8080
    if (tcp->dest == __constant_htons(8080))
        return XDP_DROP;

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
```

### Load XDP Program

```bash
# Compile eBPF program
clang -O2 -target bpf -c xdp_prog.c -o xdp_prog.o

# Load onto interface
ip link set dev eth0 xdpgeneric obj xdp_prog.o sec xdp

# Unload
ip link set dev eth0 xdpgeneric off
```

---

## Zero-Copy Techniques

### sendfile() for File-to-Socket

```c
#include <sys/sendfile.h>

ssize_t send_file(int out_fd, int in_fd, size_t count) {
    off_t offset = 0;
    return sendfile(out_fd, in_fd, &offset, count);
}
```

### splice() for Pipe-Based Zero-Copy

```c
#include <fcntl.h>

// Transfer between file descriptors via pipe
ssize_t splice_transfer(int fd_in, int fd_out, size_t len) {
    int pipefd[2];
    pipe(pipefd);

    // Move data from fd_in to pipe
    ssize_t n = splice(fd_in, NULL, pipefd[1], NULL, len,
                       SPLICE_F_MOVE | SPLICE_F_MORE);

    // Move data from pipe to fd_out
    n = splice(pipefd[0], NULL, fd_out, NULL, n,
               SPLICE_F_MOVE | SPLICE_F_MORE);

    close(pipefd[0]);
    close(pipefd[1]);
    return n;
}
```

---

## Huge Pages

### Configure Huge Pages

```bash
# Reserve 1GB huge pages at boot
echo 'vm.nr_hugepages=1024' >> /etc/sysctl.conf

# Or at runtime (2MB pages)
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# Mount hugetlbfs
mkdir /mnt/huge
mount -t hugetlbfs nodev /mnt/huge
```

### Use Huge Pages in Application

```c
#include <sys/mman.h>

void* alloc_huge_page(size_t size) {
    void *ptr = mmap(
        NULL,
        size,
        PROT_READ | PROT_WRITE,
        MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB,
        -1,
        0
    );

    if (ptr == MAP_FAILED) {
        perror("mmap huge page");
        return NULL;
    }

    return ptr;
}
```

---

## CPU Pinning

```c
#define _GNU_SOURCE
#include <sched.h>
#include <pthread.h>

void pin_thread_to_core(int core_id) {
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(core_id, &cpuset);

    pthread_t current = pthread_self();
    pthread_setaffinity_np(current, sizeof(cpuset), &cpuset);
}

// Pin network processing to isolated cores
// /etc/default/grub: GRUB_CMDLINE_LINUX="isolcpus=2,3,4,5"
```

---

## High-Frequency Trading Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Order Book  │  │  Strategy   │  │  Risk Management    │  │
│  │  (Lock-free)│  │   Engine    │  │      Engine         │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                     │             │
├─────────┼────────────────┼─────────────────────┼─────────────┤
│         │     Network Layer (DPDK)             │             │
│  ┌──────▼──────────────────▼───────────────────▼──────────┐  │
│  │              Poll Mode Driver (PMD)                    │  │
│  │         No interrupts, no syscalls                     │  │
│  └────────────────────────┬───────────────────────────────┘  │
│                           │                                  │
├───────────────────────────┼──────────────────────────────────┤
│                    Hardware (NIC)                            │
│  ┌────────────────────────▼───────────────────────────────┐  │
│  │   Mellanox/Intel NIC with RSS, HW Timestamps           │  │
│  │   Direct Memory Access (DMA) to user-space buffers     │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

Target: < 5 microsecond tick-to-trade latency
```

## Related Documentation

- For lock-free algorithms: `lock-free-algorithms.md`
- For SIMD optimization: `simd-optimization.md`
