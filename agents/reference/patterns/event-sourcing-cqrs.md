# Event Sourcing & CQRS Implementation

## Overview

Complete production-ready Event Sourcing with CQRS (Command Query Responsibility Segregation) pattern implementation.

## Core Concepts

- **Event Store**: Append-only log of domain events
- **Aggregates**: Domain objects rebuilt from events
- **Projections**: Read-optimized views built from events
- **Commands**: Intentions that produce events
- **Queries**: Read operations against projections

## Event Store Implementation

```typescript
// Complete Event Sourcing + CQRS System
interface DomainEvent {
  aggregateId: string;
  eventType: string;
  eventData: any;
  eventVersion: number;
  timestamp: Date;
  userId: string;
  metadata: Record<string, any>;
}

// Event Store Implementation
class EventStore {
  constructor(
    private postgres: PostgresClient,
    private kafka: KafkaProducer,
    private s3: S3Client
  ) {}

  async append(events: DomainEvent[]): Promise<void> {
    // Begin transaction for consistency
    const client = await this.postgres.getClient();

    try {
      await client.query('BEGIN');

      // Store events in PostgreSQL
      for (const event of events) {
        await client.query(`
          INSERT INTO event_store (
            aggregate_id, event_type, event_data, event_version,
            timestamp, user_id, metadata
          ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        `, [
          event.aggregateId,
          event.eventType,
          JSON.stringify(event.eventData),
          event.eventVersion,
          event.timestamp,
          event.userId,
          JSON.stringify(event.metadata)
        ]);

        // Update aggregate version
        await client.query(`
          INSERT INTO aggregate_versions (aggregate_id, version)
          VALUES ($1, $2)
          ON CONFLICT (aggregate_id)
          DO UPDATE SET version = $2
        `, [event.aggregateId, event.eventVersion]);
      }

      await client.query('COMMIT');

      // Publish to Kafka for projections
      for (const event of events) {
        await this.kafka.send({
          topic: `events.${event.eventType}`,
          messages: [{
            key: event.aggregateId,
            value: JSON.stringify(event),
            headers: {
              'event-type': event.eventType,
              'aggregate-id': event.aggregateId,
              'timestamp': event.timestamp.toISOString()
            }
          }]
        });
      }

      // Archive to S3 for long-term storage
      if (events.length > 100) {
        await this.archiveEvents(events);
      }

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getEvents(
    aggregateId: string,
    fromVersion?: number,
    toVersion?: number
  ): Promise<DomainEvent[]> {
    const query = `
      SELECT * FROM event_store
      WHERE aggregate_id = $1
      ${fromVersion ? 'AND event_version >= $2' : ''}
      ${toVersion ? 'AND event_version <= $3' : ''}
      ORDER BY event_version ASC
    `;

    const params = [aggregateId];
    if (fromVersion) params.push(fromVersion);
    if (toVersion) params.push(toVersion);

    const result = await this.postgres.query(query, params);

    return result.rows.map(row => ({
      aggregateId: row.aggregate_id,
      eventType: row.event_type,
      eventData: row.event_data,
      eventVersion: row.event_version,
      timestamp: row.timestamp,
      userId: row.user_id,
      metadata: row.metadata
    }));
  }

  // Snapshot support for performance
  async createSnapshot(aggregateId: string, state: any): Promise<void> {
    const snapshot = {
      aggregateId,
      state: JSON.stringify(state),
      version: state.version,
      timestamp: new Date()
    };

    await this.postgres.query(`
      INSERT INTO snapshots (aggregate_id, state, version, timestamp)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (aggregate_id)
      DO UPDATE SET state = $2, version = $3, timestamp = $4
    `, [snapshot.aggregateId, snapshot.state, snapshot.version, snapshot.timestamp]);
  }
}
```

## Aggregate Root Pattern

```typescript
// Aggregate Root with Event Sourcing
abstract class AggregateRoot {
  protected events: DomainEvent[] = [];
  protected version: number = 0;

  constructor(protected id: string) {}

  protected apply(event: DomainEvent): void {
    this.events.push(event);
    this.version = event.eventVersion;
    this.when(event);
  }

  protected abstract when(event: DomainEvent): void;

  getUncommittedEvents(): DomainEvent[] {
    return this.events;
  }

  markEventsAsCommitted(): void {
    this.events = [];
  }

  loadFromHistory(events: DomainEvent[]): void {
    events.forEach(event => this.when(event));
    this.version = events[events.length - 1]?.eventVersion || 0;
  }
}

// Example: Order Aggregate
class OrderAggregate extends AggregateRoot {
  private status: OrderStatus = 'pending';
  private items: OrderItem[] = [];
  private totalAmount: number = 0;
  private customerId: string = '';

  static create(orderId: string, customerId: string, items: OrderItem[]): OrderAggregate {
    const order = new OrderAggregate(orderId);

    order.apply({
      aggregateId: orderId,
      eventType: 'OrderCreated',
      eventData: { customerId, items },
      eventVersion: 1,
      timestamp: new Date(),
      userId: customerId,
      metadata: {}
    });

    return order;
  }

  ship(shippingAddress: Address): void {
    if (this.status !== 'paid') {
      throw new Error('Cannot ship unpaid order');
    }

    this.apply({
      aggregateId: this.id,
      eventType: 'OrderShipped',
      eventData: { shippingAddress },
      eventVersion: this.version + 1,
      timestamp: new Date(),
      userId: 'system',
      metadata: {}
    });
  }

  protected when(event: DomainEvent): void {
    switch (event.eventType) {
      case 'OrderCreated':
        this.status = 'pending';
        this.customerId = event.eventData.customerId;
        this.items = event.eventData.items;
        this.totalAmount = this.calculateTotal();
        break;

      case 'OrderPaid':
        this.status = 'paid';
        break;

      case 'OrderShipped':
        this.status = 'shipped';
        break;

      case 'OrderDelivered':
        this.status = 'delivered';
        break;
    }
  }
}
```

## Command Handler (CQRS Write Side)

```typescript
// CQRS Command Handler
class OrderCommandHandler {
  constructor(
    private eventStore: EventStore,
    private repository: OrderRepository
  ) {}

  async handle(command: Command): Promise<void> {
    switch (command.type) {
      case 'CreateOrder':
        await this.createOrder(command);
        break;
      case 'ShipOrder':
        await this.shipOrder(command);
        break;
      case 'CancelOrder':
        await this.cancelOrder(command);
        break;
    }
  }

  private async createOrder(command: CreateOrderCommand): Promise<void> {
    // Load aggregate
    const order = OrderAggregate.create(
      command.orderId,
      command.customerId,
      command.items
    );

    // Apply business logic
    if (command.coupon) {
      order.applyCoupon(command.coupon);
    }

    // Store events
    await this.eventStore.append(order.getUncommittedEvents());

    // Update read model asynchronously
    await this.publishToProjection(order.getUncommittedEvents());
  }

  private async shipOrder(command: ShipOrderCommand): Promise<void> {
    // Load aggregate from event store
    const events = await this.eventStore.getEvents(command.orderId);
    const order = new OrderAggregate(command.orderId);
    order.loadFromHistory(events);

    // Apply command
    order.ship(command.shippingAddress);

    // Store new events
    await this.eventStore.append(order.getUncommittedEvents());
  }
}
```

## Query Handler (CQRS Read Side)

```typescript
// CQRS Query Handler with Read Model
class OrderQueryHandler {
  constructor(
    private readDb: PostgresClient,
    private cache: RedisClient,
    private elasticsearch: ElasticsearchClient
  ) {}

  async getOrder(orderId: string): Promise<OrderReadModel> {
    // Check cache first
    const cached = await this.cache.get(`order:${orderId}`);
    if (cached) return JSON.parse(cached);

    // Query read model
    const result = await this.readDb.query(
      'SELECT * FROM order_projections WHERE id = $1',
      [orderId]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('Order not found');
    }

    const order = result.rows[0];

    // Cache for future queries
    await this.cache.setex(
      `order:${orderId}`,
      300,
      JSON.stringify(order)
    );

    return order;
  }

  async searchOrders(criteria: SearchCriteria): Promise<OrderReadModel[]> {
    // Use Elasticsearch for complex searches
    const response = await this.elasticsearch.search({
      index: 'orders',
      body: {
        query: {
          bool: {
            must: [
              criteria.customerId && { term: { customerId: criteria.customerId } },
              criteria.status && { term: { status: criteria.status } },
              criteria.dateRange && {
                range: {
                  createdAt: {
                    gte: criteria.dateRange.from,
                    lte: criteria.dateRange.to
                  }
                }
              }
            ].filter(Boolean)
          }
        },
        sort: [{ createdAt: 'desc' }],
        size: criteria.limit || 20,
        from: criteria.offset || 0
      }
    });

    return response.hits.hits.map(hit => hit._source);
  }
}
```

## Projection Builder

```typescript
// Projection Builder for Read Model
class OrderProjectionBuilder {
  constructor(
    private kafka: KafkaConsumer,
    private readDb: PostgresClient,
    private elasticsearch: ElasticsearchClient
  ) {
    this.subscribeToEvents();
  }

  private async subscribeToEvents() {
    await this.kafka.subscribe({
      topics: ['events.OrderCreated', 'events.OrderShipped', 'events.OrderDelivered'],
      fromBeginning: false
    });

    await this.kafka.run({
      eachMessage: async ({ topic, message }) => {
        const event = JSON.parse(message.value.toString());
        await this.projectEvent(event);
      }
    });
  }

  private async projectEvent(event: DomainEvent) {
    switch (event.eventType) {
      case 'OrderCreated':
        await this.projectOrderCreated(event);
        break;
      case 'OrderShipped':
        await this.projectOrderShipped(event);
        break;
      case 'OrderDelivered':
        await this.projectOrderDelivered(event);
        break;
    }

    // Update Elasticsearch
    await this.updateSearchIndex(event);
  }

  private async projectOrderCreated(event: DomainEvent) {
    await this.readDb.query(`
      INSERT INTO order_projections (
        id, customer_id, items, total_amount, status, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6)
    `, [
      event.aggregateId,
      event.eventData.customerId,
      JSON.stringify(event.eventData.items),
      event.eventData.totalAmount,
      'pending',
      event.timestamp
    ]);
  }
}
```

## Database Schema

```sql
-- Event Store
CREATE TABLE event_store (
    id BIGSERIAL PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    event_data JSONB NOT NULL,
    event_version INTEGER NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id VARCHAR(255),
    metadata JSONB,
    UNIQUE(aggregate_id, event_version)
);

CREATE INDEX idx_event_store_aggregate ON event_store(aggregate_id, event_version);
CREATE INDEX idx_event_store_type ON event_store(event_type);
CREATE INDEX idx_event_store_timestamp ON event_store(timestamp);

-- Aggregate Versions (for optimistic concurrency)
CREATE TABLE aggregate_versions (
    aggregate_id UUID PRIMARY KEY,
    version INTEGER NOT NULL
);

-- Snapshots
CREATE TABLE snapshots (
    aggregate_id UUID PRIMARY KEY,
    state JSONB NOT NULL,
    version INTEGER NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL
);

-- Read Model Projections
CREATE TABLE order_projections (
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    items JSONB NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_customer ON order_projections(customer_id);
CREATE INDEX idx_orders_status ON order_projections(status);
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Command Side                            │
├─────────────────────────────────────────────────────────────┤
│  API Request  →  Command Handler  →  Aggregate  →  Events   │
│                        ↓                              ↓     │
│              Validation/Auth                    Event Store  │
└─────────────────────────────────────────────────────────────┘
                                                      ↓ Kafka
┌─────────────────────────────────────────────────────────────┐
│                      Query Side                              │
├─────────────────────────────────────────────────────────────┤
│  API Request  →  Query Handler  →  Read Model / Cache       │
│                        ↑                                     │
│              Projection Builder  ←  Event Consumer           │
└─────────────────────────────────────────────────────────────┘
```
