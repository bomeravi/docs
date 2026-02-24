# Kubernetes: Installation and Common Commands (Windows, Ubuntu, macOS)

This document contains step-by-step installation instructions for Kubernetes on Windows, Ubuntu, and macOS, followed by a compact, practical reference of kubectl/deployment commands and examples optimized for storing manifests in a GitHub repository.

## Overview and recommendations

- For local development: use `minikube`, `kind`, or Docker Desktop Kubernetes (Windows/macOS). For lightweight clusters on WSL2/macOS, `kind` is great. For production clusters: `kubeadm` (Linux) or managed services (EKS/GKE/AKS).
- Store all manifests in git; use Kustomize/Helm for overlays; use GitHub Actions or ArgoCD for deployment automation.

---

## Prerequisites (all OS)

- Docker or container runtime (Docker Desktop, containerd). For `kind` and `minikube`, Docker is recommended.
- `kubectl` (CLI). Install per OS below.
- A GitHub repository to store YAML manifests and CI workflows.

---

## Install on Ubuntu (20.04/22.04)
```bash
sudo swapoff -a
```

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
lsmod | grep br_netfilter
lsmod | grep overlay
```

1. Update packages and install container runtime (Docker):

```bash
sudo apt update && sudo apt install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl status containerd
sudo usermod -aG docker $USER
```

2. Install `kubectl`:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

Doctl needed for digitalocean only,
```bash
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.146.0/doctl-1.146.0-linux-amd64.tar.gz
tar xf ~/doctl-1.146.0-linux-amd64.tar.gz
sudo mv ~/doctl /usr/local/bin
```


3. Install `kubeadm`, `kubelet`, `kubectl` from apt (optional for kubeadm clusters):

```bash
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

4. Create a cluster with `kubeadm` (production/dev Linux cluster):
not needed
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

```bash
sudo kubeadm init
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# Install a CNI, e.g. Calico:
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

To join nodes, use the `kubeadm join` command printed by `kubeadm init`. do not forgot to add sudo if necessary
or generate print command again
```bash
kubeadm token create --print-join-command
```

---

## Install on macOS

Options: Docker Desktop (recommended), Homebrew + minikube, or `kind`.

1. Install Homebrew (if needed):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install `kubectl` and `minikube` or `kind`:

```bash
brew install kubectl
brew install minikube
# or
brew install kind
```

3. Start a local cluster (minikube):

```bash
minikube start --driver=docker
kubectl get nodes
```

Or with `kind`:

```bash
cat <<EOF | kind create cluster --name demo --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
EOF
kubectl cluster-info --context kind-demo
```

Docker Desktop: install the app and enable Kubernetes in Preferences → Kubernetes.

---

## Install on Windows

Recommended paths: Docker Desktop with Kubernetes (for GUI) or WSL2 + `kind`/`minikube`.

1. Install Docker Desktop (Windows 10/11):
- Download from Docker Desktop and enable WSL2 integration and Kubernetes in settings.

2. Install `kubectl` (via Chocolatey or Scoop):

```powershell
# Chocolatey
choco install -y kubernetes-cli
# or Scoop
scoop install kubectl
kubectl version --client
```

3. Using WSL2 (Ubuntu on WSL) + `kind` (recommended for scripting):

```bash
# inside WSL2 Ubuntu
sudo apt update && sudo apt install -y docker.io
# ensure Docker Desktop exposes the daemon or install docker in WSL
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 && chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind
kind create cluster
kubectl cluster-info --context kind-kind
```

---

## Common kubectl workflows and commands (with examples)

Note: Keep declarative YAML in `./manifests/` and use `kubectl apply -f`.

- Create a namespace:

```bash
kubectl create namespace demo
```

- Apply manifests:

```bash
kubectl apply -f manifests/ -n demo
```

- Create a Deployment (imperative):

```bash
kubectl create deployment nginx --image=nginx -n demo
kubectl expose deployment nginx --port=80 --type=ClusterIP -n demo
```

- Useful `kubectl` listing and debugging:

```bash
kubectl get pods -n demo
kubectl get svc -n demo
kubectl describe pod <pod-name> -n demo
kubectl logs <pod-name> -n demo
kubectl exec -it <pod-name> -n demo -- /bin/bash
kubectl port-forward svc/nginx 8080:80 -n demo
kubectl delete -f manifests/ -n demo
kubectl rollout status deployment/nginx -n demo
kubectl rollout undo deployment/nginx -n demo
kubectl scale deployment/nginx --replicas=3 -n demo
```

---

## Example manifests (minimal)

1) `manifests/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
```

2) `manifests/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

Apply both with `kubectl apply -f manifests/`.

---

## ConfigMaps, Secrets, and rolling updates

- Create a ConfigMap from file or literal:

```bash
kubectl create configmap app-config --from-literal=LOG_LEVEL=info -n demo
kubectl create secret generic db-credentials --from-literal=username=admin --from-literal=password='s3cr3t' -n demo
```

- Apply a config change and trigger rolling update by updating Deployment image or env:

```bash
kubectl set image deployment/nginx nginx=nginx:1.25 -n demo
kubectl rollout status deployment/nginx -n demo
```

---

## Helm and Kustomize (brief)

- Helm: package charts and store in `charts/`. Install with:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-redis bitnami/redis -n demo
```

- Kustomize: maintain overlays per environment (base, overlay/dev, overlay/prod). Apply with:

```bash
kustomize build overlays/dev | kubectl apply -f -
# or kubectl apply -k overlays/dev
```

---

## GitHub-optimized repo layout (suggested)

- `manifests/` - base YAMLs (Deployment, Service, Ingress)
- `overlays/dev/`, `overlays/prod/` - Kustomize overlays or Helm values
- `charts/` - Helm charts (if used)
- `.github/workflows/` - CI for lint, test, deploy
- `README.md` - instructions and local dev commands

Keep manifests small, templatize with Helm or Kustomize, and use image tags with CI-driven updates.

---

## Example GitHub Actions snippet (deploy manifests)

Save Kubernetes cluster credentials (kubeconfig) as a repository secret `KUBECONFIG_DATA` (base64-encoded) or use cluster action providers.

`.github/workflows/deploy.yml` (snippet):

```yaml
name: Deploy to Kubernetes
on:
  push:
    branches: [ main ]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'latest'
    - name: Configure kubeconfig
      run: echo "${{ secrets.KUBECONFIG_DATA }}" | base64 --decode > $HOME/.kube/config
    - name: Deploy manifests
      run: kubectl apply -k ./overlays/prod
```

Notes: prefer short-lived credentials or GitHub OIDC for security. For GitOps, push manifests and let ArgoCD watch the repo.

---

## ArgoCD / GitOps recommendation

- Use ArgoCD (or Flux) to continuously deploy from Git:
  - Push YAMLs/Helm charts to `manifests/` or a dedicated `gitops/` repo.
  - ArgoCD syncs cluster state to repo state.

---

## Quick troubleshooting tips

- Check events: `kubectl get events -n <ns>`
- Describe: `kubectl describe pod <pod>` to see pod scheduling or image pull errors
- Node status: `kubectl get nodes` and `kubectl describe node <node>`
- Resource exec/logs: `kubectl exec -it <pod> -- /bin/sh` and `kubectl logs -f <pod>`

---

## Next steps and recommendations

- Commit all YAMLs to Git using the layout above.
- Add CI workflows for linting (`kubeval`, `kustomize` build, `helm lint`) and for deploying to staging via GitHub Actions.
- Consider using `image update` bots or GitHub Actions to automate image tag updates and PRs.

---

If you want, I can:
- add example `manifests/` files directly into the repo,
- create `.github/workflows/deploy.yml` with a full flow, or
- add an `ArgoCD` example app manifest.

Tell me which of those you'd like next.
