# Go Microservice Example

This folder contains a basic Go deployment exposed internally with a ClusterIP service.

- Replace `your-registry/go-app:latest` with your own image.
- The app is expected to listen on port `8080`.

## `deployment.yaml`
Deploys 2 replicas of the Go application.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-app
  labels:
    app: go-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: go-app
  template:
    metadata:
      labels:
        app: go-app
    spec:
      containers:
      - name: go
        image: your-registry/go-app:latest
        ports:
        - containerPort: 8080
```

## `service.yaml`
Exposes the Go pods inside the cluster on port `8080`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: go-app
  labels:
    app: go-app
spec:
  selector:
    app: go-app
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
  type: ClusterIP
```
