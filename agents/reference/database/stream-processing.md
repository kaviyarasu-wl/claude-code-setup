# Stream Processing Patterns

## Overview

Event streaming and distributed transaction patterns using Apache Kafka, the Saga pattern, and event-driven microservices architecture.

## Kafka Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Producer   │───>│   Kafka     │───>│  Consumer   │
│  Service    │    │   Cluster   │    │  Group      │
└─────────────┘    └─────────────┘    └─────────────┘
                          │
                   ┌──────┴──────┐
                   │             │
              ┌────┴────┐   ┌────┴────┐
              │ Topic A │   │ Topic B │
              │ P0 P1 P2│   │ P0 P1   │
              └─────────┘   └─────────┘
```

---

## Saga Pattern for Distributed Transactions

### Saga Orchestrator

```typescript
class OrderSaga {
  private steps: SagaStep[] = [];
  private executedSteps: SagaStep[] = [];

  constructor(private orderId: string) {}

  addStep(execute: () => Promise<void>, compensate: () => Promise<void>) {
    this.steps.push({ execute, compensate });
  }

  async execute(): Promise<void> {
    for (const step of this.steps) {
      try {
        await step.execute();
        this.executedSteps.push(step);
      } catch (error) {
        await this.compensate();
        throw error;
      }
    }
  }

  async compensate(): Promise<void> {
    // Execute compensations in reverse order
    for (const step of this.executedSteps.reverse()) {
      try {
        await step.compensate();
      } catch (error) {
        console.error('Compensation failed:', error);
        // Log for manual intervention
      }
    }
  }
}
```

### Order Processing with Saga

```typescript
@Injectable()
export class OrderService {
  constructor(
    private readonly db: DatabaseService,
    private readonly kafka: KafkaService,
    private readonly inventory: InventoryService,
    private readonly payment: PaymentService,
    private readonly notification: NotificationService,
  ) {}

  @EventPattern('order.create')
  async handleOrderCreation(@Payload() data: CreateOrderDTO) {
    const saga = new OrderSaga(data.orderId);

    try {
      // Step 1: Reserve inventory
      saga.addStep(
        () => this.inventory.reserve(data.items),
        () => this.inventory.release(data.items)
      );

      // Step 2: Process payment
      saga.addStep(
        () => this.payment.charge(data.payment),
        () => this.payment.refund(data.payment)
      );

      // Step 3: Create order record
      saga.addStep(
        () => this.createOrder(data),
        () => this.cancelOrder(data.orderId)
      );

      // Step 4: Send notifications
      saga.addStep(
        () => this.notification.sendOrderConfirmation(data),
        () => Promise.resolve() // No compensation needed
      );

      await saga.execute();

      // Publish success event
      await this.kafka.emit('order.completed', {
        orderId: data.orderId,
        status: 'success',
        timestamp: new Date()
      });

    } catch (error) {
      // Saga automatically compensates on failure
      await this.kafka.emit('order.failed', {
        orderId: data.orderId,
        error: error.message,
        timestamp: new Date()
      });

      throw error;
    }
  }
}
```

---

## Kafka Producer Configuration

```typescript
import { Kafka, Partitioners, CompressionTypes } from 'kafkajs';

const kafka = new Kafka({
  clientId: 'my-app',
  brokers: ['kafka-1:9092', 'kafka-2:9092', 'kafka-3:9092'],
  ssl: true,
  sasl: {
    mechanism: 'scram-sha-512',
    username: process.env.KAFKA_USERNAME!,
    password: process.env.KAFKA_PASSWORD!,
  },
  retry: {
    initialRetryTime: 100,
    retries: 8,
    maxRetryTime: 30000,
  },
});

const producer = kafka.producer({
  createPartitioner: Partitioners.DefaultPartitioner,
  idempotent: true, // Exactly-once semantics
  transactionalId: 'my-transactional-producer',
  maxInFlightRequests: 5,
});

// Transactional send
async function sendTransactional(messages: Message[]) {
  const transaction = await producer.transaction();

  try {
    await transaction.send({
      topic: 'orders',
      messages,
      compression: CompressionTypes.GZIP,
    });

    await transaction.commit();
  } catch (error) {
    await transaction.abort();
    throw error;
  }
}
```

---

## Kafka Consumer with Exactly-Once Processing

```typescript
const consumer = kafka.consumer({
  groupId: 'order-processor',
  sessionTimeout: 30000,
  heartbeatInterval: 3000,
  maxBytesPerPartition: 1048576, // 1MB
  maxWaitTimeInMs: 5000,
});

await consumer.subscribe({
  topics: ['orders', 'payments'],
  fromBeginning: false,
});

await consumer.run({
  autoCommit: false, // Manual commit for exactly-once
  eachMessage: async ({ topic, partition, message }) => {
    const key = message.key?.toString();
    const value = JSON.parse(message.value!.toString());

    try {
      // Process message
      await processMessage(topic, value);

      // Commit offset after successful processing
      await consumer.commitOffsets([{
        topic,
        partition,
        offset: (BigInt(message.offset) + 1n).toString(),
      }]);

    } catch (error) {
      // Dead letter queue for failed messages
      await producer.send({
        topic: `${topic}.dlq`,
        messages: [{
          key,
          value: JSON.stringify({
            originalMessage: value,
            error: error.message,
            timestamp: new Date(),
          }),
        }],
      });
    }
  },
});
```

---

## Windowing Strategies

### Tumbling Window (Fixed, Non-Overlapping)

```typescript
class TumblingWindow<T> {
  private buffer: T[] = [];
  private windowStart: number;

  constructor(
    private windowSize: number, // milliseconds
    private onWindowClose: (items: T[]) => void
  ) {
    this.windowStart = Date.now();
    this.startTimer();
  }

  add(item: T) {
    this.buffer.push(item);
  }

  private startTimer() {
    setInterval(() => {
      if (this.buffer.length > 0) {
        this.onWindowClose([...this.buffer]);
        this.buffer = [];
      }
      this.windowStart = Date.now();
    }, this.windowSize);
  }
}

// Usage: Aggregate orders every 5 minutes
const orderWindow = new TumblingWindow<Order>(5 * 60 * 1000, (orders) => {
  const summary = {
    count: orders.length,
    totalAmount: orders.reduce((sum, o) => sum + o.amount, 0),
    averageAmount: orders.reduce((sum, o) => sum + o.amount, 0) / orders.length,
  };
  publishMetrics(summary);
});
```

### Sliding Window

```typescript
class SlidingWindow<T> {
  private events: Array<{ item: T; timestamp: number }> = [];

  constructor(
    private windowSize: number, // milliseconds
    private slideInterval: number
  ) {
    setInterval(() => this.cleanup(), this.slideInterval);
  }

  add(item: T) {
    this.events.push({ item, timestamp: Date.now() });
  }

  getWindow(): T[] {
    const cutoff = Date.now() - this.windowSize;
    return this.events
      .filter(e => e.timestamp >= cutoff)
      .map(e => e.item);
  }

  private cleanup() {
    const cutoff = Date.now() - this.windowSize;
    this.events = this.events.filter(e => e.timestamp >= cutoff);
  }
}
```

### Session Window

```typescript
class SessionWindow<T> {
  private sessions: Map<string, { items: T[]; lastActivity: number }> = new Map();

  constructor(
    private timeout: number, // Inactivity timeout in ms
    private onSessionClose: (sessionId: string, items: T[]) => void
  ) {
    setInterval(() => this.checkTimeouts(), 1000);
  }

  add(sessionId: string, item: T) {
    const session = this.sessions.get(sessionId) || { items: [], lastActivity: 0 };
    session.items.push(item);
    session.lastActivity = Date.now();
    this.sessions.set(sessionId, session);
  }

  private checkTimeouts() {
    const now = Date.now();
    for (const [sessionId, session] of this.sessions) {
      if (now - session.lastActivity > this.timeout) {
        this.onSessionClose(sessionId, session.items);
        this.sessions.delete(sessionId);
      }
    }
  }
}
```

---

## Event Schema with Avro

```json
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.company.events",
  "fields": [
    {"name": "eventId", "type": "string"},
    {"name": "eventType", "type": {"type": "enum", "name": "OrderEventType",
      "symbols": ["CREATED", "CONFIRMED", "SHIPPED", "DELIVERED", "CANCELLED"]}},
    {"name": "orderId", "type": "string"},
    {"name": "customerId", "type": "string"},
    {"name": "items", "type": {"type": "array", "items": {
      "type": "record", "name": "OrderItem", "fields": [
        {"name": "productId", "type": "string"},
        {"name": "quantity", "type": "int"},
        {"name": "price", "type": {"type": "bytes", "logicalType": "decimal", "precision": 10, "scale": 2}}
      ]}}},
    {"name": "totalAmount", "type": {"type": "bytes", "logicalType": "decimal", "precision": 10, "scale": 2}},
    {"name": "timestamp", "type": {"type": "long", "logicalType": "timestamp-millis"}},
    {"name": "metadata", "type": {"type": "map", "values": "string"}, "default": {}}
  ]
}
```

---

## Key Patterns Summary

| Pattern | Use Case | Guarantee |
|---------|----------|-----------|
| Saga | Distributed transactions | Eventual consistency |
| Transactional Outbox | Reliable event publishing | At-least-once |
| Idempotent Consumer | Duplicate handling | Exactly-once |
| Tumbling Window | Fixed-interval aggregation | Complete windows |
| Session Window | User activity grouping | Activity-based |

## Related Documentation

- For change data capture: `cdc-implementation.md`
- For event sourcing: `../patterns/event-sourcing-cqrs.md`
