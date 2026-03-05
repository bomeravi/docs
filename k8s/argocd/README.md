# Docs App Argo CD

Argo CD application manifest for deploying the same docs app from Git.

## File

- `01-application.yaml`

## Required edit

Update this field before applying:

- `spec.source.repoURL`

You can keep:

- `targetRevision: argocd`
- `path: k8s/kubernetes`

## Apply

```bash
kubectl apply -f k8s/argocd/01-application.yaml
```

## Verify

```bash
kubectl get applications -n argocd
argocd app get docs
```
