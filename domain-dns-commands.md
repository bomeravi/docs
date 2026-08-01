# DNS & Domain Terminal Commands

A cheat sheet of terminal commands for inspecting a domain — DNS records,
propagation, expiry, WHOIS, reverse DNS, and more. Covers **Ubuntu/Linux,
macOS, and Windows**.

> Every example uses `sajiloapps.com`. Swap in your own domain as needed.

---

## Table of Contents

- [Requirements](#requirements)
- [Ping a Domain](#ping-a-domain)
- [Basic DNS Lookup](#basic-dns-lookup)
- [A Record (IPv4)](#a-record-ipv4)
- [AAAA Record (IPv6)](#aaaa-record-ipv6)
- [NS Record (Nameservers)](#ns-record-nameservers)
- [MX Record (Mail Servers)](#mx-record-mail-servers)
- [TXT Record (SPF, DKIM, DMARC)](#txt-record-spf-dkim-dmarc)
- [CNAME Record](#cname-record)
- [SOA Record](#soa-record)
- [All Records at Once](#all-records-at-once)
- [Query a Specific DNS Server](#query-a-specific-dns-server)
- [Reverse DNS (PTR) Lookup](#reverse-dns-ptr-lookup)
- [Domain and SSL Expiry](#domain-and-ssl-expiry)
- [WHOIS Lookup](#whois-lookup)
- [Trace DNS Resolution Path](#trace-dns-resolution-path)
- [Trace Network Path](#trace-network-path)
- [Check HTTP and HTTPS Response](#check-http-and-https-response)
- [DNS Propagation Check](#dns-propagation-check)
- [Flush Local DNS Cache](#flush-local-dns-cache)
- [Windows Equivalents](#windows-equivalents)
- [Troubleshooting](#troubleshooting)
- [Summary](#summary)

---

## Requirements

Install the common DNS tools.

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install dnsutils whois traceroute mtr-tiny -y
```

**macOS** (`dig`, `whois`, and `traceroute` are mostly preinstalled):

```bash
brew install whois bind mtr
```

---

## Ping a Domain

```bash
ping sajiloapps.com
```

Limit to 4 packets:

```bash
ping -c 4 sajiloapps.com
```

---

## Basic DNS Lookup

**dig:**

```bash
dig sajiloapps.com
```

**nslookup:**

```bash
nslookup sajiloapps.com
```

---

## A Record (IPv4)

**dig:**

```bash
dig A sajiloapps.com +short
```

**nslookup:**

```bash
nslookup -type=A sajiloapps.com
```

---

## AAAA Record (IPv6)

**dig:**

```bash
dig AAAA sajiloapps.com +short
```

**nslookup:**

```bash
nslookup -type=AAAA sajiloapps.com
```

---

## NS Record (Nameservers)

**dig:**

```bash
dig NS sajiloapps.com +short
```

**nslookup:**

```bash
nslookup -type=NS sajiloapps.com
```

---

## MX Record (Mail Servers)

**dig:**

```bash
dig MX sajiloapps.com +short
```

**nslookup:**

```bash
nslookup -type=MX sajiloapps.com
```

---

## TXT Record (SPF, DKIM, DMARC)

All TXT records:

```bash
dig TXT sajiloapps.com +short
```

DKIM — replace `selector` with the actual selector, e.g. `google` or `default`:

```bash
dig TXT selector._domainkey.sajiloapps.com +short
```

DMARC:

```bash
dig TXT _dmarc.sajiloapps.com +short
```

---

## CNAME Record

```bash
dig CNAME www.sajiloapps.com +short
```

---

## SOA Record

The zone authority record — primary nameserver, admin contact, and TTLs.

```bash
dig SOA sajiloapps.com +short
```

---

## All Records at Once

```bash
dig sajiloapps.com ANY +noall +answer
```

> Most resolvers now refuse `ANY` queries (RFC 8482) and return a minimal
> answer. Loop over the common types instead:

```bash
for t in A AAAA NS MX TXT CNAME SOA; do
  echo "== $t =="
  dig $t sajiloapps.com +short
done
```

---

## Query a Specific DNS Server

Use `@server` to bypass your local resolver and ask a specific DNS server
directly.

**Google DNS (8.8.8.8):**

```bash
dig @8.8.8.8 sajiloapps.com A +short
```

**Cloudflare DNS (1.1.1.1):**

```bash
dig @1.1.1.1 sajiloapps.com A +short
```

**Quad9 (9.9.9.9):**

```bash
dig @9.9.9.9 sajiloapps.com A +short
```

**OpenDNS (208.67.222.222):**

```bash
dig @208.67.222.222 sajiloapps.com A +short
```

**The domain's own authoritative nameserver:**

```bash
# 1. find the nameserver
dig NS sajiloapps.com +short

# 2. query it directly
dig @ns1.sajiloapps.com sajiloapps.com A +short
```

**With `nslookup`** (server as the last argument):

```bash
nslookup sajiloapps.com 8.8.8.8
nslookup sajiloapps.com 1.1.1.1
```

---

## Reverse DNS (PTR) Lookup

Find the hostname behind an IP address.

**dig:**

```bash
dig -x 8.8.8.8 +short
```

**nslookup:**

```bash
nslookup 8.8.8.8
```

> Reverse DNS is published by whoever owns the IP block — usually your hosting
> provider, not your registrar. A missing PTR record is normal unless you set
> one up.

---

## Domain and SSL Expiry

### Domain expiry date (via WHOIS)

```bash
whois sajiloapps.com | grep -iE "Expiry|Expiration|Registry Expiry Date"
```

### SSL certificate expiry

```bash
echo | openssl s_client -servername sajiloapps.com -connect sajiloapps.com:443 2>/dev/null | openssl x509 -noout -dates
```

Just the expiry date:

```bash
echo | openssl s_client -servername sajiloapps.com -connect sajiloapps.com:443 2>/dev/null | openssl x509 -noout -enddate
```

Expected output:

```text
notAfter=Oct 30 23:59:59 2026 GMT
```

---

## WHOIS Lookup

Full registration info — registrar, creation date, expiry, nameservers, status:

```bash
whois sajiloapps.com
```

Filter the key fields:

```bash
whois sajiloapps.com | grep -iE "Registrar:|Creation Date|Registry Expiry Date|Name Server|Domain Status"
```

---

## Trace DNS Resolution Path

Show the full resolver trace, from the root servers down:

```bash
dig +trace sajiloapps.com
```

Show query time and which server answered:

```bash
dig sajiloapps.com +stats
```

---

## Trace Network Path

```bash
traceroute sajiloapps.com
```

Faster alternative with live, continuously updating stats:

```bash
mtr sajiloapps.com
```

---

## Check HTTP and HTTPS Response

Headers only:

```bash
curl -I https://sajiloapps.com
```

Follow redirects and show total timing:

```bash
curl -IL -w "\nTotal time: %{time_total}s\n" https://sajiloapps.com
```

---

## DNS Propagation Check

Query several public resolvers and compare the answers after a DNS change:

```bash
for server in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do
  echo "== $server =="
  dig @$server sajiloapps.com A +short
done
```

Identical results across all four means the change has propagated.

---

## Flush Local DNS Cache

**Ubuntu (systemd-resolved):**

```bash
sudo resolvectl flush-caches

# older systemd:
sudo systemd-resolve --flush-caches
```

**macOS:**

```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

**Windows (PowerShell/cmd):**

```powershell
ipconfig /flushdns
```

---

## Windows Equivalents

| Task                  | Command                                              |
| --------------------- | ---------------------------------------------------- |
| Ping                  | `ping sajiloapps.com`                                 |
| DNS lookup            | `nslookup sajiloapps.com`                             |
| A record              | `nslookup -type=A sajiloapps.com`                     |
| MX record             | `nslookup -type=MX sajiloapps.com`                    |
| NS record             | `nslookup -type=NS sajiloapps.com`                    |
| Query specific server | `nslookup sajiloapps.com 8.8.8.8`                     |
| Trace route           | `tracert sajiloapps.com`                              |
| Flush DNS cache       | `ipconfig /flushdns`                                  |
| WHOIS                 | `winget install whois`, or use an online lookup       |

> Tip: install `dig` on Windows via the
> [BIND tools for Windows](https://www.isc.org/download/), or use WSL for the
> full Linux command set.

---

## Troubleshooting

### `dig` or `whois`: command not found

```bash
sudo apt install dnsutils whois -y
```

### Query times out

Check that the firewall isn't blocking UDP/TCP port 53:

```bash
sudo ufw status
```

### Stale results after a DNS change

DNS changes take time to propagate, bounded by the record's TTL. Query the
authoritative nameserver directly to confirm the change is live, then wait out
the TTL for public resolvers to catch up:

```bash
dig NS sajiloapps.com +short
dig @ns1.sajiloapps.com sajiloapps.com A +short
```

### WHOIS shows no expiry field

Some TLD registries (`.io` and various ccTLDs) return non-standard WHOIS
formats. Ask IANA for the authoritative WHOIS server:

```bash
whois -h whois.iana.org sajiloapps.com
```

---

## Summary

| Task                | Command                                                    |
| ------------------- | ---------------------------------------------------------- |
| Resolve IPv4        | `dig A sajiloapps.com +short`                               |
| Nameservers         | `dig NS sajiloapps.com +short`                              |
| Mail servers        | `dig MX sajiloapps.com +short`                              |
| SPF / DKIM / DMARC  | `dig TXT sajiloapps.com +short`                             |
| Ask a resolver      | `dig @1.1.1.1 sajiloapps.com A +short`                      |
| Reverse lookup      | `dig -x 8.8.8.8 +short`                                     |
| Registration info   | `whois sajiloapps.com`                                      |
| SSL expiry          | `openssl s_client -connect sajiloapps.com:443` → `x509 -noout -enddate` |
| Full resolver trace | `dig +trace sajiloapps.com`                                 |
| Flush cache         | `sudo resolvectl flush-caches`                              |

---

## Related

- [Cloudflared](./cloudflared.md) — expose a local service on a subdomain
  through a Cloudflare Tunnel.
- [Certbot](./security/certbot.md) — issue and renew the TLS certificate behind
  the SSL expiry checks above.
