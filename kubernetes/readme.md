---
pagination_label: Kubernetes
---

# Kubernetes

This folder contains installation notes, a kubectl command reference, and reusable manifest examples.

## Guides in this folder

- [Installation](./01-kubernetes-installation.md): install Kubernetes on Ubuntu, macOS, and Windows, plus the manifest/CI layout.
- [kubectl Commands Reference](./02-kubectl-commands.md): everyday commands for namespaces, pods, deployments, services, logs, debugging, and cleanup.
- [Production Baseline](./03-production-baseline.md): security, availability,
  configuration, rollout, and rollback requirements for production workloads.
- Example manifests by stack: `manifests/` (laravel, wordpress, java-microservice, node, go, django, jenkins, react)

Apply app manifests, for example:

```bash
kubectl create namespace demo || true
kubectl apply -f kubernetes/manifests/react/ -n demo
```

For the docs deployment flow using Docker Hub + Jenkins + Argo CD, see:

- `../k8s/README.md`
- `../k8s/kubernetes/README.md`
- `../k8s/argocd/README.md`
