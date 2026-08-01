# ECR (Elastic Container Registry)

ECR is AWS's managed Docker container registry. Store, version, and deploy Docker images privately.

---

## 1. Create a Repository

### Console

1. **ECR → Repositories → Create repository**
2. Choose **Private**
3. Set **Repository name**: e.g. `my-app`
4. Click **Create repository**

### CLI

```bash
aws ecr create-repository \
  --repository-name my-app \
  --region ap-south-1
```

Output includes the `repositoryUri`:
```text
123456789012.dkr.ecr.ap-south-1.amazonaws.com/my-app
```

---

## 2. Authenticate Docker to ECR

Required before push/pull. Token is valid for 12 hours.

```bash
aws ecr get-login-password --region ap-south-1 \
  | docker login --username AWS --password-stdin \
    123456789012.dkr.ecr.ap-south-1.amazonaws.com
```

---

## 3. Build and Push an Image

```bash
# Build
docker build -t my-app .

# Tag with ECR URI
docker tag my-app:latest \
  123456789012.dkr.ecr.ap-south-1.amazonaws.com/my-app:latest

# Push
docker push \
  123456789012.dkr.ecr.ap-south-1.amazonaws.com/my-app:latest
```

---

## 4. Pull an Image

```bash
docker pull \
  123456789012.dkr.ecr.ap-south-1.amazonaws.com/my-app:latest
```

---

## 5. List Images

```bash
aws ecr list-images \
  --repository-name my-app \
  --region ap-south-1
```

---

## 6. Delete an Image

```bash
aws ecr batch-delete-image \
  --repository-name my-app \
  --image-ids imageTag=old-tag \
  --region ap-south-1
```

---

## 7. Lifecycle Policy (Auto-cleanup)

Automatically delete old/untagged images to save storage costs.

```bash
cat > lifecycle-policy.json <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 tagged images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": { "type": "expire" }
    },
    {
      "rulePriority": 2,
      "description": "Remove untagged images older than 1 day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": { "type": "expire" }
    }
  ]
}
EOF

aws ecr put-lifecycle-policy \
  --repository-name my-app \
  --lifecycle-policy-text file://lifecycle-policy.json \
  --region ap-south-1
```

---

## 8. Use in Jenkins Pipeline

```groovy
environment {
    AWS_REGION    = 'ap-south-1'
    AWS_ACCOUNT   = '123456789012'
    ECR_REPO      = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-app"
}

stages {
    stage('Login to ECR') {
        steps {
            sh '''
                aws ecr get-login-password --region $AWS_REGION \
                  | docker login --username AWS --password-stdin \
                    $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com
            '''
        }
    }
    stage('Build & Push') {
        steps {
            sh '''
                docker build -t $ECR_REPO:${BUILD_NUMBER} .
                docker push $ECR_REPO:${BUILD_NUMBER}
                docker tag $ECR_REPO:${BUILD_NUMBER} $ECR_REPO:latest
                docker push $ECR_REPO:latest
            '''
        }
    }
}
```

---

## 9. Use in Kubernetes

```yaml
spec:
  containers:
  - name: my-app
    image: 123456789012.dkr.ecr.ap-south-1.amazonaws.com/my-app:latest
```

For EKS nodes to pull from ECR, attach `AmazonEC2ContainerRegistryReadOnly` policy to the node group IAM role — no image pull secret needed.

---

## IAM Permissions Required

Minimum for push:
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:PutImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`

Or use managed policy: `arn:aws:iam::aws:policy/AmazonECRFullAccess`

---

## Related

- [IAM](./iam.md) — set up push/pull permissions
- [EKS](./eks.md) — deploy images from ECR to Kubernetes
- [Jenkins Agents](../jenkins/agents.md) — run ECR push in CI pipeline
