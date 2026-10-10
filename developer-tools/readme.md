---
pagination_label: Developer Tools
---

# Developer Tools

A collection of useful tools that help developers build, test, and debug applications more efficiently during local development and on staging environments.

---

## Tools

| Tool | Purpose |
|---|---|
| [Mailpit](./mailpit.md) | Local SMTP server and email testing UI — catches outgoing emails without sending them |
| [tmux](./tmux.md) | Terminal multiplexer — keep queue workers, schedulers and other long-running processes alive after SSH disconnects |

---

## Email Testing

- [Mailpit](./mailpit.md) — Lightweight local SMTP catcher with a web UI. Captures all emails sent by your application during development. Supports reverse proxy setup with Apache2, Nginx, and HAProxy.

---

## Server Process Management

- [tmux](./tmux.md) — Persistent terminal sessions for running background processes on servers, with recipes for Laravel queue workers, the scheduler, Horizon, Node/Python apps, and starting sessions on boot.
