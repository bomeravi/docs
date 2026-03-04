# WordPress Kubernetes Example

This folder contains a WordPress + MySQL example with separate deployments and services.

- `secret-example.yaml` is a template; replace values with base64-encoded credentials.
- For production, use managed storage/database and stronger secret management.

## `secret-example.yaml`
Defines the Secret keys used by both WordPress and MySQL.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wp-secret
type: Opaque
data:
  # base64-encoded values
  db_root_password: REPLACE_WITH_BASE64
  db_user: REPLACE_WITH_BASE64
  db_password: REPLACE_WITH_BASE64
```

## `deployment-mysql.yaml`
Deploys a single MySQL pod configured from the `wp-secret` Secret.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wp-secret
              key: db_root_password
        - name: MYSQL_DATABASE
          value: wordpress
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: wp-secret
              key: db_user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wp-secret
              key: db_password
        ports:
        - containerPort: 3306
```

## `service-mysql.yaml`
Exposes MySQL inside the cluster on port `3306`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  selector:
    app: mysql
  ports:
  - protocol: TCP
    port: 3306
    targetPort: 3306
  type: ClusterIP
```

## `deployment-wordpress.yaml`
Deploys WordPress configured to connect to the MySQL service.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:6.2-php8.1-apache
        ports:
        - containerPort: 80
        env:
        - name: WORDPRESS_DB_HOST
          value: mysql
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: wp-secret
              key: db_user
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wp-secret
              key: db_password
```

## `service-wordpress.yaml`
Exposes WordPress inside the cluster on port `80`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  selector:
    app: wordpress
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```
