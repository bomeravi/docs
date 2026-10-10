---
pagination_label: Operations
---

# Operations

Operational guidance for keeping services recoverable and observable after
they are deployed. These pages are deliberately provider-neutral so they can
be used for VMs, managed cloud services, containers, and Kubernetes workloads.

## Guides

- [Backup and Disaster Recovery](./backup-disaster-recovery.md) — define,
  perform, test, and restore backups.
- [Monitoring and Alerting](./monitoring-alerting.md) — health checks, metrics,
  logs, alert design, and incident triage.
- [Load Testing](./load-testing.md) — JMeter, k6, Locust, Artillery, wrk,
  ab, Vegeta, hey, Siege and Gatling, plus metrics to monitor and CI/CD
  integration.
- [Multi-Data-Center Replication](./multi-dc-replication.md) — encrypted
  DC-to-DC link, MySQL/PostgreSQL/Redis/file replication, lag monitoring, and
  a split-brain-safe failover and failback runbook.

## Minimum production standard

Before a service goes live, its owner should be able to identify:

1. The service owner and its escalation path.
2. The source of truth for infrastructure and deployment configuration.
3. Where metrics, logs, and uptime checks are viewed.
4. What is backed up, its retention period, and the most recent restore test.
5. How to roll back the most recent deployment.

For workload-level safeguards, also follow the
[Kubernetes Production Baseline](../kubernetes/03-production-baseline.md).
