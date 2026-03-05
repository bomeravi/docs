# Docs App Kubernetes (Direct)

Direct Kubernetes manifests for deploying docs with `kubectl`.

## Image

- `bomeravi/docs:latest`
- `imagePullPolicy: Always`

## Domain + SSL

- Host: `docs.digi-kube.sajiloapps.com`
- Ingress class: `nginx`
- TLS issuer: `letsencrypt-prod` (`ClusterIssuer`)

## Files

- `01-namespace.yaml` - `docs` namespace
- `02-clusterissuer.yaml` - cert-manager ClusterIssuer
- `03-deployment.yaml` - docs deployment (2 replicas)
- `04-service.yaml` - ClusterIP service on port 80
- `05-ingress.yaml` - HTTPS ingress for the docs domain

## Prerequisites

- ingress-nginx controller installed
- cert-manager installed
- DNS `A` record for `docs.digi-kube.sajiloapps.com` pointed to ingress public IP

## Apply

```bash
kubectl apply -f k8s/kubernetes/01-namespace.yaml
kubectl apply -f k8s/kubernetes/02-clusterissuer.yaml
kubectl apply -f k8s/kubernetes/03-deployment.yaml
kubectl apply -f k8s/kubernetes/04-service.yaml
kubectl apply -f k8s/kubernetes/05-ingress.yaml
```

## Verify

```bash
kubectl get pods -n docs
kubectl get svc -n docs
kubectl get ingress -n docs
kubectl get certificate -n docs
```
