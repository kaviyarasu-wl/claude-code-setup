# Zero-Downtime Deployment System

## Overview

Complete deployment orchestration with blue-green, canary, rolling deployments, and feature flag integration.

## Deployment Strategies

| Strategy | Risk | Rollback Speed | Use Case |
|----------|------|----------------|----------|
| Blue-Green | Low | Instant | Critical services |
| Canary | Medium | Fast | User-facing features |
| Rolling | Medium | Slow | Stateless services |
| Feature Flag | Lowest | Instant | A/B testing, gradual rollout |

## Implementation

```typescript
// Blue-Green Deployment with Canary Release
class ZeroDowntimeDeployment {
  private kubernetes: KubernetesClient;
  private monitoring: MonitoringService;
  private loadBalancer: LoadBalancerService;

  async deploy(
    application: string,
    version: string,
    strategy: DeploymentStrategy
  ): Promise<DeploymentResult> {
    const deployment = new DeploymentOrchestrator({
      app: application,
      version,
      strategy
    });

    try {
      // Pre-deployment checks
      await deployment.runPreflightChecks();

      // Execute deployment strategy
      switch (strategy) {
        case 'blue-green':
          return await this.blueGreenDeploy(deployment);
        case 'canary':
          return await this.canaryDeploy(deployment);
        case 'rolling':
          return await this.rollingDeploy(deployment);
        case 'feature-flag':
          return await this.featureFlagDeploy(deployment);
      }

    } catch (error) {
      await deployment.rollback();
      throw error;
    }
  }

  private async blueGreenDeploy(deployment: Deployment): Promise<DeploymentResult> {
    // Create green environment
    const greenEnv = await this.kubernetes.createDeployment({
      name: `${deployment.app}-green`,
      replicas: deployment.replicas,
      image: deployment.image,
      labels: { version: deployment.version, env: 'green' }
    });

    // Wait for green to be ready
    await this.waitForReady(greenEnv);

    // Run smoke tests
    const smokeTestResult = await this.runSmokeTests(greenEnv);
    if (!smokeTestResult.passed) {
      throw new Error('Smoke tests failed');
    }

    // Gradual traffic shift
    for (const percentage of [10, 25, 50, 75, 100]) {
      await this.loadBalancer.updateWeights({
        blue: 100 - percentage,
        green: percentage
      });

      // Monitor metrics
      await this.monitorHealth(greenEnv, 60); // 1 minute

      // Check error rates
      const errorRate = await this.monitoring.getErrorRate(greenEnv);
      if (errorRate > 0.01) { // 1% threshold
        await this.loadBalancer.updateWeights({ blue: 100, green: 0 });
        throw new Error(`High error rate detected: ${errorRate}`);
      }
    }

    // Complete switch
    await this.kubernetes.updateService({
      name: deployment.app,
      selector: { version: deployment.version }
    });

    // Keep blue for rollback
    await this.kubernetes.scaleDeployment(`${deployment.app}-blue`, 0);

    return {
      status: 'success',
      version: deployment.version,
      deploymentTime: Date.now()
    };
  }

  private async canaryDeploy(deployment: Deployment): Promise<DeploymentResult> {
    const stages = [
      { percentage: 5, duration: 300, name: 'alpha' },
      { percentage: 10, duration: 600, name: 'beta' },
      { percentage: 25, duration: 1800, name: 'gamma' },
      { percentage: 50, duration: 3600, name: 'delta' },
      { percentage: 100, duration: 0, name: 'production' }
    ];

    for (const stage of stages) {
      // Deploy canary version
      await this.kubernetes.updateDeployment({
        name: `${deployment.app}-canary`,
        replicas: Math.ceil(deployment.replicas * stage.percentage / 100)
      });

      // Configure traffic split
      await this.configureIstioVirtualService({
        name: deployment.app,
        routes: [
          { version: 'stable', weight: 100 - stage.percentage },
          { version: 'canary', weight: stage.percentage }
        ]
      });

      // Monitor and analyze
      const analysis = await this.runCanaryAnalysis({
        baseline: 'stable',
        canary: 'canary',
        metrics: ['latency_p99', 'error_rate', 'cpu_usage'],
        duration: stage.duration
      });

      if (!analysis.passed) {
        await this.abortCanary(deployment);
        throw new Error(`Canary failed at ${stage.name}: ${analysis.reason}`);
      }

      // Progressive rollout
      if (stage.percentage < 100) {
        await this.sleep(stage.duration * 1000);
      }
    }

    // Promote canary to stable
    await this.promoteCanary(deployment);

    return { status: 'success', strategy: 'canary' };
  }
}
```

## Feature Flag System

```typescript
// Feature Flag Service
class FeatureFlagService {
  private flags: Map<string, FeatureFlag> = new Map();

  async evaluateFlag(
    flagName: string,
    context: EvaluationContext
  ): Promise<boolean> {
    const flag = this.flags.get(flagName);
    if (!flag) return false;

    // Check kill switch
    if (flag.killSwitch) return false;

    // Check prerequisites
    for (const prereq of flag.prerequisites) {
      if (!await this.evaluateFlag(prereq, context)) {
        return false;
      }
    }

    // Evaluate rules
    for (const rule of flag.rules) {
      if (await this.evaluateRule(rule, context)) {
        return rule.variation;
      }
    }

    // Check percentage rollout
    if (flag.percentage) {
      const hash = this.hash(`${flagName}:${context.userId}`);
      return (hash % 100) < flag.percentage;
    }

    return flag.defaultVariation;
  }

  private async evaluateRule(
    rule: Rule,
    context: EvaluationContext
  ): Promise<boolean> {
    switch (rule.type) {
      case 'user':
        return rule.values.includes(context.userId);

      case 'segment':
        return await this.isInSegment(context.userId, rule.segment);

      case 'attribute':
        return this.matchesAttribute(context, rule.attribute, rule.operator, rule.value);

      case 'time':
        return this.isWithinTimeWindow(rule.startTime, rule.endTime);

      case 'percentage':
        const hash = this.hash(`${rule.id}:${context.userId}`);
        return (hash % 100) < rule.percentage;
    }
  }
}
```

## Kubernetes Manifests

```yaml
# Blue-Green Service
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    # Switch between blue/green by changing version
    version: green
  ports:
    - port: 80
      targetPort: 8080

---
# Canary with Istio
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
    - myapp
  http:
    - route:
        - destination:
            host: myapp
            subset: stable
          weight: 90
        - destination:
            host: myapp
            subset: canary
          weight: 10
```

## Deployment Checklist

- [ ] Pre-deployment health check
- [ ] Database migrations completed
- [ ] Feature flags configured
- [ ] Monitoring dashboards ready
- [ ] Rollback procedure documented
- [ ] On-call team notified
- [ ] Smoke tests passing
- [ ] Traffic gradually shifted
- [ ] Error rates within threshold
- [ ] Rollback plan verified
