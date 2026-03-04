# Java Microservice Example

This folder contains a Java microservice deployment and service.

- Replace `your-registry/java-microservice:latest` with your own image.
- The app is expected to listen on port `8080`.

## `deployment.yaml`
Deploys 2 replicas and sets `SPRING_PROFILES_ACTIVE=prod`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-microservice
  labels:
    app: java-microservice
spec:
  replicas: 2
  selector:
    matchLabels:
      app: java-microservice
  template:
    metadata:
      labels:
        app: java-microservice
    spec:
      containers:
      - name: app
        image: your-registry/java-microservice:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: prod
```

## `service.yaml`
Exposes the Java pods inside the cluster on port `8080`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: java-microservice
  labels:
    app: java-microservice
spec:
  selector:
    app: java-microservice
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
  type: ClusterIP
```
