# Django Example

This folder contains a Django deployment and service.

- Replace `your-registry/django:latest` with your own image.
- The app is expected to run with Gunicorn on port `8000`.
- Create the `django-secret` Secret before applying.

## `deployment.yaml`
Deploys 2 replicas of the Django application and reads `SECRET_KEY` from a Secret.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-app
  labels:
    app: django-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: django-app
  template:
    metadata:
      labels:
        app: django-app
    spec:
      containers:
      - name: django
        image: your-registry/django:latest
        ports:
        - containerPort: 8000
        env:
        - name: DJANGO_SETTINGS_MODULE
          value: myproject.settings.production
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: django-secret
              key: secret_key
```

## `service.yaml`
Exposes the Django pods inside the cluster on port `8000`.

```yaml  
apiVersion: v1
kind: Service
metadata:
  name: django-app
  labels:
    app: django-app
spec:
  selector:
    app: django-app
  ports:
  - protocol: TCP
    port: 8000
    targetPort: 8000
  type: ClusterIP
```
