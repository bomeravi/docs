# K8s Deployment Paths

This folder contains two deployment paths for the same app image (`bomeravi/docs:latest`).

## Folder layout

- `k8s/kubernetes/` - direct `kubectl apply` manifests (used by Jenkins pipeline).
- `k8s/argocd/` - Argo CD `Application` manifest that points to `k8s/kubernetes`.

Manifests are numbered (`01-`, `02-`, ...) so execution order is explicit.

## Branch flow

Use two git branches for your release flow:

- `jenkins` branch:
  - Runs `Jenkinsfile`.
  - Builds and pushes `bomeravi/docs:latest`.
  - Applies manifests from `k8s/kubernetes` using `kubectl`.
- `argocd` branch:
  - Keeps Argo CD app config in `k8s/argocd`.
  - Argo CD syncs `k8s/kubernetes` from the branch.

## Docker image tag

This setup always uses:

```bash
docker push bomeravi/docs:latest
```
