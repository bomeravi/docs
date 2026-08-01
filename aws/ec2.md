# EC2 (Elastic Compute Cloud)

Launch and manage virtual machines on AWS.

---

## 1. Launch an Instance (Console)

1. **EC2 → Instances → Launch instances**
2. Set **Name** for the instance.
3. Choose **AMI**: Ubuntu 24.04 LTS (or Amazon Linux 2023).
4. Choose **Instance type**: `t3.micro` (free tier) or as needed.
5. **Key pair**: create or select existing `.pem` key.
6. **Network settings**:
   - Select or create a VPC and subnet.
   - **Allow SSH (port 22)** from your IP.
   - Add other ports as needed (80, 443, 8080).
7. **Configure storage**: default 8 GB gp3 (increase if needed).
8. Click **Launch instance**.

---

## 2. Launch via AWS CLI

```bash
aws ec2 run-instances \
  --image-id ami-0f58b397bc5c1f2e8 \
  --instance-type t3.micro \
  --key-name my-key-pair \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=my-server}]'
```

---

## 3. Connect via SSH

```bash
# Fix key permissions
chmod 400 my-key.pem

# Connect (Ubuntu AMI)
ssh -i my-key.pem ubuntu@<public-ip>

# Connect (Amazon Linux)
ssh -i my-key.pem ec2-user@<public-ip>
```

---

## 4. Security Groups

Security groups act as a virtual firewall.

### Add inbound rule (CLI)

```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

### Common ports

| Port | Protocol | Use |
|------|----------|-----|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 3306 | TCP | MySQL |
| 5432 | TCP | PostgreSQL |
| 8080 | TCP | Jenkins / App |
| 6443 | TCP | Kubernetes API |

---

## 5. Stop / Start / Terminate

```bash
# Stop (preserves EBS, stops billing for compute)
aws ec2 stop-instances --instance-ids i-0123456789abcdef0

# Start
aws ec2 start-instances --instance-ids i-0123456789abcdef0

# Terminate (destroys instance and root EBS)
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0
```

---

## 6. List Instances

```bash
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

---

## 7. Resize Instance Type

```bash
# 1. Stop instance
aws ec2 stop-instances --instance-ids i-0123456789abcdef0

# 2. Change type
aws ec2 modify-instance-attribute \
  --instance-id i-0123456789abcdef0 \
  --instance-type '{"Value":"t3.medium"}'

# 3. Start
aws ec2 start-instances --instance-ids i-0123456789abcdef0
```

---

## 8. User Data (Bootstrap Script)

Run commands on first boot:

```bash
aws ec2 run-instances \
  --image-id ami-0f58b397bc5c1f2e8 \
  --instance-type t3.micro \
  --key-name my-key-pair \
  --user-data file://bootstrap.sh \
  ...
```

`bootstrap.sh`:
```bash
#!/bin/bash
apt update -y
apt install -y nginx
systemctl enable --now nginx
```

---

## Related

- [Elastic IP](./elastic-ip.md) — assign static IP to this instance
- [IAM](./iam.md) — attach IAM role to instance for AWS service access
- [Security Groups](./ec2.md) — port rules
