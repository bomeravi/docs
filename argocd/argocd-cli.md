# Argo CD CLI

The Argo CD command-line interface (`argocd`) is used to interact with an Argo CD server. It is the primary way to create, manage, and inspect applications from your terminal. This document explains how to install the CLI, configure access, log in, and provides several common usage examples.

---

## Installation

Download the binary for your operating system from the [official release page](https://github.com/argoproj/argo-cd/releases) or install via package managers.

```bash
# Linux example
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# macOS (Homebrew)
brew install argocd
```

Confirm installation:

```bash
argocd version --client
```

---

## Setup & Login

Argo CD uses a TLS connection to its API server. The CLI must be pointed to the server's address and authenticated.

1. **Obtain the API server URL** – typically `https://<ARGOCD_SERVER_HOST>:<PORT>` (e.g., `https://argocd.example.com`).
2. **Login with credentials** – use username/password or token.

```bash
# Basic login
argocd login argocd.example.com

# specify port or insecure
argocd login argocd.example.com:443 --insecure

# using username/password
argocd login argocd.example.com --username admin --password $ARGOCD_PASSWORD

# using a service account token (for automation)
argocd login argocd.example.com --auth-token $ARGOCD_TOKEN
```

> 📌 **Tip:** The default `admin` password is stored as a Kubernetes secret in the Argo CD namespace, e.g. `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`.

Once logged in, the CLI caches credentials in `~/.argocd/config`.

---

## Common Commands

### Application operations

```bash
# list all applications
argocd app list

# get detailed information about an app
argocd app get my-app

# create a new application (example)
argocd app create my-app \
  --repo https://github.com/myorg/myrepo.git \
  --path path/to/chart \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# synchronize (deploy) the application
argocd app sync my-app

# check status
argocd app wait my-app --timeout 120

# delete application
argocd app delete my-app
```

### Projects

```bash
# list projects
argocd proj list

# create a project from a file
argocd proj create -f project.yaml
```

### Settings & user operations

```bash
# change password
argocd account update-password --current-password old --new-password new

# logout
argocd logout argocd.example.com
```

### Cluster management

```bash
# add a new cluster
argocd cluster add <context-name> --name my-cluster

# list connected clusters
argocd cluster list
```

### Secrets

```bash
# generate a new SSH key and add to repo
argocd repo add git@github.com:myorg/myrepo.git --ssh-private-key-path ~/.ssh/id_rsa
```

---

## Examples

### Scripted login & sync

```bash
#!/bin/bash
set -e

ARGOCD_URL=argocd.example.com
ARGOCD_USER=admin
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

argocd login $ARGOCD_URL --username $ARGOCD_USER --password $ARGOCD_PASS --insecure
argocd app sync my-app
```

### Using a config file for app creation (`app.yaml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    path: guestbook
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

```bash
argocd app create -f app.yaml
```

---

## Troubleshooting

* **TLS errors** – use `--insecure` during login or supply certificate via `--grpc-web` and `--certificate` flags.
* **Unauthorized** – check credentials or the API server URL.
* **Connection refused** – ensure Argo CD server is accessible and port is open.

For a complete list of commands and options, run `argocd --help` or consult the [official CLI reference](https://argo-cd.readthedocs.io/en/stable/cli_reference/).

---

Happy deploying with Argo CD! 🎯
