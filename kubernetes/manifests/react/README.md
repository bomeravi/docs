# React App Kubernetes Example

This folder contains a static React app deployment and service.

- Replace `your-registry/react-app:latest` with your own image.
- The container is expected to serve static files on port `80`.

## `deployment.yaml`
Deploys 2 replicas of the React app with CPU and memory requests/limits.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: react-app
  labels:
    app: react-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: react-app
  template:
    metadata:
      labels:
        app: react-app
    spec:
      containers:
      - name: react
        image: your-registry/react-app:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
```

## `service.yaml`
Exposes the React pods inside the cluster on port `80`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: react-app
  labels:
    app: react-app
spec:
  selector:
    app: react-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```
