# Jenkins on Kubernetes

This folder contains a Jenkins StatefulSet and Service.

- `statefulset.yaml` provisions persistent Jenkins data with a `volumeClaimTemplates` request.
- `service.yaml` exposes both Jenkins UI and agent ports.
- Review resources, storage size, and service type before production use.

## `statefulset.yaml`
Runs Jenkins as a single-replica StatefulSet with persistent storage.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: jenkins
  labels:
    app: jenkins
spec:
  serviceName: "jenkins"
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
        - containerPort: 50000
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "1"
            memory: "2Gi"
  volumeClaimTemplates:
  - metadata:
      name: jenkins-home
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

## `service.yaml`
Exposes Jenkins UI (`8080`) and agent port (`50000`) using `NodePort`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  labels:
    app: jenkins
spec:
  selector:
    app: jenkins
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: agent
    port: 50000
    targetPort: 50000
  type: NodePort
```
