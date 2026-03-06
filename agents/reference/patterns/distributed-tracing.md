# Distributed Tracing & Observability

## Overview

Advanced observability system with OpenTelemetry tracing, Prometheus metrics, and structured logging for distributed systems.

## Key Technologies

- **OpenTelemetry**: Distributed tracing standard
- **Prometheus**: Metrics collection and alerting
- **Jaeger**: Trace visualization
- **Elasticsearch**: Log aggregation

## Implementation

```typescript
// Advanced Observability System
import { trace, context, SpanStatusCode } from '@opentelemetry/api';
import { PrometheusExporter } from '@opentelemetry/exporter-prometheus';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';

class ObservabilityService {
  private tracer = trace.getTracer('app-tracer');
  private metrics = new MetricsCollector();

  // Distributed tracing wrapper
  async traceOperation<T>(
    name: string,
    operation: () => Promise<T>,
    attributes?: Record<string, any>
  ): Promise<T> {
    const span = this.tracer.startSpan(name, {
      attributes: {
        ...attributes,
        'service.name': process.env.SERVICE_NAME,
        'deployment.environment': process.env.ENV
      }
    });

    // Add baggage for cross-service correlation
    const baggage = propagation.getBaggage(context.active());
    if (baggage) {
      span.setAttributes(Object.fromEntries(baggage.getAllEntries()));
    }

    try {
      // Record start metrics
      this.metrics.increment(`operation.${name}.started`);
      const timer = this.metrics.startTimer(`operation.${name}.duration`);

      // Execute operation with context
      const result = await context.with(
        trace.setSpan(context.active(), span),
        operation
      );

      // Record success
      span.setStatus({ code: SpanStatusCode.OK });
      this.metrics.increment(`operation.${name}.success`);
      timer.end();

      return result;

    } catch (error) {
      // Record error
      span.recordException(error);
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message
      });

      this.metrics.increment(`operation.${name}.error`);
      this.metrics.increment(`error.${error.constructor.name}`);

      // Send to error tracking
      await this.sendToSentry(error, span);

      throw error;

    } finally {
      span.end();
    }
  }
}
```

## Metrics Collector

```typescript
// Custom metrics collection
class MetricsCollector {
  private prometheus = new PrometheusRegistry();

  constructor() {
    this.setupDefaultMetrics();
    this.setupCustomMetrics();
  }

  private setupCustomMetrics() {
    // Business metrics
    this.orderValue = new Histogram({
      name: 'order_value_dollars',
      help: 'Order value in dollars',
      buckets: [10, 50, 100, 500, 1000, 5000, 10000],
      labelNames: ['product_category', 'customer_segment']
    });

    // Performance metrics
    this.apiLatency = new Histogram({
      name: 'api_latency_seconds',
      help: 'API endpoint latency',
      buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5],
      labelNames: ['method', 'endpoint', 'status_code']
    });

    // System metrics
    this.dbConnections = new Gauge({
      name: 'database_connections',
      help: 'Active database connections',
      labelNames: ['pool_name', 'state']
    });

    // Error tracking
    this.errorRate = new Counter({
      name: 'errors_total',
      help: 'Total errors',
      labelNames: ['error_type', 'severity', 'component']
    });
  }

  // Circuit breaker metrics
  trackCircuitBreaker(name: string, state: 'open' | 'closed' | 'half-open') {
    this.prometheus.gauge(`circuit_breaker_state`, {
      name,
      state
    }).set(state === 'open' ? 1 : 0);
  }

  // SLA tracking
  trackSLA(operation: string, success: boolean, duration: number) {
    const slaTarget = this.getSLATarget(operation);
    const withinSLA = duration <= slaTarget;

    this.prometheus.histogram(`sla_compliance`, {
      operation,
      within_sla: withinSLA
    }).observe(duration);

    if (!withinSLA) {
      this.alerting.send({
        severity: 'warning',
        message: `SLA breach for ${operation}: ${duration}ms > ${slaTarget}ms`
      });
    }
  }
}
```

## Structured Logging

```typescript
// Distributed logging
class StructuredLogger {
  private correlationId: string;

  log(level: LogLevel, message: string, meta?: any) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      correlationId: this.correlationId,
      traceId: trace.getSpan(context.active())?.spanContext().traceId,
      spanId: trace.getSpan(context.active())?.spanContext().spanId,
      service: process.env.SERVICE_NAME,
      environment: process.env.ENV,
      ...meta
    };

    // Send to multiple destinations
    this.sendToElasticsearch(logEntry);
    this.sendToCloudWatch(logEntry);
    this.sendToKafka(logEntry);

    // Alert on errors
    if (level === 'error' || level === 'fatal') {
      this.alerting.sendAlert(logEntry);
    }
  }
}
```

## Key Metrics to Track

| Category | Metric | Type | Labels |
|----------|--------|------|--------|
| Latency | api_latency_seconds | Histogram | method, endpoint, status |
| Throughput | requests_total | Counter | method, endpoint |
| Errors | errors_total | Counter | type, severity, component |
| Saturation | db_connections | Gauge | pool, state |
| Business | order_value | Histogram | category, segment |
| SLA | sla_compliance | Histogram | operation, within_sla |

## Alert Rules

```yaml
groups:
  - name: sla_alerts
    rules:
      - alert: HighLatency
        expr: histogram_quantile(0.99, api_latency_seconds) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High API latency detected"

      - alert: HighErrorRate
        expr: rate(errors_total[5m]) > 0.01
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Error rate above 1%"

      - alert: CircuitBreakerOpen
        expr: circuit_breaker_state == 1
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Circuit breaker is open"
```
