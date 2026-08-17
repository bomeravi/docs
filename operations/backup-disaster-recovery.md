---
pagination_label: Backup & Recovery
---

# Backup and Disaster Recovery

A backup is only useful when it can be restored within the time the service
needs. This runbook establishes a repeatable process for every production
service; adapt the exact commands to the database, cloud provider, and
workload.

## Define the recovery objective first

For each service, record the following in its service inventory:

| Item | Question to answer |
| --- | --- |
| Owner | Who is accountable for recovery and who is the backup contact? |
| Data | Which databases, file uploads, volumes, configs, and credentials are essential? |
| RPO | How much data loss is acceptable, measured in time? |
| RTO | How long may recovery take before the impact becomes unacceptable? |
| Dependencies | Which DNS, identity, storage, queues, or third parties are needed first? |
| Restore location | Where can a safe test restore run without affecting production? |

Do not store secret values in this repository. Link to the approved secret
manager entry and list only the responsible team and recovery process here.

## What to back up

| Asset | Minimum approach | Restore verification |
| --- | --- | --- |
| Relational database | Automated snapshots plus point-in-time recovery where available | Restore to an isolated instance; run schema and sample-data checks |
| Object/file storage | Versioning and lifecycle policy; replicate critical data if required | Recover a prior object version and download it |
| VM volume | Provider snapshots or image backups | Boot an isolated restored VM and check application data |
| Kubernetes state | Git-managed manifests plus persistent-volume/database backup | Restore to a separate namespace or cluster |
| CI/CD and service config | Configuration-as-code, credential inventory, and encrypted export where supported | Recreate a non-production service from the documented source |

Infrastructure code is not a replacement for a data backup. Terraform or
Kubernetes manifests can recreate resources but generally cannot recreate the
data inside them.

## Backup implementation checklist

- Encrypt backups in transit and at rest.
- Use a separate account, project, bucket, or access boundary from the primary
  workload when the service criticality requires it.
- Enable immutable or versioned retention where supported, with a documented
  retention and deletion policy.
- Limit deletion and restore permissions to specific roles.
- Alert when a scheduled backup fails, is too old for the RPO, or cannot be
  verified.
- Record the backup location, schedule, retention, owner, and cost owner in
  the service inventory.

## Recovery procedure

Use this order during a real incident or scheduled exercise:

1. **Declare and contain.** Open an incident, name an incident lead, preserve
   evidence, and stop writes or destructive automation if that prevents further
   loss.
2. **Identify the recovery point.** Choose the latest backup that is known to
   be internally consistent and meets the RPO. Record its timestamp.
3. **Restore in isolation first.** Use a new database instance, VM, bucket
   prefix, namespace, or cluster. Never overwrite the only remaining copy.
4. **Validate.** Check application start-up, schema/version, record counts or
   checksums, critical user journeys, permissions, and log errors.
5. **Promote deliberately.** Update DNS, traffic routing, credentials, or
   deployment configuration only after the service owner approves the result.
6. **Observe after recovery.** Watch error rate, latency, queue depth, storage
   use, and backup jobs. Preserve the prior environment until the recovery is
   confirmed.
7. **Document the outcome.** Record actual RTO/RPO, gaps found, and actions
   required before closing the incident.

## Restore testing schedule

Test restores on a cadence appropriate to the service criticality—at least
quarterly for important production data and after a major backup-design change.
An exercise should measure the real restore time, not merely confirm that a
snapshot exists.

Record each test with:

- date, service, backup timestamp, and executor;
- recovery location and exact procedure used;
- validation performed and result;
- measured restore time and data age;
- follow-up actions and responsible owner.

## Service recovery record template

```md
## <service name> recovery record

- Owner: <team or person>
- Backup scope: <database, uploads, volumes, configuration>
- Backup location: <approved internal reference>
- Schedule / retention: <for example, hourly PITR + 35-day snapshots>
- RPO / RTO: <for example, 1 hour / 4 hours>
- Last restore test: <YYYY-MM-DD, result, evidence link>
- Recovery runbook: <internal link>
- Escalation: <internal contact or rotation>
```

## Related

- [AWS RDS](../aws/rds.md) — snapshots, point-in-time restore, and Multi-AZ.
- [AWS S3](../aws/s3.md) — versioning and lifecycle policies.
- [DigitalOcean Spaces](../digitalocean/space-object-storage.md) — object
  storage setup.
- [Kubernetes manifests](../kubernetes/manifests/README.md) — workloads whose
  data requirements must be assessed.
- [GRUB and EFI Boot Repair](../troubleshoot/grub-efi-boot-repair.md) — a
  recovery example after an image restore.
