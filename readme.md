---
title: Documentation
slug: /
sidebar_position: 1
---

# Documentation

This repository contains internal setup, deployment, and operations documentation.

## All Documentation Pages

### Core Docs
- [Basic Packages](./basic-packages.md)
- [Certbot](./certbot.md)
- [Cloudflared](./cloudflared.md)
- [LAMP Setup](./lamp-setup.md)
- [Server Setup](./server-setup.md)

### ArgoCD
- [Overview](./argocd/readme.md)

### DigitalOcean
- [Overview](./digitalocean/readme.md)
- [Droplet Setup](./digitalocean/droplet.md)
- [Fix Sudo User Permission](./digitalocean/fix-sudo-user-permission.md)
- [Install doctl](./digitalocean/install-doctl.md)
- [Kubernetes on DigitalOcean](./digitalocean/kubernetes.md)
- [Space Object Storage](./digitalocean/space-object-storage.md)

### SSH
- [Overview](./ssh/readme.md)
- [Allow Multiple SSH](./ssh/allow-multiple-ssh.md)
- [Disable Root Ubuntu](./ssh/disable-root-ubuntu.md)
- [Generate Keys](./ssh/generate-keys.md)

### Git
- [Overview](./git/readme.md)
- [Git Setup](./git/git-setup.md)
- [Git Commands](./git/git-commands.md)
- [Git Commit Guide](./git/git-commit.md)

### Docker
- [Overview](./docker/readme.md)
- [Dockerfiles Overview](./docker/dockerfiles/readme.md)
- [Django Dockerfile](./docker/dockerfiles/django.md)
- [Go Dockerfile](./docker/dockerfiles/go.md)
- [Java Microservice Dockerfile](./docker/dockerfiles/java-microservice.md)
- [Laravel Dockerfile](./docker/dockerfiles/laravel.md)
- [PHP Dockerfile](./docker/dockerfiles/php.md)
- [Python Dockerfile](./docker/dockerfiles/python.md)
- [React Dockerfile](./docker/dockerfiles/react.md)
- [WordPress Dockerfile](./docker/dockerfiles/wordpress.md)

### Jenkins
- [Overview](./jenkins/readme.md)
- [Apache Setup](./jenkins/apache-setup.md)
- [Secrets](./jenkins/secrets.md)
- [Server Setup](./jenkins/server-setup.md)
- [Jenkinsfiles Overview](./jenkins/jenkinsfiles/readme.md)
- [Jenkinsfile Django](./jenkins/jenkinsfiles/Jenkinsfile-django.md)
- [Docs + Kubernetes Jenkinsfile](./jenkins/jenkinsfiles/Jenkinsfile-docs-k8s.md)
- [Jenkinsfile Go](./jenkins/jenkinsfiles/Jenkinsfile-go.md)
- [Jenkinsfile Java](./jenkins/jenkinsfiles/Jenkinsfile-java.md)
- [Jenkinsfile Laravel](./jenkins/jenkinsfiles/Jenkinsfile-laravel.md)
- [Jenkinsfile PHP](./jenkins/jenkinsfiles/Jenkinsfile-php.md)
- [Jenkinsfile Python](./jenkins/jenkinsfiles/Jenkinsfile-python.md)
- [Jenkinsfile React](./jenkins/jenkinsfiles/Jenkinsfile-react.md)
- [Jenkinsfile WordPress](./jenkins/jenkinsfiles/Jenkinsfile-wordpress.md)
- [Shared Library Overview](./jenkins/shared-library/README.md)

### Kubernetes
- [Overview](./kubernetes/readme.md)
- [Installation and Commands](./kubernetes/kubernetes-installation-and-commands.md)
- [Manifests Overview](./kubernetes/manifests/README.md)
- [Django Manifest Docs](./kubernetes/manifests/django/README.md)
- [Go Manifest Docs](./kubernetes/manifests/go/README.md)
- [Java Microservice Manifest Docs](./kubernetes/manifests/java-microservice/README.md)
- [Jenkins Manifest Docs](./kubernetes/manifests/jenkins/README.md)
- [Laravel Manifest Docs](./kubernetes/manifests/laravel/README.md)
- [Node Manifest Docs](./kubernetes/manifests/node/README.md)
- [React Manifest Docs](./kubernetes/manifests/react/README.md)
- [WordPress Manifest Docs](./kubernetes/manifests/wordpress/README.md)

## Cloudflare Pages Deployment

This repo is ready to deploy as a static docs site using Docsify.

### 1) Connect repository
- In Cloudflare dashboard, go to **Workers & Pages** -> **Create** -> **Pages**.
- Connect this Git repository.

### 2) Build configuration
Use these exact values:
- **Framework preset:** `None`
- **Build command:** *(leave empty)*
- **Build output directory:** `.`
- **Root directory:** `/` (or empty/default)

### 3) Deploy
- Trigger deployment from the dashboard.
- Cloudflare will serve `index.html` from repo root.

### 4) How navigation works
- `index.html` boots Docsify.
- `_sidebar.md` contains links to all markdown pages.
- `readme.md` is the homepage.

## Local Preview

To preview locally before pushing:

```bash
npx docsify-cli serve .
```

Then open `http://localhost:3000`.


## 🤝 Contributing

If you find any issues or want to add new documentation, feel free to submit a PR — contributions are always welcomed!

> [!WARNING]
> This repository may contain existing errors or outdated content. Some things may stop working over time due to application version updates.

### How to contribute

| | What | How |
|---|---|---|
| 🐛 | Found an error? | Fix it and open a PR |
| 📄 | Missing documentation? | Add new pages or expand existing ones |
| 🔧 | Broken example? | Update it for the latest version |
