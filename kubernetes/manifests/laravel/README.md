# Laravel Kubernetes Example

This folder contains a minimal Laravel (PHP-FPM) deployment and service.

- Replace `your-registry/laravel:latest` with your own image.
- Create the `laravel-secret` Secret before applying.
- Pair this with Nginx/Ingress for HTTP routing to PHP-FPM.

## `deployment.yaml`
Deploys 2 replicas of Laravel PHP-FPM and reads `APP_KEY` from a Secret.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: laravel-app
  labels:
    app: laravel
spec:
  replicas: 2
  selector:
    matchLabels:
      app: laravel
  template:
    metadata:
      labels:
        app: laravel
    spec:
      containers:
      - name: php-fpm
        image: your-registry/laravel:latest
        ports:
        - containerPort: 9000
        env:
        - name: APP_ENV
          value: production
        - name: APP_KEY
          valueFrom:
            secretKeyRef:
              name: laravel-secret
              key: app_key
```

## `service.yaml`
Exposes Laravel PHP-FPM inside the cluster on port `9000`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: laravel
  labels:
    app: laravel
spec:
  selector:
    app: laravel
  ports:
  - protocol: TCP
    port: 9000
    targetPort: 9000
  type: ClusterIP
```
