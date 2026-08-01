---
pagination_label: AWS
---

# AWS (Amazon Web Services)

Practical guides for provisioning and managing AWS resources.

## Guides

- [EC2](./ec2.md) — launch and configure virtual machines
- [Elastic IP](./elastic-ip.md) — assign static public IPs to EC2 instances
- [IAM](./iam.md) — users, roles, policies, and access keys
- [ECR](./ecr.md) — Elastic Container Registry: push and pull Docker images
- [EKS](./eks.md) — Elastic Kubernetes Service: managed Kubernetes cluster
- [S3](./s3.md) — object storage: buckets, uploads, policies, static sites
- [RDS](./rds.md) — managed relational databases (PostgreSQL, MySQL)

## Prerequisites

- AWS account — https://aws.amazon.com
- AWS CLI installed and configured:

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version

# Configure with access key
aws configure
# AWS Access Key ID: <your-key>
# AWS Secret Access Key: <your-secret>
# Default region: ap-south-1
# Default output format: json
```

- Set region shortcut (optional):

```bash
export AWS_DEFAULT_REGION=ap-south-1
```
