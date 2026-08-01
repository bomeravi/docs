# IAM (Identity and Access Management)

IAM controls who can access AWS resources and what they can do. Everything in AWS flows through IAM.

---

## Core Concepts

| Concept | Description |
|---------|-------------|
| **User** | Human identity with long-term credentials |
| **Group** | Collection of users sharing the same policies |
| **Role** | Temporary identity assumed by services or users |
| **Policy** | JSON document defining allowed/denied actions |
| **Access Key** | Programmatic credentials (key ID + secret) for CLI/SDK |

---

## 1. Create IAM User

### Console

1. **IAM → Users → Create user**
2. Set username
3. Check **Provide user access to the AWS Management Console** if needed
4. Attach permissions: add to group or attach policy directly
5. Click **Create user**
6. Download credentials CSV or note the password

### CLI

```bash
aws iam create-user --user-name deploy-bot
```

---

## 2. Attach Policy to User

```bash
# Attach AWS managed policy
aws iam attach-user-policy \
  --user-name deploy-bot \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess

# List attached policies
aws iam list-attached-user-policies --user-name deploy-bot
```

---

## 3. Create Access Keys (CLI/SDK Access)

### Console

1. **IAM → Users → select user → Security credentials → Create access key**
2. Use case: **CLI**
3. Download `.csv` — secret shown only once

### CLI

```bash
aws iam create-access-key --user-name deploy-bot
```

Output:
```json
{
    "AccessKey": {
        "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
        "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        "Status": "Active",
        "UserName": "deploy-bot"
    }
}
```

Use with `aws configure` or set environment variables:

```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

---

## 4. IAM Groups

```bash
# Create group
aws iam create-group --group-name developers

# Attach policy to group
aws iam attach-group-policy \
  --group-name developers \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Add user to group
aws iam add-user-to-group --user-name deploy-bot --group-name developers
```

---

## 5. IAM Roles

Roles are assumed by AWS services (EC2, EKS, Lambda) or federated users — no long-term keys needed.

### Create Role for EC2

```bash
# Trust policy (who can assume the role)
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF

# Create role
aws iam create-role \
  --role-name ec2-s3-access \
  --assume-role-policy-document file://trust-policy.json

# Attach policy to role
aws iam attach-role-policy \
  --role-name ec2-s3-access \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create instance profile (required to attach role to EC2)
aws iam create-instance-profile --instance-profile-name ec2-s3-access
aws iam add-role-to-instance-profile \
  --instance-profile-name ec2-s3-access \
  --role-name ec2-s3-access

# Attach to EC2 instance
aws ec2 associate-iam-instance-profile \
  --instance-id i-0123456789abcdef0 \
  --iam-instance-profile Name=ec2-s3-access
```

---

## 6. Custom Policy

```bash
cat > ecr-push-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name ecr-push \
  --policy-document file://ecr-push-policy.json
```

---

## 7. Common AWS Managed Policies

| Policy ARN | Description |
|-----------|-------------|
| `arn:aws:iam::aws:policy/AdministratorAccess` | Full admin (use sparingly) |
| `arn:aws:iam::aws:policy/PowerUserAccess` | Full access except IAM |
| `arn:aws:iam::aws:policy/ReadOnlyAccess` | Read everything |
| `arn:aws:iam::aws:policy/AmazonEC2FullAccess` | Full EC2 |
| `arn:aws:iam::aws:policy/AmazonECRFullAccess` | Full ECR |
| `arn:aws:iam::aws:policy/AmazonEKSClusterPolicy` | EKS cluster management |
| `arn:aws:iam::aws:policy/AmazonS3FullAccess` | Full S3 |
| `arn:aws:iam::aws:policy/AmazonRDSFullAccess` | Full RDS |

---

## 8. Delete Access Key

```bash
aws iam delete-access-key \
  --user-name deploy-bot \
  --access-key-id AKIAIOSFODNN7EXAMPLE
```

---

## Best Practices

- Never use root account for daily work — create an admin IAM user.
- Grant least privilege — only the permissions needed.
- Use roles for EC2/EKS/Lambda — no static keys on servers.
- Rotate access keys regularly.
- Enable MFA on all human users.

---

## Related

- [EC2](./ec2.md) — attach IAM roles to instances
- [ECR](./ecr.md) — IAM policies for image push/pull
- [EKS](./eks.md) — IAM roles for node groups and pods
