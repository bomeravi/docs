# Standard Ports

Common applications/services and their default ports.

## Web Servers

| Application | Port      | Protocol |
| ----------- | --------- | -------- |
| Apache      | 80, 443   | TCP      |
| Nginx       | 80, 443   | TCP      |
| HAProxy     | 80, 443   | TCP      |
| Tomcat      | 8080      | TCP      |

## CI/CD & DevOps Tools

| Application | Port  | Protocol |
| ----------- | ----- | -------- |
| Jenkins     | 8080  | TCP      |
| ArgoCD      | 8080, 443 | TCP  |
| SonarQube   | 9000  | TCP      |
| Docker      | 2375, 2376 | TCP |
| Kubernetes API Server | 6443 | TCP |
| Kubelet     | 10250 | TCP      |
| etcd        | 2379, 2380 | TCP |

## Networking

| Application | Port    | Protocol |
| ----------- | ------- | -------- |
| SSH         | 22      | TCP      |
| FTP         | 21      | TCP      |
| FTP (Data)  | 20      | TCP      |
| SFTP        | 22      | TCP      |
| Telnet      | 23      | TCP      |
| DNS         | 53      | TCP/UDP  |
| DHCP        | 67, 68  | UDP      |
| NTP         | 123     | UDP      |

## Email

| Application | Port      | Protocol |
| ----------- | --------- | -------- |
| SMTP        | 25        | TCP      |
| SMTP (SSL)  | 465       | TCP      |
| SMTP (TLS)  | 587       | TCP      |
| POP3        | 110       | TCP      |
| POP3 (SSL)  | 995       | TCP      |
| IMAP        | 143       | TCP      |
| IMAP (SSL)  | 993       | TCP      |

## Databases

| Application    | Port  | Protocol |
| -------------- | ----- | -------- |
| MySQL/MariaDB  | 3306  | TCP      |
| PostgreSQL     | 5432  | TCP      |
| MongoDB        | 27017 | TCP      |
| Redis          | 6379  | TCP      |
| Elasticsearch  | 9200, 9300 | TCP |
| Memcached      | 11211 | TCP/UDP  |
| Cassandra      | 9042  | TCP      |
| Oracle DB      | 1521  | TCP      |
| MSSQL          | 1433  | TCP      |
| Zookeeper      | 2181  | TCP      |

## Monitoring & Messaging

| Application  | Port  | Protocol |
| ------------ | ----- | -------- |
| Prometheus   | 9090  | TCP      |
| Grafana      | 3000  | TCP      |
| RabbitMQ     | 5672, 15672 | TCP |
| Kafka        | 9092  | TCP      |

## Other

| Application | Port  | Protocol |
| ----------- | ----- | -------- |
| LDAP        | 389   | TCP      |
| LDAP (SSL)  | 636   | TCP      |
| RDP         | 3389  | TCP      |
| VNC         | 5900  | TCP      |
| Squid Proxy | 3128  | TCP      |
| HashiCorp Consul | 8500 | TCP |
| HashiCorp Vault  | 8200 | TCP |
| SNMP        | 161, 162 | UDP   |
| Syslog      | 514   | TCP/UDP  |
| Cloudflared | -     | -        |
