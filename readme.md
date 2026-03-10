---
title: Documentation
slug: /
sidebar_position: 1
---

# Documentation

This repository serves as a centralized collection of internal setup, deployment, and operational guides used by our team. It is intended to document best practices, step-by-step procedures, and configuration notes for systems we manage, including cloud services, container orchestration, CI/CD, and more. Whether you're onboarding or troubleshooting, these docs should help you get up to speed quickly.

## All Documentation Pages

### Core Docs
- [Basic Packages](./01-basic-packages.md)
- [Server Setup](./02-server-setup.md)
- [Certbot](./certbot.md)
- [Cloudflared](./cloudflared.md)
- [LAMP Setup](./lamp-setup.md)

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

### Jenkins
- [Overview](./jenkins/readme.md)
- [Apache Setup](./jenkins/apache-setup.md)
- [Secrets](./jenkins/secrets.md)
- [Server Setup](./jenkins/server-setup.md)
- [Jenkinsfiles Overview](./jenkins/jenkinsfiles/readme.md)
- [Shared Library Overview](./jenkins/shared-library/README.md)

### Kubernetes
- [Overview](./kubernetes/readme.md)
- [Installation and Commands](./kubernetes/kubernetes-installation-and-commands.md)
- [Manifests Overview](./kubernetes/manifests/README.md)

## Local Preview

To preview locally before pushing:

```bash
npx docsify-cli serve .
```
or using php
```php
php -S localhost:3000 -t .
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
