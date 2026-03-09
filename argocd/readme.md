# ArgoCD 

### Description

Argo CD is a GitOps continuous delivery tool for Kubernetes. It watches your Git repository for application and infrastructure manifests, then keeps the cluster state synchronized with what is defined in Git.

This guide documents a basic Argo CD setup with Helm, cert-manager `ClusterIssuer`, and HTTPS ingress so you can securely access the Argo CD UI.

### Installation


Install Helm (on local, not on kubernites)
method 1
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
```

method 2:
```bash
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

### Setup

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```


Install cert manager
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```


add ingress
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

```bash
kubectl get svc -n ingress-nginx
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

```bash
kubectl get ingress -n argocd
```


```bash
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.19.4 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
```

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: bomeravi@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```




### Setup Https

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - argocd.digi.saroj.name.np
    secretName: argocd-tls
  rules:
  - host: argocd.digi.saroj.name.np
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF
```

Get Initial Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### Docs App (GitOps Flow)

For the docs deployment (`docs.digi-kube.sajiloapps.com`) this repo now includes:

- `k8s/kubernetes/` for app manifests (Deployment, Service, Ingress, TLS issuer)
- `k8s/argocd/01-application.yaml` for the Argo CD `Application`

Update `repoURL` in `k8s/argocd/01-application.yaml`, then apply:

```bash
kubectl apply -f k8s/argocd/01-application.yaml
```

Recommended branch mapping:

- `jenkins` branch for direct Jenkins + kubectl pipeline
- `argocd` branch for Argo CD sync (`targetRevision: argocd`)
