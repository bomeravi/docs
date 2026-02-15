# Kubernetes Docs

# Kubernetes

This folder contains installation notes and example manifests for local development and deployment.

- Installation and common commands: `kubernetes-installation-and-commands.md`
- Example manifests: `manifests/` (laravel, wordpress, java-microservice, node, go, django, jenkins, react)

Apply app manifests, for example:

```bash
kubectl create namespace demo || true
kubectl apply -f kubernetes/manifests/react/ -n demo
```

This folder contains Kubernetes-related documentation and example manifests.

- Installation and commands: `kubernetes-installation-and-commands.md`
- Example manifests: `manifests/` (laravel, wordpress, java-microservice, node, go, django)

See `kubernetes-installation-and-commands.md` for OS-specific install steps and common `kubectl` usage.

