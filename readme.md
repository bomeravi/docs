---
title: Documentation
slug: /
sidebar_position: 1
---

# Documentation

This repository serves as a centralized collection of internal setup, deployment, and operational guides used by our team. It is intended to document best practices, step-by-step procedures, and configuration notes for systems we manage, including cloud services, container orchestration, CI/CD, and more. Whether you're onboarding or troubleshooting, these docs should help you get up to speed quickly.

## 🚀 Start Here

New here? Jump straight into the essentials:

- [Server Setup](./02-server-setup.md) — provision a fresh box
- [Create a Deployer User](./ssh/create-user.md) — CI/CD user + passwordless sudo
- [Docker](./docker/readme.md) — install & Dockerfiles
- [Jenkins](./jenkins/readme.md) — pipelines & Jenkinsfiles
- [Operations](./operations/readme.md) — recovery and monitoring expectations

> 💡 Browse everything from the left sidebar, or press **/** to search.

## 📚 What's Inside

| Area              | Covers                                            |
| ----------------- | ------------------------------------------------- |
| Core / Server     | Base packages, server setup, Certbot, HTTPS, LAMP |
| SSH               | Access, user creation, key generation             |
| Git               | Setup, commands, commit conventions               |
| Docker            | Install + per-stack Dockerfiles                   |
| Jenkins           | CI/CD, Jenkinsfiles, shared library, secrets      |
| Kubernetes        | Install, commands, manifests by stack             |
| Cloud             | DigitalOcean, AWS, Cloudflared                    |
| Infrastructure    | Terraform workflow and state-management guidance  |
| Operations        | Backup/recovery and monitoring/alerting baselines |
| Developer Tools   | Mailpit and other local-dev helpers               |

## Local Preview

To preview locally before pushing:

```bash
npx docsify-cli serve .
```
or using php

```bash
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
