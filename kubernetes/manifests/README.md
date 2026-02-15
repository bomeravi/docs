# Kubernetes Manifests

This folder contains example Kubernetes manifests organized per-application. Replace image names, secrets, and resource settings before applying to your cluster.

Layout:

- `laravel/` - Laravel (PHP-FPM) example
- `wordpress/` - WordPress + MySQL example
- `java-microservice/` - Java microservice example
- `node/` - Node.js example
- `go/` - Go microservice example
- `django/` - Python / Django example
 - `jenkins/` - Jenkins StatefulSet example with PVC
 - `react/` - React (static) app example

Apply an app's manifests with:

```bash
kubectl apply -f kubernetes/manifests/<app>/ -n <namespace>
```

Be sure to create namespaces, PVCs, and secrets as required by each app.
