# HAProxy 

> **HAProxy** (High Availability Proxy) is a free, open-source TCP/HTTP load balancer and proxy server. This guide covers installation, basic configuration, and common usage patterns.


## Prerequisites

| Requirement | Details |
|---|---|
| OS | Linux (Ubuntu, Debian, RHEL, CentOS, Fedora) |
| Privileges | `root` or `sudo` access |
| Ports | Typically 80, 443, or custom ports — must be free |
| SSL certs | Required only for HTTPS termination |

---

## Installation

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y haproxy
```

To install a newer version via the official PPA:

```bash
# Create a directory for the key if it doesn't exist
sudo install -d -m 0755 /usr/share/keyrings
# Download the GPG key
sudo wget -qO /usr/share/keyrings/HAPROXY-key-community.asc https://pks.haproxy.com/linux/community/RPM-GPG-KEY-HAProxy

# Add the HAProxy repository for noble and HAProxy 3.2
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/HAPROXY-key-community.asc] https://www.haproxy.com/download/haproxy/performance/ubuntu/ha32 noble main" | sudo tee /etc/apt/sources.list.d/haproxy.list

sudo apt-get update
sudo apt-get install haproxy-awslc
```

### RHEL / CentOS / Fedora

```bash
# CentOS / RHEL
sudo yum install -y haproxy

# Fedora
sudo dnf install -y haproxy
```

### From Source

```bash
# Install build dependencies
sudo apt install -y build-essential libssl-dev libpcre3-dev zlib1g-dev

# Download and compile
wget https://www.haproxy.org/download/2.9/src/haproxy-2.9.0.tar.gz
tar -xzf haproxy-2.9.0.tar.gz
cd haproxy-2.9.0

make TARGET=linux-glibc USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1
sudo make install
```

### Docker

```bash
docker run -d \
  --name haproxy \
  -p 80:80 \
  -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  haproxy:latest
```

To reload config inside Docker:

```bash
docker kill -s HUP haproxy
```

---

## Configuration Overview

### Config File Location

| Platform | Default Path |
|---|---|
| Ubuntu / Debian | `/etc/haproxy/haproxy.cfg` |
| RHEL / CentOS | `/etc/haproxy/haproxy.cfg` |
| Source install | `/usr/local/etc/haproxy/haproxy.cfg` |
| Docker | Mounted via volume |

### Config Structure

```
global
    # Process-level settings (logging, ulimits, SSL)

defaults
    # Default values inherited by frontends and backends

frontend <name>
    # What to listen on and how to route traffic

backend <name>
    # Where to send traffic (servers, health checks, algorithms)

listen <name>
    # Shorthand: combines frontend + backend in one block
```

---

## Core Sections Explained

### global

Controls the HAProxy process itself.

```haproxy
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # SSL tuning
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
```

### defaults

Default values applied to all frontends and backends unless overridden.

```haproxy
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5s
    timeout client  50s
    timeout server  50s
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
```

### frontend

Defines where HAProxy listens and how it directs traffic.

```haproxy
frontend http_front
    bind *:80
    default_backend http_back

    # Optional: redirect HTTP → HTTPS
    # redirect scheme https if !{ ssl_fc }
```

### backend

Defines the pool of servers that handle requests.

```haproxy
backend http_back
    balance roundrobin
    server web1 192.168.1.10:8080 check
    server web2 192.168.1.11:8080 check
    server web3 192.168.1.12:8080 check backup
```

### listen

Combines frontend and backend in a single block — convenient for simple setups.

```haproxy
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
```

---

## Common Configuration Examples

### HTTP Load Balancer

```haproxy
frontend http_front
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /health
    server web1 10.0.0.1:80 check
    server web2 10.0.0.2:80 check
    server web3 10.0.0.3:80 check
```

### HTTPS Termination (SSL/TLS)

Combine your certificate and private key into a single `.pem` file:

```bash
cat fullchain.pem privkey.pem > /etc/haproxy/certs/example.com.pem
```

```haproxy
frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/example.com.pem
    http-request set-header X-Forwarded-Proto https
    default_backend web_servers

frontend http_front
    bind *:80
    redirect scheme https code 301
```

### TCP Proxy

Use `mode tcp` for non-HTTP protocols (databases, SMTP, custom TCP services).

```haproxy
frontend mysql_front
    bind *:3306
    mode tcp
    default_backend mysql_servers

backend mysql_servers
    mode tcp
    balance leastconn
    server db1 10.0.0.10:3306 check
    server db2 10.0.0.11:3306 check
```

### Health Checks

```haproxy
backend web_servers
    option httpchk GET /healthz HTTP/1.1\r\nHost:\ example.com
    http-check expect status 200

    # inter: interval, fall: failures before down, rise: successes before up
    server web1 10.0.0.1:80 check inter 5s fall 3 rise 2
    server web2 10.0.0.2:80 check inter 5s fall 3 rise 2
```

### Sticky Sessions

Route the same client to the same backend server using cookies.

```haproxy
backend web_servers
    balance roundrobin
    cookie SERVERID insert indirect nocache
    server web1 10.0.0.1:80 check cookie web1
    server web2 10.0.0.2:80 check cookie web2
```

---

## Load Balancing Algorithms

| Algorithm | Keyword | Best For |
|---|---|---|
| Round Robin | `roundrobin` | Equally-spec'd servers, short requests |
| Least Connections | `leastconn` | Long-lived connections, varying load |
| Source IP Hash | `source` | Sticky routing without cookies |
| URI Hash | `uri` | Cache servers (same URI → same server) |
| Random | `random` | Large, homogeneous server pools |
| Static Round Robin | `static-rr` | Round robin but not dynamic weight changes |

```haproxy
backend web_servers
    balance leastconn
    # ...
```

---

## ACLs and Routing

ACLs (Access Control Lists) let you route traffic based on request properties.

```haproxy
frontend http_front
    bind *:80

    # Define ACLs
    acl is_api    path_beg /api/
    acl is_static path_end .css .js .png .jpg .ico
    acl is_mobile hdr_sub(User-Agent) -i mobile android iphone

    # Route based on ACLs
    use_backend api_servers    if is_api
    use_backend static_servers if is_static
    use_backend mobile_servers if is_mobile
    default_backend web_servers
```

### Common ACL Matchers

| Matcher | Example | Matches |
|---|---|---|
| `path_beg` | `path_beg /api` | URL starts with `/api` |
| `path_end` | `path_end .php` | URL ends with `.php` |
| `path_reg` | `path_reg ^/v[0-9]+/` | URL matches regex |
| `hdr` | `hdr(host) example.com` | Exact header value |
| `hdr_beg` | `hdr_beg(host) api.` | Header starts with |
| `hdr_sub` | `hdr_sub(User-Agent) curl` | Header contains string |
| `src` | `src 10.0.0.0/8` | Source IP range |

---

## Stats Dashboard

Enable the built-in web UI for real-time monitoring.

```haproxy
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats realm HAProxy\ Stats
    stats auth admin:yourpassword
    stats refresh 5s
    stats show-legends
    stats show-node
```

Access at: `http://your-server:8404/stats`

> ⚠️ **Restrict access to the stats page** in production using firewall rules or ACLs.

---

## Managing the Service

```bash
# Start / Stop / Restart
sudo systemctl start haproxy
sudo systemctl stop haproxy
sudo systemctl restart haproxy

# Graceful reload (no dropped connections)
sudo systemctl reload haproxy

# Enable on boot
sudo systemctl enable haproxy

# Check status
sudo systemctl status haproxy
```

### Runtime API (via socket)

```bash
# Connect to the runtime API
sudo socat stdio /run/haproxy/admin.sock

# Useful commands
echo "show info" | sudo socat stdio /run/haproxy/admin.sock
echo "show servers state" | sudo socat stdio /run/haproxy/admin.sock
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock

# Disable a server temporarily
echo "disable server web_servers/web1" | sudo socat stdio /run/haproxy/admin.sock

# Re-enable
echo "enable server web_servers/web1" | sudo socat stdio /run/haproxy/admin.sock
```

---

## Logging

HAProxy logs to syslog by default. Configure rsyslog to capture its output:

```bash
# /etc/rsyslog.d/49-haproxy.conf
$AddUnixListenSocket /dev/log

:programname, startswith, "haproxy" {
  /var/log/haproxy.log
  stop
}
```

```bash
sudo systemctl restart rsyslog
```

To view logs:

```bash
sudo tail -f /var/log/haproxy.log
```

---

## Testing Your Config

**Always validate before reloading in production.**

```bash
# Check config syntax
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Check with a specific config file path
haproxy -c -f /path/to/custom.cfg

# Dry-run (parse and exit without binding ports)
sudo haproxy -f /etc/haproxy/haproxy.cfg -c
```

Expected output on success:

```
Configuration file is valid
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `502 Bad Gateway` | Backend servers down | Check server health, firewall rules |
| `503 Service Unavailable` | All backends failed health checks | Verify health check endpoint and ports |
| Config fails to reload | Syntax error | Run `haproxy -c -f haproxy.cfg` and fix errors |
| Port already in use | Another process on same port | `sudo ss -tlnp \| grep <port>` |
| SSL handshake failure | Wrong cert/key or TLS version | Check cert path, key match, and `ssl-min-ver` |
| High memory usage | `maxconn` too high | Tune `maxconn` in `global` and per-server |

```bash
# Check what's listening on a port
sudo ss -tlnp | grep 80

# View HAProxy version and build options
haproxy -v

# Test backend connectivity from the HAProxy host
curl -I http://10.0.0.1:8080/health
```

---

## Security Hardening Tips

- **Run as non-root**: Use `user haproxy` and `group haproxy` in the `global` section.
- **Use `chroot`**: Restrict filesystem access with `chroot /var/lib/haproxy`.
- **Enforce TLS 1.2+**: Set `ssl-min-ver TLSv1.2` to disable older protocols.
- **Hide version info**: Add `http-response del-header Server` to remove server headers.
- **Rate limiting**: Use `stick-table` to throttle abusive clients:

```haproxy
frontend http_front
    bind *:80
    stick-table type ip size 100k expire 30s store conn_cur,conn_rate(10s),http_req_rate(10s)
    tcp-request connection track-sc0 src
    tcp-request connection reject if { sc_conn_rate(0) gt 100 }
    default_backend web_servers
```

- **Restrict stats page**: Limit access by IP with an ACL:

```haproxy
listen stats
    bind *:8404
    acl allowed_ips src 10.0.0.0/8 127.0.0.1
    http-request deny if !allowed_ips
    stats enable
    stats uri /stats
```
