# Elastic IP (Static IP)

Elastic IP is a static public IPv4 address that stays fixed even when you stop/start an EC2 instance. Without it, the public IP changes on every restart.

---

## 1. Allocate an Elastic IP

### Console

1. **EC2 → Elastic IPs → Allocate Elastic IP address**
2. Select **Amazon's pool of IPv4 addresses**
3. Click **Allocate**

### CLI

```bash
aws ec2 allocate-address --domain vpc
```

Output:
```json
{
    "PublicIp": "54.123.45.67",
    "AllocationId": "eipalloc-0123456789abcdef0",
    "Domain": "vpc"
}
```

Save the `AllocationId` — needed for association.

---

## 2. Associate with EC2 Instance

### Console

1. **EC2 → Elastic IPs** → select the IP
2. **Actions → Associate Elastic IP address**
3. Choose **Instance** and select your EC2 instance
4. Click **Associate**

### CLI

```bash
aws ec2 associate-address \
  --instance-id i-0123456789abcdef0 \
  --allocation-id eipalloc-0123456789abcdef0
```

---

## 3. Verify

```bash
aws ec2 describe-addresses \
  --query 'Addresses[*].[PublicIp,InstanceId,AllocationId]' \
  --output table
```

---

## 4. Disassociate from Instance

```bash
# Get association ID
aws ec2 describe-addresses --query 'Addresses[*].[AssociationId,PublicIp]' --output table

# Disassociate
aws ec2 disassociate-address --association-id eipassoc-0123456789abcdef0
```

---

## 5. Release Elastic IP

Release when no longer needed — **unassociated Elastic IPs incur charges**.

```bash
aws ec2 release-address --allocation-id eipalloc-0123456789abcdef0
```

---

## 6. Re-associate After Instance Replacement

If you terminate and launch a new EC2 instance, re-associate the same Elastic IP to the new instance:

```bash
# Disassociate from old instance (if still attached)
aws ec2 disassociate-address --association-id eipassoc-old

# Associate to new instance
aws ec2 associate-address \
  --instance-id i-new-instance-id \
  --allocation-id eipalloc-0123456789abcdef0
```

---

## Cost Notes

- **Free** when associated with a running instance.
- **Charged** (~$0.005/hr) when:
  - Allocated but not associated with any instance.
  - Associated with a stopped instance.
- Release unused Elastic IPs to avoid unexpected charges.

---

## Related

- [EC2](./ec2.md) — launch instances to associate with
- [IAM](./iam.md) — permissions needed: `ec2:AllocateAddress`, `ec2:AssociateAddress`
