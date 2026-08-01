# RDS (Relational Database Service)

RDS is AWS's managed database service. Supports PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server. AWS handles backups, patching, failover.

---

## 1. Create a DB Instance

### Console

1. **RDS → Create database**
2. **Standard create** (recommended for control)
3. **Engine**: PostgreSQL or MySQL
4. **Template**: Production / Dev/Test / Free tier
5. **DB instance identifier**: e.g. `my-app-db`
6. **Master username / password**: set and save securely
7. **Instance class**: `db.t3.micro` (free tier) or as needed
8. **Storage**: 20 GB gp2 (enable auto-scaling if needed)
9. **Connectivity**:
   - Select VPC
   - **Public access**: No (access via EC2/VPN inside VPC)
   - Create or select a DB security group
10. Click **Create database**

### CLI (PostgreSQL)

```bash
aws rds create-db-instance \
  --db-instance-identifier my-app-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16 \
  --master-username dbadmin \
  --master-user-password MySecurePass123 \
  --allocated-storage 20 \
  --storage-type gp2 \
  --no-publicly-accessible \
  --vpc-security-group-ids sg-0123456789abcdef0 \
  --region ap-south-1
```

---

## 2. Get Connection Endpoint

```bash
aws rds describe-db-instances \
  --db-instance-identifier my-app-db \
  --query 'DBInstances[0].Endpoint.[Address,Port]' \
  --output text
```

Output:
```text
my-app-db.xxxxxxxx.ap-south-1.rds.amazonaws.com   5432
```

---

## 3. Connect to Database

RDS is not publicly accessible by default. Connect from an EC2 instance in the same VPC:

```bash
# PostgreSQL
psql -h my-app-db.xxxxxxxx.ap-south-1.rds.amazonaws.com \
     -U dbadmin -d postgres

# MySQL
mysql -h my-app-db.xxxxxxxx.ap-south-1.rds.amazonaws.com \
      -u dbadmin -p
```

### SSH Tunnel (from local machine)

```bash
# Tunnel via EC2 bastion
ssh -i my-key.pem -N -L 5432:my-app-db.xxxxxxxx.ap-south-1.rds.amazonaws.com:5432 \
    ubuntu@<ec2-public-ip>

# Connect locally through tunnel
psql -h localhost -p 5432 -U dbadmin -d postgres
```

---

## 4. Security Group Rules

Allow EC2 instances to reach RDS:

```bash
# Allow PostgreSQL from EC2 security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds-0123456789 \
  --protocol tcp \
  --port 5432 \
  --source-group sg-ec2-0123456789
```

---

## 5. Automated Backups

Enabled by default with 7-day retention.

```bash
# Modify backup retention
aws rds modify-db-instance \
  --db-instance-identifier my-app-db \
  --backup-retention-period 14 \
  --preferred-backup-window "02:00-03:00" \
  --apply-immediately
```

---

## 6. Manual Snapshot

```bash
# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier my-app-db \
  --db-snapshot-identifier my-app-db-snapshot-2024-01-01

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier my-app-db \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,Status]' \
  --output table
```

---

## 7. Restore from Snapshot

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier my-app-db-restored \
  --db-snapshot-identifier my-app-db-snapshot-2024-01-01 \
  --db-instance-class db.t3.micro \
  --region ap-south-1
```

---

## 8. Parameter Groups (Tune DB Settings)

```bash
# Create parameter group
aws rds create-db-parameter-group \
  --db-parameter-group-name my-pg16-params \
  --db-parameter-group-family postgres16 \
  --description "Custom PostgreSQL 16 params"

# Modify a parameter
aws rds modify-db-parameter-group \
  --db-parameter-group-name my-pg16-params \
  --parameters "ParameterName=max_connections,ParameterValue=200,ApplyMethod=pending-reboot"

# Attach to instance
aws rds modify-db-instance \
  --db-instance-identifier my-app-db \
  --db-parameter-group-name my-pg16-params \
  --apply-immediately
```

---

## 9. Multi-AZ (High Availability)

```bash
# Enable Multi-AZ (creates synchronous standby in another AZ)
aws rds modify-db-instance \
  --db-instance-identifier my-app-db \
  --multi-az \
  --apply-immediately
```

Failover is automatic — DNS endpoint stays the same.

---

## 10. Read Replica

```bash
aws rds create-db-instance-read-replica \
  --db-instance-identifier my-app-db-replica \
  --source-db-instance-identifier my-app-db \
  --db-instance-class db.t3.micro \
  --region ap-south-1
```

---

## 11. Stop / Start / Delete

```bash
# Stop (pauses billing for compute, storage still billed)
aws rds stop-db-instance --db-instance-identifier my-app-db

# Start
aws rds start-db-instance --db-instance-identifier my-app-db

# Delete (with final snapshot)
aws rds delete-db-instance \
  --db-instance-identifier my-app-db \
  --final-db-snapshot-identifier my-app-db-final-snapshot

# Delete (skip snapshot)
aws rds delete-db-instance \
  --db-instance-identifier my-app-db \
  --skip-final-snapshot
```

---

## Connection String Examples

```bash
# PostgreSQL (app env var)
DATABASE_URL=postgresql://dbadmin:password@my-app-db.xxxxxxxx.ap-south-1.rds.amazonaws.com:5432/mydb

# MySQL
DATABASE_URL=mysql://dbadmin:password@my-app-db.xxxxxxxx.ap-south-1.rds.amazonaws.com:3306/mydb
```

---

## Related

- [EC2](./ec2.md) — connect to RDS from EC2 in same VPC
- [IAM](./iam.md) — IAM database authentication (passwordless login)
- [EKS](./eks.md) — connect pods to RDS via environment variables or Secrets
