# GitOps Workflows

## Overview

Production-grade GitOps patterns using ArgoCD, Flux v2, and Policy as Code with Open Policy Agent (OPA). These patterns enable declarative, version-controlled infrastructure management.

## ArgoCD Multi-Cluster Configuration

### Application Definition

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: production
  source:
    repoURL: https://github.com/company/k8s-manifests
    targetRevision: main
    path: apps/my-app/overlays/production
    kustomize:
      images:
        - my-app=registry.company.com/my-app:v1.2.3
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas
```

### ApplicationSet for Multi-Cluster

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-cluster-app
  namespace: argocd
spec:
  generators:
    - clusters:
        selector:
          matchLabels:
            environment: production
        values:
          revision: main
    - clusters:
        selector:
          matchLabels:
            environment: staging
        values:
          revision: develop
  template:
    metadata:
      name: "{{name}}-my-app"
    spec:
      project: default
      source:
        repoURL: https://github.com/company/k8s-manifests
        targetRevision: "{{values.revision}}"
        path: "apps/my-app/overlays/{{metadata.labels.environment}}"
      destination:
        server: "{{server}}"
        namespace: my-app
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

---

## Flux v2 GitOps Toolkit

### GitRepository Source

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: app-repo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/company/k8s-manifests
  ref:
    branch: main
  secretRef:
    name: git-credentials
  ignore: |
    # Exclude files from sync
    !.github/
    !docs/
```

### Kustomization Controller

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: production-apps
  namespace: flux-system
spec:
  interval: 10m
  targetNamespace: production
  sourceRef:
    kind: GitRepository
    name: app-repo
  path: ./apps/production
  prune: true
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: my-app
      namespace: production
  postBuild:
    substitute:
      CLUSTER_NAME: production-us-east-1
      ENVIRONMENT: production
    substituteFrom:
      - kind: ConfigMap
        name: cluster-config
      - kind: Secret
        name: cluster-secrets
  dependsOn:
    - name: infrastructure
    - name: cert-manager
```

### Image Automation

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  image: registry.company.com/my-app
  interval: 5m
  secretRef:
    name: registry-credentials
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: my-app
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: my-app
  policy:
    semver:
      range: ">=1.0.0"
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 30m
  sourceRef:
    kind: GitRepository
    name: app-repo
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: flux@company.com
        name: Flux Bot
      messageTemplate: |
        Automated image update

        Automation: {{ .AutomationObject }}
        Files:
        {{ range $filename, $_ := .Changed.FileChanges -}}
        - {{ $filename }}
        {{ end -}}
        Objects:
        {{ range $resource, $changes := .Changed.Objects -}}
        - {{ $resource.Kind }} {{ $resource.Name }}
          Changes:
        {{ range $changes -}}
            - {{ .OldValue }} -> {{ .NewValue }}
        {{ end -}}
        {{ end -}}
    push:
      branch: main
  update:
    path: ./apps
    strategy: Setters
```

---

## Policy as Code (Open Policy Agent)

### Kubernetes Admission Policies

```rego
package kubernetes.admission

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Enforce resource limits on all containers
deny[msg] {
    input.request.kind.kind == "Deployment"
    container := input.request.object.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container %s is missing memory limits", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Deployment"
    container := input.request.object.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container %s is missing CPU limits", [container.name])
}

# Enforce security policies
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Privileged container %s is not allowed", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.runAsUser == 0
    msg := "Containers cannot run as root"
}

# Network policies
deny[msg] {
    input.request.kind.kind == "Service"
    input.request.object.spec.type == "NodePort"
    msg := "NodePort services are not allowed in production"
}

# Image policies - require company registry
deny[msg] {
    input.request.kind.kind in ["Deployment", "StatefulSet", "DaemonSet"]
    container := input.request.object.spec.template.spec.containers[_]
    not startswith(container.image, "registry.company.com/")
    msg := sprintf("Image %s must be from company registry", [container.image])
}

# Deny latest tag in production
deny[msg] {
    input.request.kind.kind in ["Deployment", "StatefulSet", "DaemonSet"]
    container := input.request.object.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := "Latest tag is not allowed in production"
}

# Required labels for compliance
required_labels := {
    "app",
    "version",
    "team",
    "cost-center",
    "data-classification",
    "compliance-scope"
}

deny[msg] {
    input.request.kind.kind in ["Deployment", "Service", "StatefulSet"]
    required := required_labels[_]
    not input.request.object.metadata.labels[required]
    msg := sprintf("Missing required label: %s", [required])
}

# Data residency enforcement
deny[msg] {
    input.request.kind.kind == "PersistentVolumeClaim"
    input.request.object.metadata.labels["data-classification"] == "pii"
    not input.request.object.spec.storageClassName == "encrypted-regional"
    msg := "PII data must use encrypted regional storage"
}
```

### Gatekeeper Constraint Template

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Missing required labels: %v", [missing])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-team-labels
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
  parameters:
    labels:
      - app
      - team
      - version
```

---

## Environment Promotion Workflow

```yaml
# .github/workflows/promote.yaml
name: Environment Promotion

on:
  workflow_dispatch:
    inputs:
      version:
        description: "Version to promote"
        required: true
      source:
        description: "Source environment"
        required: true
        default: staging
      target:
        description: "Target environment"
        required: true
        default: production

jobs:
  promote:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GIT_TOKEN }}

      - name: Update target environment
        run: |
          cd apps/${{ github.event.inputs.target }}
          kustomize edit set image my-app=registry.company.com/my-app:${{ github.event.inputs.version }}

      - name: Create promotion PR
        uses: peter-evans/create-pull-request@v5
        with:
          title: "Promote ${{ github.event.inputs.version }} to ${{ github.event.inputs.target }}"
          body: |
            Promoting version `${{ github.event.inputs.version }}` from
            `${{ github.event.inputs.source }}` to `${{ github.event.inputs.target }}`

            ## Checklist
            - [ ] Staging tests passed
            - [ ] Load tests passed
            - [ ] Security scan clean
            - [ ] Change approved
          branch: promote/${{ github.event.inputs.version }}-to-${{ github.event.inputs.target }}
          labels: promotion,automated
```

---

## Key Patterns Summary

| Pattern | Tool | Use Case |
|---------|------|----------|
| Multi-cluster sync | ArgoCD ApplicationSet | Deploy to multiple clusters |
| Image automation | Flux ImageUpdateAutomation | Auto-update on new images |
| Policy enforcement | OPA/Gatekeeper | Security and compliance |
| Drift detection | ArgoCD/Flux | Detect manual changes |
| Environment promotion | GitHub Actions + Kustomize | Controlled releases |

## Related Documentation

- For Kubernetes deployment patterns: `kubernetes-patterns.md`
- For zero-downtime deployments: `zero-downtime-deployment.md`
