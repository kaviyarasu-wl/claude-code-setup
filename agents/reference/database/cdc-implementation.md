# Change Data Capture (CDC) Implementation

## Overview

Change Data Capture patterns for capturing database changes in real-time. Covers Debezium configuration, the transactional outbox pattern, and schema evolution strategies.

## CDC Approaches Comparison

| Approach | Latency | Impact on DB | Consistency | Complexity |
|----------|---------|--------------|-------------|------------|
| Log-based (Debezium) | Low | Minimal | Strong | Medium |
| Trigger-based | Medium | High | Strong | Low |
| Polling | High | Medium | Eventual | Low |
| Timestamp-based | Medium | Low | Eventual | Low |

---

## Debezium with PostgreSQL

### Kafka Connect Configuration

```json
{
  "name": "postgres-cdc-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres.example.com",
    "database.port": "5432",
    "database.user": "debezium",
    "database.password": "${file:/secrets/db-password.txt}",
    "database.dbname": "mydb",
    "database.server.name": "mydb-server",
    "plugin.name": "pgoutput",
    "slot.name": "debezium_slot",
    "publication.name": "debezium_publication",

    "table.include.list": "public.orders,public.customers,public.products",
    "column.exclude.list": "public.customers.password_hash,public.customers.ssn",

    "transforms": "unwrap,route",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.delete.handling.mode": "rewrite",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.route.regex": "([^.]+)\\.([^.]+)\\.([^.]+)",
    "transforms.route.replacement": "$3-events",

    "snapshot.mode": "initial",
    "snapshot.locking.mode": "none",

    "heartbeat.interval.ms": "10000",
    "heartbeat.action.query": "INSERT INTO debezium_heartbeat (ts) VALUES (NOW()) ON CONFLICT (id) DO UPDATE SET ts = NOW()",

    "errors.tolerance": "all",
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "errors.deadletterqueue.topic.name": "cdc-dlq",

    "topic.creation.default.replication.factor": "3",
    "topic.creation.default.partitions": "10"
  }
}
```

### PostgreSQL Setup

```sql
-- Create dedicated CDC user with minimal permissions
CREATE USER debezium WITH REPLICATION LOGIN PASSWORD 'secure-password';

-- Grant necessary permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium;
GRANT USAGE ON SCHEMA public TO debezium;

-- Create publication for CDC
CREATE PUBLICATION debezium_publication FOR TABLE
    orders,
    customers,
    products,
    order_items
WITH (publish = 'insert, update, delete');

-- Create replication slot
SELECT pg_create_logical_replication_slot('debezium_slot', 'pgoutput');

-- Heartbeat table for monitoring
CREATE TABLE debezium_heartbeat (
    id INTEGER PRIMARY KEY DEFAULT 1,
    ts TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO debezium_heartbeat (id, ts) VALUES (1, NOW());
```

---

## Transactional Outbox Pattern

### Outbox Table Schema

```sql
CREATE TABLE outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    INDEX idx_outbox_unprocessed (processed_at) WHERE processed_at IS NULL
);

-- Debezium will capture changes to this table
ALTER TABLE outbox REPLICA IDENTITY FULL;
```

### Application Code

```typescript
class OrderService {
  async createOrder(data: CreateOrderDTO): Promise<Order> {
    return await this.db.transaction(async (trx) => {
      // Create the order
      const order = await trx.insert('orders', {
        customer_id: data.customerId,
        status: 'pending',
        total_amount: data.totalAmount,
      });

      // Insert items
      await trx.insert('order_items', data.items.map(item => ({
        order_id: order.id,
        product_id: item.productId,
        quantity: item.quantity,
        price: item.price,
      })));

      // Write to outbox (same transaction!)
      await trx.insert('outbox', {
        aggregate_type: 'Order',
        aggregate_id: order.id,
        event_type: 'OrderCreated',
        payload: {
          orderId: order.id,
          customerId: data.customerId,
          items: data.items,
          totalAmount: data.totalAmount,
          createdAt: new Date(),
        },
      });

      return order;
    });
  }
}
```

### Debezium Outbox Router

```json
{
  "transforms": "outbox",
  "transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",
  "transforms.outbox.table.field.event.key": "aggregate_id",
  "transforms.outbox.table.field.event.type": "event_type",
  "transforms.outbox.table.field.event.payload": "payload",
  "transforms.outbox.route.by.field": "aggregate_type",
  "transforms.outbox.route.topic.replacement": "${routedByValue}-events"
}
```

---

## Schema Evolution Handling

### Avro Schema Registry

```typescript
import { SchemaRegistry } from '@kafkajs/confluent-schema-registry';

const registry = new SchemaRegistry({
  host: 'http://schema-registry:8081',
});

// Register schema with compatibility check
async function registerSchema(subject: string, schema: object) {
  const id = await registry.register({
    type: 'AVRO',
    schema: JSON.stringify(schema),
  }, {
    subject,
    compatibility: 'BACKWARD', // New schema can read old data
  });
  return id;
}

// Decode message with automatic schema resolution
async function decodeMessage(buffer: Buffer) {
  const decoded = await registry.decode(buffer);
  return decoded;
}
```

### Schema Evolution Rules

```yaml
# BACKWARD compatible changes (safe):
- Add optional field with default
- Remove field
- Add new enum value at end

# FORWARD compatible changes:
- Add required field with default
- Remove optional field

# BREAKING changes (avoid):
- Rename field
- Change field type
- Remove required field without default
```

---

## CDC Event Consumer

```typescript
interface CDCEvent<T> {
  before: T | null;  // Previous state (null for inserts)
  after: T | null;   // New state (null for deletes)
  source: {
    version: string;
    connector: string;
    name: string;
    ts_ms: number;
    db: string;
    schema: string;
    table: string;
  };
  op: 'c' | 'u' | 'd' | 'r';  // create, update, delete, read (snapshot)
  ts_ms: number;
}

class CDCConsumer {
  async processEvent<T>(event: CDCEvent<T>) {
    switch (event.op) {
      case 'c': // INSERT
        await this.handleInsert(event.after!);
        break;

      case 'u': // UPDATE
        await this.handleUpdate(event.before!, event.after!);
        break;

      case 'd': // DELETE
        await this.handleDelete(event.before!);
        break;

      case 'r': // SNAPSHOT READ
        await this.handleSnapshot(event.after!);
        break;
    }

    // Track processing lag
    const lag = Date.now() - event.ts_ms;
    metrics.cdcLag.observe(lag);
  }
}
```

---

## Monitoring CDC Health

```yaml
# Prometheus alerts for CDC
groups:
  - name: cdc-alerts
    rules:
      - alert: CDCReplicationLag
        expr: debezium_postgres_replication_lag_seconds > 30
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CDC replication lag is high"

      - alert: CDCConnectorDown
        expr: kafka_connect_connector_state{connector=~".*-cdc-.*"} != 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "CDC connector is not running"

      - alert: CDCSlotInactive
        expr: pg_replication_slots_active{slot_name="debezium_slot"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Debezium replication slot is inactive"
```

---

## Best Practices

1. **Use log-based CDC** for minimal database impact
2. **Enable heartbeats** to detect stuck connectors
3. **Configure dead letter queues** for failed events
4. **Monitor replication slot growth** to prevent disk exhaustion
5. **Test schema evolution** before deploying changes
6. **Use transactional outbox** for guaranteed delivery

## Related Documentation

- For stream processing: `stream-processing.md`
- For global distribution: `global-distribution.md`
