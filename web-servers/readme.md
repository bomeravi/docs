---
pagination_label: Web Servers
---

# Web Servers

Installation, configuration, and per-scenario config files for the web servers and
reverse proxies used across these docs.

## Guides in this folder

- [NGINX](./nginx.md): install, server blocks, and configs for static hosting, PHP-FPM, reverse proxy, SPA, load balancing, HTTPS, and hardening.
- [Apache](./apache.md): install, modules, and virtual hosts for the same scenarios in Apache syntax.

## Which one?

| Need | Use |
| ---- | --- |
| High-concurrency static files, reverse proxy, low memory | **NGINX** |
| `.htaccess` per-directory overrides, legacy PHP apps, module ecosystem | **Apache** |
| Dedicated TCP/HTTP load balancing with a stats dashboard | **[HAProxy](../haproxy.md)** |

## Related pages

- [LAMP Setup](../lamp-setup.md): Apache + MySQL + multi-version PHP stack.
- [HAProxy](../haproxy.md): load balancer configuration and ACL routing.
- [Certbot](../security/certbot.md): Let's Encrypt certificates for both servers.
- [Custom HTTPS](../security/custom-https.md): locally trusted certificates for development.
- [Jenkins Apache Setup](../jenkins/apache-setup.md): a worked Apache reverse-proxy vhost.

> ⚠️ NGINX and Apache both bind port 80/443. Run one, or move the second to another port.
