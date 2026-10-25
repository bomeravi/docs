# SSH Port Forwarding (Tunnels)

Reach a service on a remote machine (or expose a local one) through an
encrypted SSH connection, using key-based or password login.

---

## Local Forward (`-L`)

Open a port on **your machine** that forwards to a port reachable from the
**server**. Typical use: a web UI or database bound to `127.0.0.1` on the server.

```bash
ssh -N -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

Then open `http://localhost:8081` locally — it is served by `127.0.0.1:8080`
on `100.100.10.2`.

Format: `-L [local_bind:]local_port:target_host:target_port`

| Part | Meaning |
|------|---------|
| `-N` | Don't run a remote command — tunnel only (no shell) |
| `8081` | Port opened on your local machine |
| `127.0.0.1:8080` | Target, resolved **from the server's side** |
| `ubuntu@100.100.10.2` | SSH server to tunnel through |

> `127.0.0.1` in the target means the server itself, not your laptop.

### Forward several ports at once

```bash
ssh -N -L 8081:127.0.0.1:8080 -L 5433:127.0.0.1:5432 ubuntu@100.100.10.2
```

### Reach another host behind the server

```bash
ssh -N -L 5432:db.internal:5432 ubuntu@100.100.10.2
```

### Custom SSH port

```bash
ssh -N -p 2222 -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

---

## Authentication Options

### With a specific private key

`-i` picks the private key file; `-o IdentitiesOnly=yes` makes SSH use **only**
that key instead of trying every key in `~/.ssh` and your agent first (which can
trigger `Too many authentication failures`).

```bash
ssh -N -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes \
    -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

With a `.pem` key (e.g. a cloud provider key) on a custom port, in the
background:

```bash
ssh -f -N -p 2222 -i ~/.ssh/my-server.pem -o IdentitiesOnly=yes \
    -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

The private key must be readable only by you, or SSH refuses it with
`UNPROTECTED PRIVATE KEY FILE!`:

```bash
chmod 600 ~/.ssh/my-server.pem
```

If the key has a passphrase, SSH prompts for it on each run. Load it into the
agent once to avoid that:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

> Create and install keys with [SSH Key Generation](./generate-keys.md).

### With a password (interactive prompt)

If the server allows `PasswordAuthentication yes`, the plain command already
prompts for the password. Force it so SSH skips your keys and goes straight to
the prompt:

```bash
ssh -N \
    -o PubkeyAuthentication=no \
    -o PreferredAuthentications=password \
    -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

```text
ubuntu@100.100.10.2's password:
```

> With `-N` nothing is printed after login — the cursor just waits. That means
> the tunnel is up. Press `Ctrl+C` to close it.

### With a password, non-interactive (`sshpass`)

For scripts where nobody can type the password. Install it first:

```bash
sudo apt install sshpass -y
```

Read the password from an environment variable (`-e` uses `$SSHPASS`):

```bash
export SSHPASS='your_password'
sshpass -e ssh -N \
    -o PubkeyAuthentication=no \
    -o PreferredAuthentications=password \
    -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

Or read it from a file readable only by you:

```bash
echo 'your_password' > ~/.ssh/tunnel.pass
chmod 600 ~/.ssh/tunnel.pass
sshpass -f ~/.ssh/tunnel.pass ssh -N -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

> ⚠️ Avoid `sshpass -p 'your_password'` — the password is visible in
> `ps` output and shell history. Prefer SSH keys whenever possible.

> On the first connection `sshpass` fails silently if the host key is unknown.
> Connect once interactively to accept it, or add
> `-o StrictHostKeyChecking=accept-new`.

---

## Run in the Background (`-f`)

`-f` sends SSH to the background after authentication (password prompts still
work first):

```bash
ssh -f -N -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

Find and stop it:

```bash
pgrep -af "ssh -f -N -L 8081"
pkill -f "ssh -f -N -L 8081"
```

Add `-o ExitOnForwardFailure=yes` so SSH exits instead of running without a
tunnel when the local port is already taken.

---

## Remote Forward (`-R`)

The reverse: open a port on the **server** that forwards back to a service on
**your machine**. Example: let the server reach your local app on port `3000`.

```bash
ssh -N -R 9000:127.0.0.1:3000 ubuntu@100.100.10.2
```

On the server, `curl http://127.0.0.1:9000` hits your local port `3000`.

> To expose the remote port beyond the server's localhost, set
> `GatewayPorts yes` in the server's `/etc/ssh/sshd_config`.

---

## Dynamic Forward / SOCKS Proxy (`-D`)

Turn the server into a SOCKS5 proxy for your browser or tools:

```bash
ssh -N -D 1080 ubuntu@100.100.10.2
```

```bash
curl --socks5-hostname 127.0.0.1:1080 http://127.0.0.1:8080
```

---

## Save Tunnels in `~/.ssh/config`

```text
Host app-tunnel
    HostName 100.100.10.2
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    LocalForward 8081 127.0.0.1:8080
    LocalForward 5433 127.0.0.1:5432
    ExitOnForwardFailure yes
    ServerAliveInterval 30
```

```bash
ssh -N app-tunnel
```

See [SSH Client Config](./client-config.md) for the other options.

---

## Keep a Tunnel Alive (`autossh`)

`autossh` restarts the tunnel if the connection drops. Best with key auth:

```bash
sudo apt install autossh -y
autossh -M 0 -f -N \
    -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
    -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `bind: Address already in use` | Local port is taken — pick another or `sudo ss -tlnp \| grep 8081` |
| `channel 2: open failed: connect failed` | Nothing is listening on the target port on the server |
| `Permission denied (publickey)` | Server has password login disabled — use a key |
| `administratively prohibited` | Server has `AllowTcpForwarding no` in `sshd_config` |
| Tunnel dies when idle | Add `-o ServerAliveInterval=30` or use `autossh` |

Debug the connection with verbose output:

```bash
ssh -v -N -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2
```

---

## Summary

| Goal | Command |
|------|---------|
| Local forward | `ssh -N -L 8081:127.0.0.1:8080 ubuntu@100.100.10.2` |
| Use a specific key | add `-i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes` |
| Force password login | add `-o PubkeyAuthentication=no -o PreferredAuthentications=password` |
| Password in a script | `sshpass -e ssh -N -L …` with `$SSHPASS` set |
| Background | add `-f` |
| Remote forward | `ssh -N -R 9000:127.0.0.1:3000 ubuntu@100.100.10.2` |
| SOCKS proxy | `ssh -N -D 1080 ubuntu@100.100.10.2` |
| Auto-reconnect | `autossh -M 0 -f -N -L …` |
