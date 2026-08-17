---
pagination_label: Monitoring & Alerting
---

# Monitoring and Alerting

Monitoring should tell the team whether users can use a service, why it is
degraded, and who needs to respond. Build it from service objectives rather
than from every available metric.

## Minimum signals for every production service

| Signal | What to collect | Example alert condition |
| --- | --- | --- |
| Availability | External HTTP/TCP health check and deployment health | Check fails from more than one location for the agreed duration |
| Traffic | Requests, active users, queue depth, or jobs processed | Unexpected drop or sustained backlog |
| Errors | 5xx responses, failed jobs, application exceptions | Error rate exceeds the service objective |
| Latency | p50/p95/p99 request or job duration | p95 stays above the agreed user-facing threshold |
| Saturation | CPU, memory, disk, connection pool, and storage capacity | Resource has little headroom or is nearing exhaustion |
| Dependencies | Database, cache, queue, DNS, certificate, and third-party health | Dependency cannot serve the application |

Collect structured logs with UTC timestamps, severity, service/environment,
request or trace ID, and a useful error message. Never log passwords, API
tokens, session IDs, private keys, or full payment/personal data.

## Dashboard design

Create one overview dashboard per service and one platform dashboard for
shared infrastructure. Each service dashboard should show:

1. current deployment version and rollout status;
2. availability, request volume, error rate, and latency for a matching time
   range;
3. resource use and capacity headroom;
4. dependency health and recent alert history;
5. links to logs, tracing, runbook, owner, and rollback procedure.

Use the same labels across metrics and logs, such as `service`, `environment`,
`region`, `version`, and `namespace`. Consistent labels make an incident
searchable across tools.

## Alert rules that people can act on

An alert must include the affected service/environment, severity, observed
condition, duration, dashboard link, owner, and first investigation step. Use
two broad severities unless the team has a more formal policy:

| Severity | Use when | Expected response |
| --- | --- | --- |
| Critical | Users are broadly affected, data is at risk, or a hard capacity limit is imminent | Page the on-call owner immediately |
| Warning | A trend or partial failure needs attention but does not yet require immediate interruption | Create a ticket or notify the owning team during working hours |

Avoid alerts for a single brief failure, expected deployment restart, or a
metric with no documented response. Prefer sustained, user-impacting symptoms
over low-level causes when deciding what pages a person.

## First-response checklist

1. Confirm the alert is current and identify the service, environment, and
   user impact.
2. Check recent deployments, configuration changes, infrastructure events,
   certificate expiry, and dependency status.
3. Use the dashboard to decide whether the problem is availability, errors,
   latency, capacity, or a dependency.
4. Inspect correlated logs using the incident time range and request/trace ID.
5. Mitigate safely: roll back the known-bad release, scale a healthy workload,
   or fail over only when the runbook authorizes it.
6. Escalate to the service owner or dependency owner with evidence, not only a
   screenshot of the alert.
7. Record the timeline and create a follow-up task for any missing metric,
   alert, dashboard, or runbook.

## Monitoring readiness checklist

- [ ] Owner and on-call/escalation path are recorded.
- [ ] External health check covers the critical user journey.
- [ ] Availability, traffic, errors, latency, and saturation are visible.
- [ ] Logs are centralized, retained appropriately, and redacted.
- [ ] Alert rules have tested notification routes and runbook links.
- [ ] Certificate and domain expiry are monitored where applicable.
- [ ] Backup age/failure is monitored.
- [ ] A deployment or rollback can be correlated to the service version.

## Related

- [Standard Ports](../standard-ports.md) — expected network entry points.
- [DNS and Domain Commands](../domain-dns-commands.md) — DNS and certificate
  diagnosis.
- [Backup and Disaster Recovery](./backup-disaster-recovery.md) — protect and
  test data recovery.
- [Kubernetes Production Baseline](../kubernetes/03-production-baseline.md) —
  probes, resources, and rollout checks for workloads.
