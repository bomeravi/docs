# Kubernetes Manifests
Last updated: **March 4, 2026**

This directory contains Kubernetes manifest examples organized by application.
Each app folder has its own README that includes all YAML files with descriptions and inline code.

## App Folder Paths

- [`django/`](./django/README.md) - Django Deployment + Service
- [`go/`](./go/README.md) - Go Deployment + Service
- [`java-microservice/`](./java-microservice/README.md) - Java Deployment + Service
- [`jenkins/`](./jenkins/README.md) - Jenkins StatefulSet + Service
- [`laravel/`](./laravel/README.md) - Laravel Deployment + Service
- [`node/`](./node/README.md) - Node.js Deployment + Service
- [`react/`](./react/README.md) - React Deployment + Service
- [`wordpress/`](./wordpress/README.md) - WordPress + MySQL + Secret example

## Apply Manifests

Apply all manifests for one app:

```bash
kubectl apply -f kubernetes/manifests/<app>/ -n <namespace>
```

Example:

```bash
kubectl apply -f kubernetes/manifests/go/ -n demo
```

Before applying, update image names, create required Secrets, and adjust resources for your cluster.
