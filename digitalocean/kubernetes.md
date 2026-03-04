# Kubernetes on DigitalOcean (DOKS)
Last updated: **March 4, 2026**

This guide walks through creating a DigitalOcean Kubernetes cluster and deploying a basic workload.

## Prerequisites

- DigitalOcean account with billing enabled
- `kubectl` installed locally
- `doctl` installed locally (recommended)

## 1. Create a Kubernetes Cluster

- Open DigitalOcean dashboard.
- Go to `Kubernetes` -> `Create Kubernetes Cluster`.
- Configure:
  - Region and VPC
  - Kubernetes version
  - Node pool size and instance type
  - Cluster name
- Click `Create Cluster`.

## 2. Authenticate with DigitalOcean

Create a personal access token from `API` -> `Tokens/Keys`, then run:

```bash
doctl auth init
```

Paste the token when prompted.

## 3. Save Kubeconfig for the Cluster

List clusters:

```bash
doctl kubernetes cluster list
```

Save kubeconfig:

```bash
doctl kubernetes cluster kubeconfig save <CLUSTER_NAME>
```

## 4. Verify Cluster Access

```bash
kubectl get nodes
kubectl get ns
```

If nodes are visible, access is configured correctly.

## 5. Deploy a Test Application

```bash
kubectl create deployment hello-nginx --image=nginx:stable
kubectl expose deployment hello-nginx --port=80 --type=LoadBalancer
kubectl get svc hello-nginx -w
```

Use the external IP once it is assigned.

## 6. Basic Production Setup Checklist

- Create namespaces per environment (`dev`, `staging`, `prod`)
- Set resource requests/limits for workloads
- Store secrets in Kubernetes Secrets or external secret manager
- Enable monitoring and alerts
- Restrict access with RBAC

## Next Step

- Continue with cluster operations in [Kubernetes docs](../kubernetes/readme.md).
