# Node.js Example

This folder contains a Node.js deployment and service.

- Replace `your-registry/node-app:latest` with your own image.
- The app is expected to listen on port `3000`.

## `deployment.yaml`
Deploys 2 replicas and sets `NODE_ENV=production`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app
  labels:
    app: node-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: node-app
  template:
    metadata:
      labels:
        app: node-app
    spec:
      containers:
      - name: node
        image: your-registry/node-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: production
```

## `service.yaml`
Exposes the Node.js pods inside the cluster on port `3000`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node-app
  labels:
    app: node-app
spec:
  selector:
    app: node-app
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  type: ClusterIP
```
