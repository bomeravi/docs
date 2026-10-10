# AWS Disaster Recovery (AZ and Region Outages)

How to keep an AWS workload running when a **data center (Availability Zone)**
or an **entire Region** goes down — service by service, with the CLI commands
to set up replication, test failover, and fail back.

> Examples use **`ap-south-1` (Mumbai)** as the primary Region and
> **`ap-southeast-1` (Singapore)** as the DR Region. Replace `123456789012`
> with your account ID.

---

## Table of Contents

- [Concepts](#concepts)
- [Reference Architecture](#reference-architecture)
- [Part A — Surviving an AZ (Data Center) Outage](#part-a-surviving-an-az-data-center-outage)
  - [A1. VPC Across Three AZs](#a1-vpc-across-three-azs)
  - [A2. EC2 Auto Scaling + ALB](#a2-ec2-auto-scaling-alb)
  - [A3. RDS Multi-AZ](#a3-rds-multi-az)
  - [A4. ElastiCache (Redis/Valkey) Multi-AZ](#a4-elasticache-redisvalkey-multi-az)
  - [A5. EKS / ECS Across AZs](#a5-eks-ecs-across-azs)
  - [A6. Storage: S3, EFS, EBS](#a6-storage-s3-efs-ebs)
- [Part B — Surviving a Region Outage](#part-b-surviving-a-region-outage)
  - [B1. S3 Cross-Region Replication](#b1-s3-cross-region-replication)
  - [B2. RDS Cross-Region Read Replica](#b2-rds-cross-region-read-replica)
  - [B3. Aurora Global Database](#b3-aurora-global-database)
  - [B4. DynamoDB Global Tables](#b4-dynamodb-global-tables)
  - [B5. ElastiCache Global Datastore](#b5-elasticache-global-datastore)
  - [B6. EBS Snapshots and AMIs](#b6-ebs-snapshots-and-amis)
  - [B7. EFS Replication](#b7-efs-replication)
  - [B8. AWS Backup Cross-Region Copies](#b8-aws-backup-cross-region-copies)
  - [B9. ECR, Secrets Manager, KMS, Parameter Store](#b9-ecr-secrets-manager-kms-parameter-store)
  - [B10. Compute in the DR Region (IaC)](#b10-compute-in-the-dr-region-iac)
  - [B11. Route 53 Failover Routing](#b11-route-53-failover-routing)
  - [B12. CloudFront Origin Failover](#b12-cloudfront-origin-failover)
- [Monitoring and Alarms](#monitoring-and-alarms)
- [Region Failover Runbook](#region-failover-runbook)
- [Failback](#failback)
- [Testing (Game Days and AWS FIS)](#testing-game-days-and-aws-fis)
- [Security Checklist](#security-checklist)
- [Summary: Service-by-Service](#summary-service-by-service)

---

## Concepts

| Failure            | What happens                                     | Protection                                 |
| ------------------ | ------------------------------------------------ | ------------------------------------------ |
| Instance / host    | One server dies                                  | Auto Scaling, health checks                |
| **AZ (data center)** | Power/network loss in one AZ of a Region       | **Multi-AZ** — spread everything over ≥2 (ideally 3) AZs |
| **Region**         | Whole Region (or a key regional service) impaired | **Multi-Region** — replicate data + IaC for a second Region |
| Data corruption / deletion | Bad deploy, `DROP TABLE`, ransomware     | **Backups** with point-in-time restore (replication copies the damage) |

### DR strategies (AWS Well-Architected)

| Strategy              | DR Region state                                   | RPO           | RTO          | Cost     |
| --------------------- | ------------------------------------------------- | ------------- | ------------ | -------- |
| **Backup & restore**  | Only backups/snapshots copied                     | Hours         | Hours–day    | $        |
| **Pilot light**       | Data replicated live; compute off / minimal       | Seconds–min   | 10s of min   | $$       |
| **Warm standby**      | Data replicated; scaled-down app running          | Seconds       | Minutes      | $$$      |
| **Multi-site active/active** | Full stack serving traffic in both Regions | ~0            | ~0           | $$$$     |

> Every production workload should be **Multi-AZ**. Choose a multi-Region
> strategy based on how much downtime and data loss the business can accept.

---

## Reference Architecture

```text
                    Route 53 (failover / latency routing + health checks)
                         │                                   │
          ┌──────────────▼──────────────┐     ┌──────────────▼──────────────┐
          │   ap-south-1  (PRIMARY)     │     │   ap-southeast-1  (DR)      │
          │                             │     │                             │
          │   ALB (AZ a | b | c)        │     │   ALB (AZ a | b | c)        │
          │   ASG / EKS nodes in 3 AZs  │     │   ASG / EKS (min size)      │
          │                             │     │                             │
          │   RDS Multi-AZ / Aurora ────┼────►│   Read replica / Aurora 2nd │
          │   ElastiCache Multi-AZ ─────┼────►│   Global Datastore replica  │
          │   DynamoDB ◄────────────────┼────►│   DynamoDB (global table)   │
          │   S3 bucket ────────────────┼────►│   S3 bucket (CRR)           │
          │   EFS ──────────────────────┼────►│   EFS replica               │
          │   ECR / Secrets / KMS ──────┼────►│   replicas                  │
          │   AWS Backup vault ─────────┼────►│   Backup vault (copies)     │
          └─────────────────────────────┘     └─────────────────────────────┘
```

---

## Part A — Surviving an AZ (Data Center) Outage

### A1. VPC Across Three AZs

Create one public and one private subnet **per AZ**, and one NAT Gateway
**per AZ** (a single NAT Gateway is a single point of failure for outbound
traffic).

```bash
aws ec2 describe-availability-zones --region ap-south-1 \
  --query 'AvailabilityZones[].ZoneName' --output text
```

```bash
VPC_ID=vpc-0abc123

aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.11.0/24 --availability-zone ap-south-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-a}]'
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.12.0/24 --availability-zone ap-south-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-b}]'
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.13.0/24 --availability-zone ap-south-1c \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-c}]'
```

```bash
# NAT Gateway per AZ (repeat for b and c with their public subnets)
EIP=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)
aws ec2 create-nat-gateway --subnet-id subnet-public-a --allocation-id $EIP \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=nat-a}]'
```

Each private subnet's route table points `0.0.0.0/0` at the NAT Gateway in
**its own AZ**.

---

### A2. EC2 Auto Scaling + ALB

The ALB spans all AZs and stops sending traffic to unhealthy targets; the
Auto Scaling group replaces lost capacity in the remaining AZs.

```bash
# Target group with a real health check endpoint
aws elbv2 create-target-group --name app-tg --protocol HTTP --port 80 \
  --vpc-id $VPC_ID --health-check-path /health \
  --health-check-interval-seconds 15 --healthy-threshold-count 2 --unhealthy-threshold-count 3

# ALB in public subnets of all three AZs
aws elbv2 create-load-balancer --name app-alb --type application \
  --subnets subnet-public-a subnet-public-b subnet-public-c \
  --security-groups sg-alb
```

```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name app-asg \
  --launch-template 'LaunchTemplateName=app-lt,Version=$Latest' \
  --vpc-zone-identifier "subnet-private-a,subnet-private-b,subnet-private-c" \
  --min-size 3 --max-size 12 --desired-capacity 3 \
  --target-group-arns arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/app-tg/abc123 \
  --health-check-type ELB --health-check-grace-period 120
```

> **Size for N-1 AZs.** If you need 6 instances to serve peak traffic, run at
> least 9 across 3 AZs (3 per AZ) so losing one AZ still leaves 6. Enable
> **AZ rebalancing** (on by default) and consider **zonal shift** in Route 53
> ARC to move traffic away from a degraded AZ:

```bash
aws arc-zonal-shift start-zonal-shift \
  --resource-identifier arn:aws:elasticloadbalancing:ap-south-1:123456789012:loadbalancer/app/app-alb/abc123 \
  --away-from aps1-az1 --expires-in 2h --comment "AZ impairment"
```

---

### A3. RDS Multi-AZ

A synchronous standby in another AZ; RDS fails over automatically (typically
60–120 s) and the endpoint DNS name stays the same.

```bash
# New instance
aws rds create-db-instance --db-instance-identifier app-db \
  --engine postgres --db-instance-class db.m6g.large --allocated-storage 100 \
  --master-username dbadmin --manage-master-user-password \
  --multi-az --storage-encrypted --backup-retention-period 7 \
  --db-subnet-group-name app-db-subnets --vpc-security-group-ids sg-db \
  --deletion-protection

# Existing instance
aws rds modify-db-instance --db-instance-identifier app-db --multi-az --apply-immediately
```

Test the failover:

```bash
aws rds reboot-db-instance --db-instance-identifier app-db --force-failover
aws rds describe-events --source-identifier app-db --source-type db-instance --duration 60
```

> **Multi-AZ DB cluster** (2 readable standbys, ~35 s failover) and **Aurora**
> (storage replicated across 3 AZs, add a reader in another AZ for fast
> failover) are stronger options. Apps must reconnect on failure — use
> connection retry logic or **RDS Proxy**.

---

### A4. ElastiCache (Redis/Valkey) Multi-AZ

```bash
aws elasticache create-replication-group \
  --replication-group-id app-redis \
  --replication-group-description "App cache" \
  --engine redis --cache-node-type cache.m6g.large \
  --num-node-groups 1 --replicas-per-node-group 2 \
  --automatic-failover-enabled --multi-az-enabled \
  --transit-encryption-enabled --at-rest-encryption-enabled \
  --cache-subnet-group-name app-cache-subnets --security-group-ids sg-cache
```

Test failover:

```bash
aws elasticache test-failover --replication-group-id app-redis --node-group-id 0001
```

Always connect to the **primary endpoint** (or configuration endpoint in
cluster mode), never to a node endpoint.

---

### A5. EKS / ECS Across AZs

**EKS** — managed node groups across all private subnets, and spread pods:

```bash
eksctl create nodegroup --cluster app-cluster --name ng-app \
  --node-type m6i.large --nodes 3 --nodes-min 3 --nodes-max 12 \
  --node-private-networking --subnet-ids subnet-private-a,subnet-private-b,subnet-private-c
```

```yaml
# In the Deployment spec
spec:
  replicas: 6
  template:
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: web
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 4
  selector:
    matchLabels:
      app: web
```

> EBS-backed PersistentVolumes are **AZ-bound** — a pod using one cannot move
> to another AZ. Prefer RDS/EFS/S3 for state, or use EFS (`efs.csi.aws.com`).

**ECS (Fargate)** — pass subnets in all AZs; ECS spreads tasks across AZs by
default:

```bash
aws ecs create-service --cluster app --service-name web --task-definition web:1 \
  --desired-count 6 --launch-type FARGATE \
  --network-configuration 'awsvpcConfiguration={subnets=[subnet-private-a,subnet-private-b,subnet-private-c],securityGroups=[sg-app]}' \
  --load-balancers 'targetGroupArn=arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/app-tg/abc123,containerName=web,containerPort=80'
```

---

### A6. Storage: S3, EFS, EBS

| Service | AZ resilience                                                      |
| ------- | ------------------------------------------------------------------ |
| **S3** (Standard) | Stored across ≥3 AZs automatically. Avoid **One Zone-IA** for critical data |
| **EFS** (Regional) | Stored across multiple AZs; create a mount target in **every** AZ |
| **EBS** | Lives in **one AZ**. Take snapshots (stored regionally) and keep stateless instances |

```bash
# EFS mount target per AZ
for s in subnet-private-a subnet-private-b subnet-private-c; do
  aws efs create-mount-target --file-system-id fs-0abc123 --subnet-id $s --security-groups sg-efs
done
```

```bash
# Automated EBS snapshots via Data Lifecycle Manager (daily, keep 7)
aws dlm create-lifecycle-policy --description "daily-ebs" --state ENABLED \
  --execution-role-arn arn:aws:iam::123456789012:role/AWSDataLifecycleManagerDefaultRole \
  --policy-details '{
    "ResourceTypes":["VOLUME"],
    "TargetTags":[{"Key":"backup","Value":"daily"}],
    "Schedules":[{"Name":"daily","CreateRule":{"Interval":24,"IntervalUnit":"HOURS","Times":["20:00"]},
                  "RetainRule":{"Count":7},"CopyTags":true}]
  }'
```

---

## Part B — Surviving a Region Outage

### B1. S3 Cross-Region Replication

**1. Create the DR bucket and enable versioning on both:**

```bash
aws s3api create-bucket --bucket app-uploads-dr --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

aws s3api put-bucket-versioning --bucket app-uploads    --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning --bucket app-uploads-dr --versioning-configuration Status=Enabled
```

**2. IAM role for replication** — trust policy `s3-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "s3.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

Permissions `s3-crr-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetReplicationConfiguration", "s3:ListBucket"],
      "Resource": "arn:aws:s3:::app-uploads"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"],
      "Resource": "arn:aws:s3:::app-uploads/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"],
      "Resource": "arn:aws:s3:::app-uploads-dr/*"
    }
  ]
}
```

```bash
aws iam create-role --role-name s3-crr-role --assume-role-policy-document file://s3-trust.json
aws iam put-role-policy --role-name s3-crr-role --policy-name s3-crr --policy-document file://s3-crr-policy.json
```

**3. Replication rule** `replication.json` (with Replication Time Control —
99.99 % of objects within 15 minutes):

```json
{
  "Role": "arn:aws:iam::123456789012:role/s3-crr-role",
  "Rules": [{
    "ID": "crr-all",
    "Status": "Enabled",
    "Priority": 1,
    "Filter": {},
    "DeleteMarkerReplication": { "Status": "Disabled" },
    "Destination": {
      "Bucket": "arn:aws:s3:::app-uploads-dr",
      "StorageClass": "STANDARD",
      "ReplicationTime": { "Status": "Enabled", "Time": { "Minutes": 15 } },
      "Metrics": { "Status": "Enabled", "EventThreshold": { "Minutes": 15 } }
    }
  }]
}
```

```bash
aws s3api put-bucket-replication --bucket app-uploads --replication-configuration file://replication.json
aws s3api get-bucket-replication --bucket app-uploads
```

> - Replication applies to **new** objects. Copy existing ones with **S3
>   Batch Replication**.
> - `DeleteMarkerReplication: Disabled` keeps accidental deletes in the
>   primary from removing objects in DR.
> - For SSE-KMS objects add `SourceSelectionCriteria.SseKmsEncryptedObjects`
>   and `Destination.EncryptionConfiguration.ReplicaKmsKeyID` (a key in the DR
>   Region), and grant the role `kms:Decrypt` / `kms:Encrypt`.
> - Use **S3 Multi-Region Access Points** if the app should switch buckets
>   without a config change.

---

### B2. RDS Cross-Region Read Replica

For RDS MySQL / MariaDB / PostgreSQL / Oracle / SQL Server (asynchronous).

```bash
aws rds create-db-instance-read-replica \
  --region ap-southeast-1 \
  --db-instance-identifier app-db-dr \
  --source-db-instance-identifier arn:aws:rds:ap-south-1:123456789012:db:app-db \
  --db-instance-class db.m6g.large \
  --db-subnet-group-name app-db-subnets-dr \
  --vpc-security-group-ids sg-db-dr \
  --kms-key-id arn:aws:kms:ap-southeast-1:123456789012:key/<dr-key-id> \
  --multi-az
```

> Encrypted sources need `--kms-key-id` from the **DR Region**. The DB subnet
> group and security group must already exist there.

Check lag:

```bash
aws cloudwatch get-metric-statistics --region ap-southeast-1 \
  --namespace AWS/RDS --metric-name ReplicaLag \
  --dimensions Name=DBInstanceIdentifier,Value=app-db-dr \
  --start-time $(date -u -d '-15 min' +%FT%TZ) --end-time $(date -u +%FT%TZ) \
  --period 60 --statistics Maximum
```

**Promote during a Region outage** (one-way — it becomes a standalone writable
DB):

```bash
aws rds promote-read-replica --region ap-southeast-1 \
  --db-instance-identifier app-db-dr --backup-retention-period 7
aws rds wait db-instance-available --region ap-southeast-1 --db-instance-identifier app-db-dr
```

> Cheaper alternative (backup & restore): copy automated backups to the DR
> Region with
> `aws rds start-db-instance-automated-backups-replication --region ap-southeast-1 --source-db-instance-arn <arn> --backup-retention-period 7`
> and restore with point-in-time recovery when needed.

---

### B3. Aurora Global Database

Storage-level replication, typically **< 1 s** lag, managed cross-Region
failover.

```bash
# 1. Turn the existing primary cluster into a global database
aws rds create-global-cluster --region ap-south-1 \
  --global-cluster-identifier app-global \
  --source-db-cluster-identifier arn:aws:rds:ap-south-1:123456789012:cluster:app-aurora

# 2. Add a secondary cluster in the DR Region
aws rds create-db-cluster --region ap-southeast-1 \
  --db-cluster-identifier app-aurora-dr \
  --global-cluster-identifier app-global \
  --engine aurora-postgresql --engine-version 16.4 \
  --db-subnet-group-name app-db-subnets-dr --vpc-security-group-ids sg-db-dr \
  --kms-key-id arn:aws:kms:ap-southeast-1:123456789012:key/<dr-key-id>

# 3. Add at least one instance to the secondary cluster
aws rds create-db-instance --region ap-southeast-1 \
  --db-instance-identifier app-aurora-dr-1 --db-cluster-identifier app-aurora-dr \
  --engine aurora-postgresql --db-instance-class db.r6g.large
```

> The engine and version must match the primary cluster.

**Planned switchover** (both Regions healthy, no data loss):

```bash
aws rds switchover-global-cluster --region ap-south-1 \
  --global-cluster-identifier app-global \
  --target-db-cluster-identifier arn:aws:rds:ap-southeast-1:123456789012:cluster:app-aurora-dr
```

**Unplanned failover** (primary Region down — may lose the last seconds of
writes):

```bash
aws rds failover-global-cluster --region ap-southeast-1 \
  --global-cluster-identifier app-global \
  --target-db-cluster-identifier arn:aws:rds:ap-southeast-1:123456789012:cluster:app-aurora-dr \
  --allow-data-loss
```

Lag metric: `AuroraGlobalDBReplicationLag` (ms) in `AWS/RDS`.

---

### B4. DynamoDB Global Tables

Multi-Region, **active-active**: each Region accepts writes, last writer wins.

```bash
aws dynamodb update-table --region ap-south-1 --table-name Orders \
  --replica-updates '[{"Create": {"RegionName": "ap-southeast-1"}}]'

aws dynamodb describe-table --region ap-south-1 --table-name Orders \
  --query 'Table.Replicas'
```

Also enable point-in-time recovery (replication does not protect against bad
writes):

```bash
aws dynamodb update-continuous-backups --region ap-south-1 --table-name Orders \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

> Design for conflicts: avoid having two Regions update the same item at the
> same time (e.g. route each user to a "home" Region), or use **multi-Region
> strong consistency** where available. Lag metric: `ReplicationLatency`.

---

### B5. ElastiCache Global Datastore

```bash
# 1. Make the existing replication group the global primary
aws elasticache create-global-replication-group --region ap-south-1 \
  --global-replication-group-id-suffix app-redis \
  --primary-replication-group-id app-redis

# AWS prefixes the ID; get the full one
aws elasticache describe-global-replication-groups --region ap-south-1 \
  --query 'GlobalReplicationGroups[].GlobalReplicationGroupId'

# 2. Create the secondary in the DR Region
aws elasticache create-replication-group --region ap-southeast-1 \
  --replication-group-id app-redis-dr \
  --replication-group-description "DR cache" \
  --global-replication-group-id <full-global-id> \
  --cache-subnet-group-name app-cache-subnets-dr --security-group-ids sg-cache-dr
```

Promote the DR Region:

```bash
aws elasticache failover-global-replication-group --region ap-south-1 \
  --global-replication-group-id <full-global-id> \
  --primary-region ap-southeast-1 \
  --primary-replication-group-id app-redis-dr
```

> If the cache is only a cache, you can skip this — start an empty cluster in
> DR and let it warm up. Replicate only if the app keeps sessions or queues in
> Redis.

---

### B6. EBS Snapshots and AMIs

```bash
# Copy a snapshot to the DR Region (encrypted with a DR-Region key)
aws ec2 copy-snapshot --region ap-southeast-1 \
  --source-region ap-south-1 --source-snapshot-id snap-0abc123 \
  --encrypted --kms-key-id arn:aws:kms:ap-southeast-1:123456789012:key/<dr-key-id> \
  --description "DR copy of app data"

# Copy the golden AMI used by the launch template
aws ec2 copy-image --region ap-southeast-1 \
  --source-region ap-south-1 --source-image-id ami-0abc123 \
  --name "app-golden-$(date +%F)" --encrypted \
  --kms-key-id arn:aws:kms:ap-southeast-1:123456789012:key/<dr-key-id>
```

> Automate copies with a DLM policy `CrossRegionCopyRules` block, or with
> AWS Backup (B8). Rebuild the AMI pipeline (EC2 Image Builder) to distribute
> to both Regions.

---

### B7. EFS Replication

```bash
aws efs create-replication-configuration --region ap-south-1 \
  --source-file-system-id fs-0abc123 \
  --destinations Region=ap-southeast-1,KmsKeyId=arn:aws:kms:ap-southeast-1:123456789012:key/<dr-key-id>

aws efs describe-replication-configurations --region ap-south-1 --file-system-id fs-0abc123
```

The replica is **read-only** until you delete the replication configuration
(failover). RPO is typically minutes (`TimeSinceLastSync` metric).

```bash
# Failover: make the DR copy writable
aws efs delete-replication-configuration --region ap-south-1 --source-file-system-id fs-0abc123
```

---

### B8. AWS Backup Cross-Region Copies

Central backups for RDS, Aurora, DynamoDB, EBS, EFS, S3 and more — copied to a
vault in the DR Region (and ideally a separate backup account).

```bash
aws backup create-backup-vault --region ap-southeast-1 --backup-vault-name prod-vault-dr \
  --encryption-key-arn arn:aws:kms:ap-southeast-1:123456789012:key/<dr-key-id>

# Immutable retention (WORM) — cannot be deleted, even by admins, before 7 days
aws backup put-backup-vault-lock-configuration --region ap-southeast-1 \
  --backup-vault-name prod-vault-dr --min-retention-days 7 --max-retention-days 365
```

`plan.json`:

```json
{
  "BackupPlanName": "prod-daily-dr",
  "Rules": [{
    "RuleName": "daily",
    "TargetBackupVaultName": "prod-vault",
    "ScheduleExpression": "cron(0 20 * * ? *)",
    "StartWindowMinutes": 60,
    "CompletionWindowMinutes": 180,
    "Lifecycle": { "DeleteAfterDays": 35 },
    "CopyActions": [{
      "DestinationBackupVaultArn": "arn:aws:backup:ap-southeast-1:123456789012:backup-vault:prod-vault-dr",
      "Lifecycle": { "DeleteAfterDays": 35 }
    }]
  }]
}
```

```bash
PLAN_ID=$(aws backup create-backup-plan --region ap-south-1 \
  --backup-plan file://plan.json --query BackupPlanId --output text)

# Back up every resource tagged backup=daily
aws backup create-backup-selection --region ap-south-1 --backup-plan-id $PLAN_ID \
  --backup-selection '{
    "SelectionName": "tagged-daily",
    "IamRoleArn": "arn:aws:iam::123456789012:role/service-role/AWSBackupDefaultServiceRole",
    "ListOfTags": [{"ConditionType":"STRINGEQUALS","ConditionKey":"backup","ConditionValue":"daily"}]
  }'
```

Restore testing can be automated with **AWS Backup restore testing** plans.

---

### B9. ECR, Secrets Manager, KMS, Parameter Store

**ECR** — replicate images so DR clusters can pull:

```bash
aws ecr put-replication-configuration --region ap-south-1 \
  --replication-configuration '{
    "rules": [{ "destinations": [{ "region": "ap-southeast-1", "registryId": "123456789012" }] }]
  }'
```

**KMS** — multi-Region keys keep the same key material/ID in both Regions:

```bash
KEY_ID=$(aws kms create-key --region ap-south-1 --multi-region \
  --description "app multi-region key" --query KeyMetadata.KeyId --output text)
aws kms replicate-key --region ap-south-1 --key-id $KEY_ID --replica-region ap-southeast-1
```

**Secrets Manager** — replicas stay in sync with the primary:

```bash
aws secretsmanager replicate-secret-to-regions --region ap-south-1 \
  --secret-id prod/app/db \
  --add-replica-regions Region=ap-southeast-1,KmsKeyId=$KEY_ID
```

Promote a replica to standalone during a Region outage:

```bash
aws secretsmanager stop-replication-to-replica --region ap-southeast-1 --secret-id prod/app/db
```

**SSM Parameter Store** has no native replication — copy parameters with a
script (or manage them in Terraform for both Regions):

```bash
aws ssm get-parameters-by-path --region ap-south-1 --path /prod/app --recursive --with-decryption \
  --query 'Parameters[].[Name,Type,Value]' --output text |
while IFS=$'\t' read -r name type value; do
  aws ssm put-parameter --region ap-southeast-1 --name "$name" --type "$type" --value "$value" --overwrite
done
```

> Also replicate **ACM certificates** (request a cert in each Region — ALB
> certs are regional; CloudFront uses `us-east-1`), **IAM** is global, and
> **CloudWatch alarms / EventBridge rules** must be created in each Region.

---

### B10. Compute in the DR Region (IaC)

Keep the whole stack in Terraform (see [Terraform](../terraform/readme.md)) so the DR
Region is a second instance of the same code, not a hand-built copy.

```hcl
provider "aws" {
  alias  = "primary"
  region = "ap-south-1"
}

provider "aws" {
  alias  = "dr"
  region = "ap-southeast-1"
}

module "app_primary" {
  source    = "./modules/app"
  providers = { aws = aws.primary }
  min_size  = 3
  desired   = 3
}

module "app_dr" {
  source    = "./modules/app"
  providers = { aws = aws.dr }
  min_size  = 0   # pilot light: 0, warm standby: 1–2
  desired   = 0
}
```

Scale up DR compute during failover:

```bash
aws autoscaling update-auto-scaling-group --region ap-southeast-1 \
  --auto-scaling-group-name app-asg --min-size 3 --desired-capacity 6

# EKS
eksctl scale nodegroup --region ap-southeast-1 --cluster app-cluster-dr --name ng-app --nodes 6

# ECS
aws ecs update-service --region ap-southeast-1 --cluster app --service web --desired-count 6
```

> Check **service quotas** (vCPU, EIPs, NAT Gateways) in the DR Region now —
> a Region outage is the worst time to wait for a quota increase.

---

### B11. Route 53 Failover Routing

**1. Health check on the primary ALB** (`hc.json`):

```json
{
  "Type": "HTTPS",
  "FullyQualifiedDomainName": "app-alb-123.ap-south-1.elb.amazonaws.com",
  "Port": 443,
  "ResourcePath": "/health",
  "RequestInterval": 30,
  "FailureThreshold": 3
}
```

```bash
HC_ID=$(aws route53 create-health-check --caller-reference "app-primary-$(date +%s)" \
  --health-check-config file://hc.json --query HealthCheck.Id --output text)
```

**2. Get each ALB's DNS name and hosted zone ID:**

```bash
aws elbv2 describe-load-balancers --region ap-south-1 --names app-alb \
  --query 'LoadBalancers[0].[DNSName,CanonicalHostedZoneId]' --output text
aws elbv2 describe-load-balancers --region ap-southeast-1 --names app-alb \
  --query 'LoadBalancers[0].[DNSName,CanonicalHostedZoneId]' --output text
```

**3. PRIMARY / SECONDARY records** (`failover.json`):

```json
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "app.example.com",
        "Type": "A",
        "SetIdentifier": "primary-ap-south-1",
        "Failover": "PRIMARY",
        "HealthCheckId": "<HC_ID>",
        "AliasTarget": {
          "HostedZoneId": "<PRIMARY_ALB_ZONE_ID>",
          "DNSName": "app-alb-123.ap-south-1.elb.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "app.example.com",
        "Type": "A",
        "SetIdentifier": "secondary-ap-southeast-1",
        "Failover": "SECONDARY",
        "AliasTarget": {
          "HostedZoneId": "<DR_ALB_ZONE_ID>",
          "DNSName": "app-alb-456.ap-southeast-1.elb.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
```

```bash
aws route53 change-resource-record-sets --hosted-zone-id Z0123456789ABC --change-batch file://failover.json
aws route53 get-health-check-status --health-check-id $HC_ID
```

> - Make `/health` check real dependencies (DB reachable), but keep it fast.
> - For **active/active**, use **latency-based** routing with a health check
>   on each record instead of failover routing.
> - For a deliberate, human-controlled switch that does not depend on the
>   impaired Region's control plane, use **Route 53 ARC routing controls**
>   (data-plane operations work even when a Region's console/API is down).

---

### B12. CloudFront Origin Failover

For static sites and assets served from S3 (or two ALBs): create an **origin
group** with the primary bucket and the DR bucket. CloudFront retries the
secondary origin when the primary returns 5xx/403/404 or times out.

```json
"OriginGroups": {
  "Quantity": 1,
  "Items": [{
    "Id": "s3-failover-group",
    "FailoverCriteria": { "StatusCodes": { "Quantity": 4, "Items": [500, 502, 503, 504] } },
    "Members": {
      "Quantity": 2,
      "Items": [{ "OriginId": "s3-primary-ap-south-1" }, { "OriginId": "s3-dr-ap-southeast-1" }]
    }
  }]
}
```

Point the cache behaviour's `TargetOriginId` at `s3-failover-group`. (Origin
groups serve GET/HEAD/OPTIONS only.)

---

## Monitoring and Alarms

Create alarms in the Region where the metric lives, and send them to an SNS
topic that pages the on-call engineer. See
[Monitoring and Alerting](../operations/monitoring-alerting.md).

| Metric                           | Namespace / Region         | Alarm when                    |
| -------------------------------- | -------------------------- | ----------------------------- |
| `ReplicaLag`                     | `AWS/RDS`, DR Region       | > 60 s for 5 min              |
| `AuroraGlobalDBReplicationLag`   | `AWS/RDS`, DR Region       | > 5000 ms                     |
| `ReplicationLatency`             | `AWS/DynamoDB`             | > 60000 ms                    |
| `ReplicationLatency` / `OperationsFailedReplication` | `AWS/S3` (RTC metrics) | > 900 s / > 0 |
| `TimeSinceLastSync`              | `AWS/EFS`                  | > 3600 s                      |
| `HealthCheckStatus`              | `AWS/Route53`, **us-east-1** | < 1                         |
| `UnHealthyHostCount`             | `AWS/ApplicationELB`       | > 0 for 5 min                 |

Example — RDS replica lag:

```bash
aws cloudwatch put-metric-alarm --region ap-southeast-1 \
  --alarm-name app-db-dr-replica-lag \
  --namespace AWS/RDS --metric-name ReplicaLag \
  --dimensions Name=DBInstanceIdentifier,Value=app-db-dr \
  --statistic Maximum --period 60 --evaluation-periods 5 \
  --threshold 60 --comparison-operator GreaterThanThreshold \
  --treat-missing-data breaching \
  --alarm-actions arn:aws:sns:ap-southeast-1:123456789012:oncall
```

Get notified of AWS-side incidents (AWS Health events) via EventBridge:

```bash
aws events put-rule --region ap-south-1 --name aws-health-events \
  --event-pattern '{"source":["aws.health"]}'
aws events put-targets --region ap-south-1 --rule aws-health-events \
  --targets 'Id=sns,Arn=arn:aws:sns:ap-south-1:123456789012:oncall'
```

> Put the alarm/notification path for the **primary** Region in the **DR**
> Region too — if the primary Region is down, its alarms may not fire.

---

## Region Failover Runbook

> ⚠️ Decide in advance **who** can declare a Region failover and at what
> threshold (e.g. primary impaired > 30 min per AWS Health + own checks).
> Region failover is rarely reversible in minutes.

1. **Confirm the outage** — AWS Health Dashboard, your Route 53 health checks,
   synthetic checks from outside AWS. An AZ issue is handled by Multi-AZ; do
   **not** fail over the Region for it.
2. **Freeze deploys** and announce the incident.
3. **Stop writes to the primary** if it is partially reachable (scale ASG to
   0, set app to maintenance mode) to avoid split-brain.
4. **Promote data stores in the DR Region:**

   | Service      | Command                                                                     |
   | ------------ | --------------------------------------------------------------------------- |
   | Aurora global| `aws rds failover-global-cluster … --allow-data-loss`                       |
   | RDS replica  | `aws rds promote-read-replica --region ap-southeast-1 --db-instance-identifier app-db-dr` |
   | ElastiCache  | `aws elasticache failover-global-replication-group …`                       |
   | EFS          | `aws efs delete-replication-configuration …`                                |
   | Secrets      | `aws secretsmanager stop-replication-to-replica …` (if primary unreachable) |
   | DynamoDB / S3| Already available — switch the app's Region/bucket config                   |

5. **Scale up compute** in the DR Region (ASG / EKS / ECS — B10).
6. **Point the app at DR endpoints** — DB endpoint, Redis endpoint, bucket,
   queue URLs (keep these in Parameter Store/Secrets per Region).
7. **Switch traffic** — Route 53 failover happens automatically when the
   health check fails; with ARC, flip the routing control.
8. **Verify** — login, create an order, background jobs running, error rates
   normal.
9. **Record** the failover time and estimated data loss window (last
   replication timestamp).

---

## Failback

1. Wait until the primary Region is stable (AWS Health shows resolved).
2. **Re-establish replication in reverse** (DR → primary):
   - Aurora: once the old primary Region recovers, it rejoins as a secondary;
     later use `switchover-global-cluster` to move back with no data loss.
   - RDS: create a new cross-Region read replica **from** the promoted DR
     instance into the primary Region.
   - EFS: create a replication configuration from DR to a new file system in
     the primary Region.
   - ElastiCache: re-add the primary Region as a secondary, then fail over.
   - S3: add a reverse replication rule (or bidirectional replication).
3. Wait for lag ≈ 0, schedule a maintenance window, and switch over in the
   reverse order of the runbook.
4. Scale DR back down to pilot-light / warm-standby size and re-enable all
   original replication and alarms.

---

## Testing (Game Days and AWS FIS)

| Test                                   | How                                                        | Frequency   |
| -------------------------------------- | ---------------------------------------------------------- | ----------- |
| RDS Multi-AZ failover                  | `aws rds reboot-db-instance --force-failover`              | Quarterly   |
| ElastiCache failover                   | `aws elasticache test-failover`                            | Quarterly   |
| AZ outage                              | AWS FIS scenario **"AZ Availability: Power Interruption"** | Twice a year|
| Zonal shift away from an AZ            | `aws arc-zonal-shift start-zonal-shift`                    | Quarterly   |
| Restore from backup in DR Region       | AWS Backup restore testing                                 | Monthly     |
| Full Region failover + failback        | Game day following the runbook                             | Yearly      |

Run an FIS experiment from a saved template:

```bash
aws fis list-experiment-templates --region ap-south-1
aws fis start-experiment --region ap-south-1 --experiment-template-id EXT123abc
aws fis get-experiment --region ap-south-1 --id EXP123abc
```

> Always add **stop conditions** (a CloudWatch alarm) to FIS templates, and
> run first in staging.

---

## Security Checklist

- [ ] DR Region is **allowed** in Organizations SCPs and IAM policies
- [ ] Replication roles (S3, Backup, DLM) have least-privilege policies
- [ ] KMS keys exist in the DR Region (or multi-Region keys) and key policies allow the replication roles
- [ ] Backups copied to a **separate account** and vault with **Vault Lock**
- [ ] S3 delete-marker replication disabled; versioning + MFA delete / Object Lock where needed
- [ ] RDS / Aurora / DynamoDB have deletion protection and PITR enabled
- [ ] Security groups and NACLs in DR mirror the primary (managed by IaC)
- [ ] Secrets replicated, not copied into code or user data
- [ ] CloudTrail and GuardDuty enabled in **both** Regions
- [ ] Service quotas raised in the DR Region
- [ ] Runbook, contacts and break-glass credentials accessible without the primary Region

---

## Summary: Service-by-Service

| Service              | AZ (data center) down               | Region down                                         |
| -------------------- | ----------------------------------- | --------------------------------------------------- |
| **EC2**              | ASG across 3 AZs + ALB              | AMIs copied; ASG in DR Region (IaC)                 |
| **ALB / NLB**        | Spans AZs automatically             | Separate LB in DR + Route 53 failover               |
| **EKS / ECS**        | Nodes/tasks in 3 AZs, topology spread | Second cluster in DR via IaC/GitOps, ECR replication |
| **RDS**              | Multi-AZ (instance or cluster)      | Cross-Region read replica or backup replication     |
| **Aurora**           | Storage across 3 AZs + reader       | Aurora Global Database                              |
| **DynamoDB**         | Built in                            | Global tables + PITR                                |
| **ElastiCache**      | Multi-AZ with auto failover         | Global Datastore (or cold cache)                    |
| **S3**               | Built in (Standard classes)         | Cross-Region Replication (+ RTC)                    |
| **EFS**              | Regional, mount target per AZ       | EFS replication                                     |
| **EBS**              | Single-AZ — snapshots               | Cross-Region snapshot copy / AWS Backup             |
| **ECR**              | Regional                            | Registry replication                                |
| **Secrets Manager**  | Regional                            | Replica secrets                                     |
| **KMS**              | Regional                            | Multi-Region keys                                   |
| **Parameter Store**  | Regional                            | Script / IaC copy                                   |
| **Route 53**         | Global                              | Failover / latency routing, ARC routing controls    |
| **CloudFront**       | Global                              | Origin groups                                       |
| **Backups**          | AWS Backup                          | Cross-Region (and cross-account) copy actions       |

---

## Done ✅

The workload now survives the loss of a single data center automatically
through Multi-AZ, and can be failed over to a second Region with replicated
data, pre-built infrastructure, tested runbooks and alarms that still work
when the primary Region is down.
