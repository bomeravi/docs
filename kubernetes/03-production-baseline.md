---
pagination_label: Kubernetes Production Baseline
---

# Kubernetes Production Baseline

Use this as the minimum review checklist for a production workload. It
complements the [installation guide](./01-kubernetes-installation.md) and the
[kubectl command reference](./02-kubectl-commands.md); it does not replace
cluster-provider security controls.

## Namespace and access controls

- Give each application/environment its own namespace.
- Use a dedicated service account for an application only when it needs to call
  the Kubernetes API. Disable automatic token mounting otherwise.
- Grant the narrowest RBAC permissions possible; do not bind application
  service accounts to `cluster-admin`.
- Add `ResourceQuota` and `LimitRange` where namespaces share a cluster.
- Apply NetworkPolicies that permit only required ingress and egress. Test DNS,
  database, and external API access before enforcing them.

## Workload manifest baseline

Every Deployment should define an immutable image version, resource requests
and limits, health probes, a restricted security context, and a graceful
termination window. Adjust the paths, port, resources, and timings to the
application—do not copy the values blindly.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-api
  labels:
    app.kubernetes.io/name: example-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: example-api
  template:
    metadata:
      labels:
        app.kubernetes.io/name: example-api
    spec:
      automountServiceAccountToken: false
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      terminationGracePeriodSeconds: 30
      containers:
        - name: api
          image: registry.example.com/example-api:1.4.2
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            readOnlyRootFilesystem: true
            runAsNonRoot: true
          startupProbe:
            httpGet:
              path: /health/startup
              port: http
            failureThreshold: 30
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /health/ready
              port: http
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health/live
              port: http
            periodSeconds: 15
```

> A liveness probe restarts containers, so make it inexpensive and independent
> of transient dependencies. A readiness probe controls whether a pod receives
> traffic; use it for dependencies the application must have to serve requests.

## Configuration and secrets

- Keep non-sensitive, environment-specific configuration in ConfigMaps or the
  deployment system.
- Do not commit real Kubernetes Secret manifests. Use an approved encrypted
  GitOps secret mechanism or external secret manager integration.
- Restrict who can read Secrets; base64 encoding is not encryption.
- Document secret rotation, including how the workload reloads new values.
- Pin image references by version or digest; never rely on `latest` for a
  production rollout.

## Availability and safe rollout

- Run at least two replicas for a service that needs availability beyond one
  pod/node failure.
- Configure a rolling update appropriate to the capacity available. Keep the
  previous ReplicaSet until the new version is verified.
- Add a PodDisruptionBudget for workloads that need a minimum number of ready
  pods during voluntary disruptions.
- Add an HPA only after resource requests and a meaningful scaling signal are
  established.
- Spread replicas across nodes or zones where the cluster and service
  criticality justify it.

Example PodDisruptionBudget:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: example-api
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: example-api
```

## Verify and roll back

Before a rollout, validate rendered manifests and confirm the namespace and
cluster context. After deployment, check both Kubernetes status and the user
path:

```bash
kubectl config current-context
kubectl diff -f kubernetes/manifests/example/ -n production
kubectl apply -f kubernetes/manifests/example/ -n production
kubectl rollout status deployment/example-api -n production --timeout=180s
kubectl get pods -n production -l app.kubernetes.io/name=example-api
kubectl get events -n production --sort-by=.lastTimestamp
```

If the new release is unhealthy, roll back only after confirming the previous
revision is safe and compatible with any database changes:

```bash
kubectl rollout history deployment/example-api -n production
kubectl rollout undo deployment/example-api -n production
kubectl rollout status deployment/example-api -n production --timeout=180s
```

GitOps-managed workloads should be rolled back through Git or the approved
Argo CD workflow so the declared state matches the cluster.

## Production review checklist

- [ ] Namespace, RBAC, quotas, and NetworkPolicies are reviewed.
- [ ] Image is pinned; container runs as non-root with least privilege.
- [ ] Requests, limits, probes, and shutdown behavior are tested.
- [ ] Secrets are not stored in plain Git and rotation is documented.
- [ ] Workload has a safe rollout/rollback path and database migration plan.
- [ ] Availability, logs, alerts, and backup coverage meet the service target.
- [ ] Manifest changes are reviewed and tested in a non-production environment.

## Related

- [Kubernetes manifests](./manifests/README.md) — stack-specific examples.
- [ArgoCD](../argocd/readme.md) — GitOps delivery.
- [Jenkins Secrets](../jenkins/secrets.md) — pipeline credentials.
- [Operations](../operations/readme.md) — recovery and monitoring practices.
