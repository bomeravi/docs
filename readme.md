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

### Git
- [Git Setup](./git/git-setup.md)
- [Git Commands](./git/git-commands.md)
- [Git Commit Guide](./git/git-commit.md)

### Docker
- [Overview](./docker/readme.md)

### Jenkins
- [Overview](./jenkins/readme.md)
- [Apache Setup](./jenkins/apache-setup.md)
- [Secrets](./jenkins/secrets.md)
- [Server Setup](./jenkins/server-setup.md)
- [Jenkinsfiles Overview](./jenkins/jenkinsfiles/readme.md)
- [Docs + Kubernetes Jenkinsfile](./jenkins/jenkinsfiles/Jenkinsfile-docs-k8s.md)
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

### K8s Deploy Flow (Docs)
- [Overview](./k8s/README.md)
- [Direct Kubectl Deploy](./k8s/kubernetes/README.md)
- [ArgoCD Application Deploy](./k8s/argocd/README.md)

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
