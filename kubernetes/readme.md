# Kubernetes

This folder contains installation notes and reusable manifest examples.

- Installation and common commands: `kubernetes-installation-and-commands.md`
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
