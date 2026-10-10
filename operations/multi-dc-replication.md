# Multi-Data-Center Replication

How to replicate databases, caches and files from a primary data center (DC1)
to a secondary one (DC2) **safely** — over an encrypted private link, with
least-privilege replication users, monitored lag, and a failover procedure
that avoids split-brain.

> Replication is **not** a backup. A bad `DELETE`, a ransomware encryption or a
> dropped table is replicated to DC2 within seconds. Keep point-in-time backups
> as described in [Backup and Disaster Recovery](./backup-disaster-recovery.md).

---

## Table of Contents

- [Concepts](#concepts)
- [Reference Architecture](#reference-architecture)
- [1. Encrypted Link Between Data Centers](#_1-encrypted-link-between-data-centers)
- [2. Firewall: Allow Only the Peer](#_2-firewall-allow-only-the-peer)
- [3. MySQL / MariaDB Replication](#_3-mysql-mariadb-replication)
- [4. PostgreSQL Streaming Replication](#_4-postgresql-streaming-replication)
- [5. Redis Replication](#_5-redis-replication)
- [6. File and Upload Replication](#_6-file-and-upload-replication)
- [7. Monitoring Replication](#_7-monitoring-replication)
- [8. Safe Failover Procedure](#_8-safe-failover-procedure)
- [9. Failback](#_9-failback)
- [10. DR Drills](#_10-dr-drills)
- [Security Checklist](#security-checklist)
- [Summary](#summary)

---

## Concepts

| Term                 | Meaning                                                                       |
| -------------------- | ----------------------------------------------------------------------------- |
| **RPO**              | Recovery Point Objective — how much data you can afford to lose (e.g. 5 s)    |
| **RTO**              | Recovery Time Objective — how long the service may be down (e.g. 15 min)      |
| **Asynchronous**     | Primary commits immediately, replica catches up. Fast; RPO = replication lag  |
| **Semi-sync / sync** | Primary waits for the replica to confirm. RPO ≈ 0; every write pays the DC-to-DC round trip |
| **Active-passive**   | DC1 takes writes, DC2 is a warm standby (read-only). Recommended default      |
| **Active-active**    | Both DCs take writes. Needs conflict handling — avoid unless the app is designed for it |
| **Split-brain**      | Both sides believe they are primary and accept writes → diverging data        |
| **Fencing**          | Forcibly stopping the old primary so split-brain cannot happen                |

### Choosing sync vs async

| DC-to-DC latency     | Recommendation                                                |
| -------------------- | ------------------------------------------------------------- |
| < 2 ms (same metro)  | Semi-sync or sync is practical                                |
| 2–30 ms (same region)| Async, or semi-sync with a short timeout for critical data    |
| > 30 ms (cross-region / continent) | Async; accept an RPO of a few seconds           |

Measure it first:

```bash
ping -c 20 <dc2-public-ip>
```

---

## Reference Architecture

```text
             DC1 (primary)                              DC2 (standby)
  ┌──────────────────────────────┐            ┌──────────────────────────────┐
  │ app servers  ──► MySQL / PG  │            │ app servers (stopped / RO)   │
  │                  (read-write)│  WireGuard │      MySQL / PG (read-only)  │
  │                  Redis master│◄══════════►│      Redis replica           │
  │                  /var/www/   │ 10.100.0.x │      /var/www/ (rsync copy)  │
  │                  uploads     │  encrypted │                              │
  └──────────────────────────────┘            └──────────────────────────────┘
          10.100.0.1                                    10.100.0.2

  Clients ──► DNS (low TTL) / load balancer ──► DC1   (switch to DC2 on failover)
```

All examples below use the WireGuard tunnel addresses: **DC1 = `10.100.0.1`**,
**DC2 = `10.100.0.2`**.

---

## 1. Encrypted Link Between Data Centers

Never send replication traffic over the public internet in clear text. Use a
site-to-site VPN; WireGuard is simple and fast. (A
[Tailscale](../tailscale.md) tailnet or a cloud VPC peering link also works.)

### 1.1 Install and generate keys (both DCs)

```bash
sudo apt update && sudo apt install wireguard -y
umask 077
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
```

### 1.2 DC1 config (`/etc/wireguard/wg0.conf`)

```ini
[Interface]
Address = 10.100.0.1/24
ListenPort = 51820
PrivateKey = <DC1_PRIVATE_KEY>

[Peer]
PublicKey = <DC2_PUBLIC_KEY>
AllowedIPs = 10.100.0.2/32
Endpoint = <DC2_PUBLIC_IP>:51820
PersistentKeepalive = 25
```

### 1.3 DC2 config (`/etc/wireguard/wg0.conf`)

```ini
[Interface]
Address = 10.100.0.2/24
ListenPort = 51820
PrivateKey = <DC2_PRIVATE_KEY>

[Peer]
PublicKey = <DC1_PUBLIC_KEY>
AllowedIPs = 10.100.0.1/32
Endpoint = <DC1_PUBLIC_IP>:51820
PersistentKeepalive = 25
```

### 1.4 Start and verify

```bash
sudo systemctl enable --now wg-quick@wg0
sudo wg show
ping -c 3 10.100.0.2   # from DC1
```

> ⚠️ Keep `privatekey` readable by root only (`chmod 600`). Never commit it.

---

## 2. Firewall: Allow Only the Peer

Replication ports must be reachable **only** from the other DC over the
tunnel — never from `0.0.0.0/0`.

```bash
# Both DCs: WireGuard from the other DC's public IP only
sudo ufw allow from <PEER_PUBLIC_IP> to any port 51820 proto udp

# DC1 (primary): DB/cache ports only from DC2 over wg0
sudo ufw allow in on wg0 from 10.100.0.2 to any port 3306 proto tcp   # MySQL
sudo ufw allow in on wg0 from 10.100.0.2 to any port 5432 proto tcp   # PostgreSQL
sudo ufw allow in on wg0 from 10.100.0.2 to any port 6379 proto tcp   # Redis

sudo ufw enable
sudo ufw status numbered
```

Add the mirror rules on DC2 (allowing `10.100.0.1`) so replication can run in
the other direction after a failover.

Bind database services to the tunnel / private address, not to every
interface — see each database section below.

---

## 3. MySQL / MariaDB Replication

GTID-based asynchronous replication with TLS (MySQL 8.0.23+ syntax; MariaDB
notes at the end).

### 3.1 Primary config (DC1) — `/etc/mysql/mysql.conf.d/replication.cnf`

```ini
[mysqld]
server_id                = 1
bind_address             = 127.0.0.1,10.100.0.1
log_bin                  = /var/log/mysql/mysql-bin
binlog_format            = ROW
binlog_expire_logs_seconds = 604800     # keep 7 days so a lagging replica can catch up
gtid_mode                = ON
enforce_gtid_consistency = ON
sync_binlog              = 1
innodb_flush_log_at_trx_commit = 1
require_secure_transport = ON           # reject non-TLS connections
```

```bash
sudo systemctl restart mysql
```

### 3.2 Replication user (DC1)

Least privilege, TLS required, allowed only from DC2's tunnel IP:

```sql
CREATE USER 'repl'@'10.100.0.2' IDENTIFIED BY 'use-a-long-random-password' REQUIRE SSL;
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'10.100.0.2';
FLUSH PRIVILEGES;
```

> Generate the password with `openssl rand -base64 32` and store it in your
> secrets manager.

### 3.3 Replica config (DC2) — `/etc/mysql/mysql.conf.d/replication.cnf`

```ini
[mysqld]
server_id                = 2
bind_address             = 127.0.0.1,10.100.0.2
log_bin                  = /var/log/mysql/mysql-bin   # needed if DC2 is promoted later
relay_log                = /var/log/mysql/relay-bin
gtid_mode                = ON
enforce_gtid_consistency = ON
log_replica_updates      = ON
read_only                = ON
super_read_only          = ON                         # even admins can't write by accident
skip_replica_start       = OFF
```

```bash
sudo systemctl restart mysql
```

### 3.4 Seed the replica with a consistent copy

On DC1 (no table locks for InnoDB):

```bash
mysqldump -u root -p --all-databases --single-transaction --triggers --routines --events \
  --set-gtid-purged=ON | gzip > /tmp/seed.sql.gz
```

Copy it over the tunnel and load it on DC2:

```bash
scp /tmp/seed.sql.gz admin@10.100.0.2:/tmp/
```

```bash
# DC2
mysql -u root -p -e "SET GLOBAL super_read_only = OFF; RESET MASTER;"
gunzip < /tmp/seed.sql.gz | mysql -u root -p
mysql -u root -p -e "SET GLOBAL super_read_only = ON;"
shred -u /tmp/seed.sql.gz
```

> For large databases (hundreds of GB) use the MySQL **Clone plugin** or
> Percona **XtraBackup** instead of `mysqldump`.

### 3.5 Start replication (DC2)

```sql
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = '10.100.0.1',
  SOURCE_PORT = 3306,
  SOURCE_USER = 'repl',
  SOURCE_PASSWORD = 'use-a-long-random-password',
  SOURCE_AUTO_POSITION = 1,
  SOURCE_SSL = 1,
  SOURCE_CONNECT_RETRY = 10,
  SOURCE_RETRY_COUNT = 8640;

START REPLICA;
```

### 3.6 Verify

```sql
SHOW REPLICA STATUS\G
```

Check these fields:

| Field                     | Healthy value                      |
| ------------------------- | ---------------------------------- |
| `Replica_IO_Running`      | `Yes`                              |
| `Replica_SQL_Running`     | `Yes`                              |
| `Seconds_Behind_Source`   | `0` (or small and not growing)     |
| `Source_SSL_Allowed`      | `Yes`                              |
| `Last_IO_Error` / `Last_SQL_Error` | empty                     |

Quick end-to-end test:

```sql
-- DC1
CREATE DATABASE repl_check; CREATE TABLE repl_check.t (id INT PRIMARY KEY, at DATETIME);
INSERT INTO repl_check.t VALUES (1, NOW());

-- DC2 (should return the row within a second)
SELECT * FROM repl_check.t;

-- DC1 (clean up; the drop replicates too)
DROP DATABASE repl_check;
```

### 3.7 Optional: semi-synchronous replication

The primary waits until DC2 has **received** each transaction before
acknowledging the commit. Use only when DC-to-DC latency is low.

```sql
-- DC1
INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.so';
SET GLOBAL rpl_semi_sync_source_enabled = 1;
SET GLOBAL rpl_semi_sync_source_timeout = 1000;   -- ms; falls back to async if DC2 is unreachable

-- DC2
INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.so';
SET GLOBAL rpl_semi_sync_replica_enabled = 1;
STOP REPLICA IO_THREAD; START REPLICA IO_THREAD;
```

Persist the same settings in the `.cnf` files so they survive restarts.

### 3.8 MariaDB differences

| MySQL 8                          | MariaDB                                              |
| -------------------------------- | ---------------------------------------------------- |
| `CHANGE REPLICATION SOURCE TO`   | `CHANGE MASTER TO MASTER_HOST=…, MASTER_USE_GTID=slave_pos, MASTER_SSL=1` |
| `START REPLICA` / `SHOW REPLICA STATUS` | `START SLAVE` / `SHOW SLAVE STATUS` (newer versions accept both) |
| `gtid_mode = ON`                 | GTID always on; no setting needed                    |
| `--set-gtid-purged=ON`           | `mariadb-dump --gtid --master-data=1`                |

---

## 4. PostgreSQL Streaming Replication

Physical streaming replication with a replication slot and TLS (paths shown
for PostgreSQL 16 on Ubuntu).

### 4.1 Primary config (DC1) — `/etc/postgresql/16/main/postgresql.conf`

```ini
listen_addresses        = 'localhost,10.100.0.1'
wal_level               = replica
max_wal_senders         = 10
max_replication_slots   = 10
wal_keep_size           = '1GB'
max_slot_wal_keep_size  = '20GB'     # stop a dead replica's slot from filling the disk
password_encryption     = scram-sha-256
ssl                     = on
```

### 4.2 Replication role and access (DC1)

```bash
sudo -u postgres psql -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'use-a-long-random-password';"
sudo -u postgres psql -c "SELECT pg_create_physical_replication_slot('dc2_replica');"
```

`/etc/postgresql/16/main/pg_hba.conf` — TLS only, DC2 only:

```text
# TYPE    DATABASE     USER        ADDRESS          METHOD
hostssl   replication  replicator  10.100.0.2/32    scram-sha-256
```

```bash
sudo systemctl restart postgresql
```

### 4.3 Seed the replica (DC2)

```bash
sudo systemctl stop postgresql
sudo -u postgres mv /var/lib/postgresql/16/main /var/lib/postgresql/16/main.old

sudo -u postgres pg_basebackup \
  -d "host=10.100.0.1 user=replicator sslmode=require" \
  -D /var/lib/postgresql/16/main \
  -X stream -S dc2_replica -R -P
```

| Flag        | Purpose                                                          |
| ----------- | ---------------------------------------------------------------- |
| `-X stream` | Stream WAL during the copy so the backup is consistent           |
| `-S`        | Use the replication slot created on the primary                  |
| `-R`        | Write `standby.signal` and `primary_conninfo` → starts as replica|
| `-P`        | Show progress                                                    |

Store the password in `~postgres/.pgpass` (mode `600`) instead of typing it:

```text
10.100.0.1:5432:replication:replicator:use-a-long-random-password
```

### 4.4 Replica config (DC2) and start

In `/etc/postgresql/16/main/postgresql.conf`:

```ini
listen_addresses = 'localhost,10.100.0.2'
hot_standby      = on        # allow read-only queries on the replica
```

```bash
sudo systemctl start postgresql
```

### 4.5 Verify

On DC1:

```bash
sudo -u postgres psql -c "SELECT client_addr, state, sync_state, write_lag, replay_lag FROM pg_stat_replication;"
sudo -u postgres psql -c "SELECT slot_name, active, wal_status FROM pg_replication_slots;"
```

On DC2:

```bash
sudo -u postgres psql -c "SELECT pg_is_in_recovery(), now() - pg_last_xact_replay_timestamp() AS lag;"
```

`pg_is_in_recovery()` must be `t` on the replica and `state` must be
`streaming` on the primary.

### 4.6 Optional: synchronous replication

Add `application_name=dc2_replica` to `primary_conninfo` in DC2's
`postgresql.auto.conf`, then on DC1:

```ini
synchronous_standby_names = 'FIRST 1 (dc2_replica)'
synchronous_commit        = on
```

> ⚠️ With synchronous replication, **writes on DC1 stop** if DC2 is
> unreachable. Only use it with a low-latency link and a plan to switch back
> to async (`synchronous_standby_names = ''` + reload) during a DC2 outage.

---

## 5. Redis Replication

Redis has no built-in encryption unless compiled with TLS, so keep it on the
WireGuard tunnel and always require a password.

DC1 — `/etc/redis/redis.conf`:

```ini
bind 127.0.0.1 10.100.0.1
protected-mode yes
requirepass use-a-long-random-password
masterauth use-a-long-random-password     # so it can become a replica after failover
```

DC2 — `/etc/redis/redis.conf`:

```ini
bind 127.0.0.1 10.100.0.2
protected-mode yes
requirepass use-a-long-random-password
masterauth use-a-long-random-password
replicaof 10.100.0.1 6379
replica-read-only yes
```

```bash
sudo systemctl restart redis-server
redis-cli -a 'use-a-long-random-password' INFO replication
```

Look for `role:slave`, `master_link_status:up` and a small
`master_last_io_seconds_ago` on DC2.

> For automatic failover use **Redis Sentinel** with at least **three**
> Sentinels in **three** locations (e.g. DC1, DC2 and a small VM in a third
> site). With only two locations, a network split cannot reach a safe quorum.

---

## 6. File and Upload Replication

### 6.1 Restricted SSH key for replication

Create a dedicated key on DC1 that can **only** rsync into one directory on
DC2:

```bash
# DC1
ssh-keygen -t ed25519 -f ~/.ssh/repl_ed25519 -N "" -C "dc1-file-repl"
```

On DC2, in `/home/repl/.ssh/authorized_keys` (one line):

```text
command="/usr/bin/rrsync /var/www/uploads",restrict ssh-ed25519 AAAA...key... dc1-file-repl
```

> `rrsync` ships with rsync on Ubuntu 22.04+. It confines the key to that
> directory and to rsync only — no shell.

### 6.2 One-off or scheduled sync

```bash
rsync -aHAX --numeric-ids --delete-after --partial \
  -e "ssh -i ~/.ssh/repl_ed25519" \
  /var/www/uploads/ repl@10.100.0.2:/
```

> ⚠️ `--delete` style flags remove files on DC2 that are missing on DC1 —
> including files deleted by mistake. Keep backups/snapshots on DC2 too, or
> drop `--delete-after` and clean up separately.

Cron every 5 minutes, without overlapping runs:

```text
*/5 * * * * flock -n /tmp/uploads-sync.lock rsync -aHAX --numeric-ids --delete-after --partial -e "ssh -i /home/deploy/.ssh/repl_ed25519" /var/www/uploads/ repl@10.100.0.2:/ >> /var/log/uploads-sync.log 2>&1
```

### 6.3 Near-real-time with lsyncd

```bash
sudo apt install lsyncd -y
sudo mkdir -p /etc/lsyncd /var/log/lsyncd
```

`/etc/lsyncd/lsyncd.conf.lua`:

```lua
settings {
  logfile    = "/var/log/lsyncd/lsyncd.log",
  statusFile = "/var/log/lsyncd/lsyncd.status",
}

sync {
  default.rsyncssh,
  source    = "/var/www/uploads",
  host      = "repl@10.100.0.2",
  targetdir = "/",
  delay     = 5,
  rsync = { archive = true, compress = true },
  ssh   = { identityFile = "/home/deploy/.ssh/repl_ed25519" },
}
```

```bash
sudo systemctl enable --now lsyncd
```

> If the app already uses object storage (S3, DigitalOcean Spaces), prefer the
> provider's **cross-region replication** with versioning enabled over syncing
> local disks.

---

## 7. Monitoring Replication

Alert on these — see [Monitoring and Alerting](./monitoring-alerting.md) for
alert design.

| Signal                              | Alert when                               |
| ----------------------------------- | ---------------------------------------- |
| MySQL `Seconds_Behind_Source`       | > RPO (e.g. 30 s) for 5 min, or `NULL`   |
| MySQL IO/SQL thread                 | Not `Yes`                                |
| PostgreSQL `replay_lag`             | > RPO for 5 min                          |
| PostgreSQL slot `wal_status`        | `unreserved` or `lost`                   |
| Redis `master_link_status`          | `down`                                   |
| File sync last success              | Older than 2× the sync interval          |
| WireGuard `latest handshake`        | Older than 3 minutes                     |
| Disk usage on primary (WAL/binlog)  | > 80 %                                   |

A simple check script for cron or a monitoring agent (MySQL replica):

```bash
#!/usr/bin/env bash
# /usr/local/bin/check-mysql-replica.sh — exits non-zero when unhealthy
MAX_LAG=30
STATUS=$(mysql --defaults-file=/etc/mysql/monitor.cnf -e "SHOW REPLICA STATUS\G")

io=$(awk '/Replica_IO_Running:/ {print $2}' <<<"$STATUS")
sql=$(awk '/Replica_SQL_Running:/ {print $2}' <<<"$STATUS")
lag=$(awk '/Seconds_Behind_Source:/ {print $2}' <<<"$STATUS")

if [[ "$io" != "Yes" || "$sql" != "Yes" ]]; then
  echo "CRITICAL: replication stopped (IO=$io SQL=$sql)"; exit 2
fi
if [[ "$lag" == "NULL" || "$lag" -gt "$MAX_LAG" ]]; then
  echo "WARNING: replica lag ${lag}s"; exit 1
fi
echo "OK: lag ${lag}s"
```

The monitor account needs only `GRANT REPLICATION CLIENT ON *.* TO
'monitor'@'localhost';`.

WireGuard handshake age:

```bash
sudo wg show wg0 latest-handshakes
```

---

## 8. Safe Failover Procedure

Do this **manually** with a runbook unless you have a tested, quorum-based
tool (Orchestrator, Patroni, Sentinel). Automatic failover between only two
sites is the most common cause of split-brain.

### 8.1 Before you start

- Lower DNS TTL for the app hostname to **60 s** well in advance (days before
  a planned switch; permanently if you rely on DNS failover).
- Have the runbook, credentials and DC2 app config ready and tested.

### 8.2 Steps

1. **Confirm DC1 is really down** — check from at least two outside locations
   and from DC2. A broken tunnel alone is not a DC outage.
2. **Fence DC1** so it cannot accept writes if it comes back:
   - stop the database and app (`sudo systemctl stop mysql nginx php*-fpm`), or
   - power off / stop the instances through the provider console/API, or
   - remove DC1 from the load balancer and block DB ports.
3. **Check how far DC2 got** (data you may lose):

   ```sql
   -- MySQL
   SHOW REPLICA STATUS\G   -- note Retrieved_Gtid_Set vs Executed_Gtid_Set
   ```

   ```bash
   # PostgreSQL
   sudo -u postgres psql -c "SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(), pg_last_xact_replay_timestamp();"
   ```

   Wait until the replica has applied everything it received.
4. **Promote DC2**:

   ```sql
   -- MySQL
   STOP REPLICA;
   RESET REPLICA ALL;
   SET GLOBAL super_read_only = OFF;
   SET GLOBAL read_only = OFF;
   ```

   ```bash
   # PostgreSQL
   sudo -u postgres psql -c "SELECT pg_promote();"

   # Redis
   redis-cli -a 'use-a-long-random-password' REPLICAOF NO ONE
   ```

   Also remove `read_only` / `super_read_only` from DC2's `.cnf` (and
   `replicaof` from `redis.conf`) so a restart keeps it writable.
5. **Point traffic to DC2** — update DNS / load balancer, start DC2 app
   servers and queue workers, and point them at the local database.
6. **Verify** — log in, create a test record, check error rates and logs.
7. **Record** the time, the last applied GTID/LSN, and any known lost writes.

> ⚠️ Never simply restart the old DC1 primary after a failover. It still
> believes it is the primary and may contain writes DC2 never received.
> Rebuild it as a replica (next section).

---

## 9. Failback

1. Keep DC1 fenced. Rebuild it as a **replica of DC2**:
   - MySQL: wipe and re-seed from DC2 (section 3.4), then
     `CHANGE REPLICATION SOURCE TO SOURCE_HOST='10.100.0.2' …`.
   - PostgreSQL: `pg_rewind` (requires `wal_log_hints = on` or data
     checksums) or a fresh `pg_basebackup` from DC2.
   - Redis: set `replicaof 10.100.0.2 6379`.
2. Wait until DC1 has caught up (lag ≈ 0).
3. Schedule a maintenance window, put the app in read-only/maintenance mode,
   confirm lag is 0, then run the same promotion steps in reverse.
4. Restore DC2 as the replica and re-enable monitoring alerts.

---

## 10. DR Drills

Replication you have never failed over is untested.

| Drill                                     | Frequency  |
| ----------------------------------------- | ---------- |
| Verify replicas are healthy and lag < RPO | Daily (automated) |
| Restore a backup into an isolated server  | Monthly    |
| Read-only smoke test against DC2          | Monthly    |
| Full planned failover to DC2 and back     | Quarterly / twice a year |

After each drill, record actual RPO/RTO and update the runbook.

---

## Security Checklist

- [ ] Replication runs only over WireGuard / private link, never plain public internet
- [ ] DB, cache and SSH ports allowed only from the peer DC's IP
- [ ] Databases bound to localhost + tunnel IP, not `0.0.0.0`
- [ ] Dedicated replication users with only replication privileges
- [ ] TLS required for MySQL (`REQUIRE SSL`) and PostgreSQL (`hostssl`)
- [ ] Strong random passwords stored in a secrets manager, not in Git
- [ ] Redis `requirepass` + `masterauth` set, `protected-mode yes`
- [ ] File-sync SSH key restricted with `rrsync` + `restrict`
- [ ] Replicas are `read_only` / `super_read_only` / `hot_standby`
- [ ] Seed dumps shredded after import
- [ ] Lag and link alerts configured and tested
- [ ] Point-in-time backups exist independently of replication
- [ ] Failover runbook written, fencing step included, drill completed

---

## Summary

| Component  | Replication method                | Verify with                                  | Promote with                    |
| ---------- | --------------------------------- | -------------------------------------------- | ------------------------------- |
| Link       | WireGuard site-to-site            | `sudo wg show`                               | —                               |
| MySQL      | GTID async (+ optional semi-sync) | `SHOW REPLICA STATUS\G`                      | `STOP REPLICA; RESET REPLICA ALL;` + disable read-only |
| PostgreSQL | Streaming + replication slot      | `pg_stat_replication`, `pg_is_in_recovery()` | `SELECT pg_promote();`          |
| Redis      | `replicaof` (+ Sentinel, 3 sites) | `INFO replication`                           | `REPLICAOF NO ONE`              |
| Files      | rsync / lsyncd over restricted SSH| sync log, file counts                        | Point app at local copy         |

---

## Done ✅

DC2 now holds an encrypted, continuously updated, read-only copy of DC1's
databases, cache and files, with lag monitoring and a fenced, manual failover
procedure that prevents split-brain.
