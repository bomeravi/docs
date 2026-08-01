# EKS (Elastic Kubernetes Service)

EKS is AWS's managed Kubernetes service. AWS manages the control plane (API server, etcd); you manage node groups.

---

## Prerequisites

```bash
# Install eksctl
curl --silent --location \
  "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
  | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin

# Verify
eksctl version
kubectl version --client
```

---

## 1. Create a Cluster

### Using eksctl (recommended)

```bash
eksctl create cluster \
  --name my-cluster \
  --region ap-south-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

This creates VPC, subnets, IAM roles, and node group automatically. Takes ~15 minutes.

### Using config file

```yaml
# cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: my-cluster
  region: ap-south-1
  version: "1.30"

managedNodeGroups:
  - name: workers
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 1
    maxSize: 4
    volumeSize: 20
    ssh:
      allow: true
      publicKeyName: my-key-pair
```

```bash
eksctl create cluster -f cluster.yaml
```

---

## 2. Connect kubectl to Cluster

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name my-cluster

# Verify
kubectl get nodes
```

---

## 3. Deploy an Application

```bash
# Deploy from ECR image
kubectl create deployment my-app \
  --image=123456789012.dkr.ecr.ap-south-1.amazonaws.com/my-app:latest

# Expose via LoadBalancer (creates AWS ALB/NLB)
kubectl expose deployment my-app \
  --type=LoadBalancer \
  --port=80 \
  --target-port=3000

# Get external URL
kubectl get svc my-app
```

---

## 4. Managed Node Group Operations

```bash
# List node groups
eksctl get nodegroup --cluster my-cluster --region ap-south-1

# Scale node group
eksctl scale nodegroup \
  --cluster my-cluster \
  --name workers \
  --nodes 4 \
  --region ap-south-1

# Add new node group
eksctl create nodegroup \
  --cluster my-cluster \
  --name workers-v2 \
  --node-type t3.large \
  --nodes 2 \
  --region ap-south-1

# Delete node group
eksctl delete nodegroup \
  --cluster my-cluster \
  --name workers \
  --region ap-south-1
```

---

## 5. IAM OIDC Provider (for Pod-level IAM Roles)

Required for IRSA (IAM Roles for Service Accounts) — lets pods assume IAM roles without static keys.

```bash
# Enable OIDC
eksctl utils associate-iam-oidc-provider \
  --cluster my-cluster \
  --region ap-south-1 \
  --approve

# Create service account with IAM role
eksctl create iamserviceaccount \
  --name my-app-sa \
  --namespace default \
  --cluster my-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve \
  --region ap-south-1
```

Use in pod:
```yaml
spec:
  serviceAccountName: my-app-sa
```

---

## 6. Install AWS Load Balancer Controller

Enables `Ingress` resources to create AWS ALB automatically.

```bash
# Add Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

---

## 7. ECR Image Pull (No Secret Needed)

Attach this policy to the node group IAM role:

```bash
aws iam attach-role-policy \
  --role-name eksctl-my-cluster-nodegroup-workers-NodeInstanceRole-XXXX \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

EKS nodes can now pull from ECR without `imagePullSecrets`.

---

## 8. Cluster Upgrade

```bash
# Upgrade control plane
eksctl upgrade cluster \
  --name my-cluster \
  --version 1.31 \
  --approve \
  --region ap-south-1

# Upgrade node group
eksctl upgrade nodegroup \
  --cluster my-cluster \
  --name workers \
  --kubernetes-version 1.31 \
  --region ap-south-1
```

---

## 9. Delete Cluster

```bash
eksctl delete cluster \
  --name my-cluster \
  --region ap-south-1
```

This removes nodes, node groups, VPC, and IAM roles created by eksctl.

---

## Useful kubectl Commands

```bash
# Node status
kubectl get nodes -o wide

# All pods across namespaces
kubectl get pods -A

# Pod logs
kubectl logs -f deployment/my-app

# Exec into pod
kubectl exec -it <pod-name> -- /bin/bash

# Describe resource
kubectl describe pod <pod-name>
```

---

## Related

- [ECR](./ecr.md) — push images to deploy on EKS
- [IAM](./iam.md) — node group roles and IRSA
- [S3](./s3.md) — persistent storage alternative for stateless apps
