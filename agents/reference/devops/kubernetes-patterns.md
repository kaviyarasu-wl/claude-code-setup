# Kubernetes Advanced Patterns

## Overview

Production-grade Kubernetes patterns for service mesh configuration, chaos engineering, and progressive delivery. These patterns are used by the elite-devops-automation agent for enterprise deployments.

## Service Mesh Configuration (Istio)

### Virtual Service with Advanced Traffic Management

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-service
spec:
  hosts:
    - my-service
  http:
    # Premium user routing
    - match:
        - headers:
            x-user-type:
              exact: premium
      route:
        - destination:
            host: my-service
            subset: premium-tier
          weight: 100
      timeout: 10s
      retries:
        attempts: 3
        perTryTimeout: 3s
        retryOn: 5xx,reset,connect-failure,refused-stream

    # Canary traffic with fault injection
    - match:
        - headers:
            x-canary:
              exact: "true"
      route:
        - destination:
            host: my-service
            subset: canary
          weight: 100
      fault:
        delay:
          percentage:
            value: 10
          fixedDelay: 5s

    # Default traffic split (95/5 stable/canary)
    - route:
        - destination:
            host: my-service
            subset: stable
          weight: 95
        - destination:
            host: my-service
            subset: canary
          weight: 5
      corsPolicy:
        allowOrigins:
          - regex: ".*"
        allowMethods:
          - GET
          - POST
          - PUT
          - DELETE
        allowHeaders:
          - content-type
          - authorization
        maxAge: 24h
```

### Destination Rule with Circuit Breaking

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: my-service
spec:
  host: my-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
        maxRequestsPerConnection: 1
        h2UpgradePolicy: UPGRADE
    loadBalancer:
      simple: LEAST_REQUEST
      consistentHash:
        httpHeaderName: x-session-id
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
      minHealthPercent: 30
      splitExternalLocalOriginErrors: true
  subsets:
    - name: stable
      labels:
        version: stable
    - name: canary
      labels:
        version: canary
      trafficPolicy:
        connectionPool:
          tcp:
            maxConnections: 10
    - name: premium-tier
      labels:
        tier: premium
      trafficPolicy:
        connectionPool:
          tcp:
            maxConnections: 200
        loadBalancer:
          simple: ROUND_ROBIN
```

---

## Chaos Engineering (LitmusChaos)

### Comprehensive Chaos Suite

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: comprehensive-chaos-suite
spec:
  appinfo:
    appns: production
    applabel: "app=critical-service"
    appkind: deployment
  engineState: "active"
  chaosServiceAccount: chaos-admin
  experiments:
    # Network Chaos - Partition
    - name: pod-network-partition
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "300"
            - name: NETWORK_INTERFACE
              value: "eth0"
            - name: TARGET_PODS
              value: "50"
            - name: POLICY
              value: "all"

    # Resource Chaos - Memory Pressure
    - name: pod-memory-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "120"
            - name: MEMORY_CONSUMPTION
              value: "500Mi"
            - name: NUMBER_OF_WORKERS
              value: "4"

    # CPU Stress
    - name: pod-cpu-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "180"
            - name: CPU_CORES
              value: "2"
            - name: CPU_LOAD
              value: "80"

    # Time Chaos - Clock Skew
    - name: time-chaos
      spec:
        components:
          env:
            - name: OFFSET
              value: "3600s"
            - name: CLOCK_IDS
              value: "CLOCK_REALTIME,CLOCK_MONOTONIC"

    # I/O Stress
    - name: pod-io-stress
      spec:
        components:
          env:
            - name: FILESYSTEM_UTILIZATION_BYTES
              value: "10737418240"  # 10GB
            - name: NUMBER_OF_WORKERS
              value: "8"
            - name: VOLUME_MOUNT_PATH
              value: "/data"
```

### Steady State Hypothesis (Chaos Toolkit)

```yaml
apiVersion: chaostoolkit.org/v1
kind: Experiment
metadata:
  name: steady-state-validation
spec:
  title: "Validate System Resilience"
  description: "Ensure system maintains SLOs under failure conditions"

  steady-state-hypothesis:
    title: "System is healthy"
    probes:
      - type: probe
        name: "service-availability"
        tolerance:
          type: "range"
          range: [99.9, 100]
        provider:
          type: http
          url: "http://service/health"
          timeout: 5

      - type: probe
        name: "latency-p99"
        tolerance:
          type: "below"
          value: 200
        provider:
          type: prometheus
          query: |
            histogram_quantile(0.99,
              rate(http_request_duration_seconds_bucket[5m])
            )

      - type: probe
        name: "error-rate"
        tolerance:
          type: "below"
          value: 0.1
        provider:
          type: prometheus
          query: |
            rate(http_requests_total{status=~"5.."}[5m])
            / rate(http_requests_total[5m]) * 100

  method:
    - type: action
      name: "inject-network-latency"
      provider:
        type: kubernetes
        module: chaoslib.litmus.network
        func: inject_latency
        arguments:
          namespace: production
          label_selector: "app=critical-service"
          latency: 100
          jitter: 50
          duration: 300

    - type: action
      name: "terminate-random-pods"
      provider:
        type: kubernetes
        module: chaoslib.litmus.pod
        func: terminate_pods
        arguments:
          namespace: production
          label_selector: "app=critical-service"
          percentage: 33
          interval: 60

  rollbacks:
    - type: action
      name: "scale-up-replicas"
      provider:
        type: kubernetes
        module: kubectl
        func: scale
        arguments:
          namespace: production
          deployment: critical-service
          replicas: 10
```

---

## Progressive Delivery

### Flagger Canary Deployment

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: my-service
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-service
  progressDeadlineSeconds: 3600
  service:
    port: 80
    targetPort: 8080
    gateways:
      - public-gateway
    hosts:
      - my-service.company.com
    trafficPolicy:
      tls:
        mode: ISTIO_MUTUAL
  analysis:
    interval: 1m
    threshold: 10
    maxWeight: 50
    stepWeight: 5
    stepWeightPromotion: 10
    metrics:
      - name: request-success-rate
        thresholdRange:
          min: 99
        interval: 1m
      - name: latency-p99
        thresholdRange:
          max: 500
        interval: 30s
      - name: cpu-usage
        thresholdRange:
          max: 80
        interval: 30s
      - name: memory-usage
        thresholdRange:
          max: 90
        interval: 30s
      - name: custom-business-metric
        templateRef:
          name: business-metrics
          namespace: flagger-system
        thresholdRange:
          min: 95
    webhooks:
      - name: acceptance-test
        type: pre-rollout
        url: http://flagger-tester.test/
        timeout: 30s
      - name: load-test
        type: rollout
        url: http://flagger-loadtester.test/
        metadata:
          cmd: "hey -z 2m -q 10 -c 2 http://my-service-canary:8080/"
      - name: smoke-test
        type: post-rollout
        url: http://flagger-tester.test/smoke
    alerts:
      - name: slack
        severity: info
        providerRef:
          name: slack-webhook
      - name: pagerduty
        severity: error
        providerRef:
          name: pagerduty-integration
  autoscalerRef:
    apiVersion: autoscaling/v2
    kind: HorizontalPodAutoscaler
    name: my-service
```

### Argo Rollouts Blue-Green Deployment

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-service
spec:
  replicas: 10
  strategy:
    blueGreen:
      activeService: my-service-active
      previewService: my-service-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
          - templateName: success-rate
        args:
          - name: service-name
            value: my-service
      postPromotionAnalysis:
        templates:
          - templateName: error-rate
        args:
          - name: service-name
            value: my-service
      antiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution: {}
      maxUnavailable: 0
      progressDeadlineAbort: true
  template:
    metadata:
      labels:
        app: my-service
    spec:
      containers:
        - name: my-service
          image: my-service:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
```

---

## Key Patterns Summary

| Pattern | Use Case | Tool |
|---------|----------|------|
| Traffic Splitting | A/B testing, canary releases | Istio VirtualService |
| Circuit Breaking | Prevent cascade failures | Istio DestinationRule |
| Network Partition | Test resilience to network issues | LitmusChaos |
| CPU/Memory Stress | Validate resource limits | LitmusChaos |
| Canary Deployment | Gradual traffic shift with metrics | Flagger |
| Blue-Green | Zero-downtime with instant rollback | Argo Rollouts |

## Related Documentation

- For GitOps workflows with ArgoCD/Flux: `gitops-workflows.md`
- For zero-downtime deployment strategies: `zero-downtime-deployment.md`
