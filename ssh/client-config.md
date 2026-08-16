# SSH Client Configuration

This document explains the most commonly used parameters in the SSH client
configuration file (`~/.ssh/config`).

## Example Configuration

```text
Host production-server
    HostName 203.0.113.10
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    PreferredAuthentications publickey

Host cloud-server
    HostName 198.51.100.20
    User developer
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host workstation
    HostName 192.168.1.100
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes

Host local-server
    HostName 127.0.0.1
    User ubuntu
    StrictHostKeyChecking accept-new
```

---

## Configuration Parameters

### `Host`

Defines a shortcut (alias) for an SSH connection.

Instead of typing:

```bash
ssh ubuntu@203.0.113.10
```

you can simply use:

```bash
ssh production-server
```

Each `Host` block can have its own configuration.

---

### `HostName`

Specifies the actual hostname or IP address of the remote system.

Examples:

```text
HostName 203.0.113.10
```

or

```text
HostName example.com
```

SSH connects to this address whenever the corresponding `Host` alias is used.

---

### `User`

Specifies the default username on the remote machine.

Example:

```text
User ubuntu
```

Instead of:

```bash
ssh ubuntu@203.0.113.10
```

you only need:

```bash
ssh production-server
```

---

### `IdentityFile`

Specifies the private SSH key used for authentication.

Example:

```text
IdentityFile ~/.ssh/id_rsa
```

The corresponding public key should already exist on the remote machine in:

```text
~/.ssh/authorized_keys
```

Using `IdentityFile` is especially useful when different servers require
different SSH keys.

---

### `PreferredAuthentications`

Specifies the authentication methods SSH should attempt and the order in which
they are tried.

Example:

```text
PreferredAuthentications publickey
```

This tells SSH to authenticate using public-key authentication.

Common values include:

| Value | Description |
|--------|-------------|
| `publickey` | SSH key authentication |
| `password` | Password authentication |
| `keyboard-interactive` | Interactive authentication (e.g., MFA or OTP) |
| `gssapi-with-mic` | Kerberos authentication |

---

### `IdentitiesOnly`

Controls whether SSH should use only the identities explicitly specified by
`IdentityFile`.

Example:

```text
IdentitiesOnly yes
```

#### Without `IdentitiesOnly`

SSH may attempt authentication using:

- Keys loaded in `ssh-agent`
- Default keys (`~/.ssh/id_*`)
- Hardware security keys
- Other available identities

This may result in errors such as:

```text
Too many authentication failures
```

or cause SSH to use the wrong key.

#### With `IdentitiesOnly yes`

SSH uses only the key specified by:

```text
IdentityFile ~/.ssh/id_ed25519
```

This is recommended when connecting to servers that require a specific private
key.

---

### `StrictHostKeyChecking`

Controls how SSH verifies a server's host key.

Example:

```text
StrictHostKeyChecking accept-new
```

#### Available Options

| Value | Description |
|--------|-------------|
| `yes` | Only connect if the host key is already trusted. Rejects unknown or changed host keys. |
| `accept-new` | Automatically trusts new hosts but rejects changed host keys. Recommended for automation. |
| `no` | Automatically accepts all host keys, including changed ones. Least secure. |
| `ask` | Prompts before trusting an unknown host (default behavior). |

#### Recommendation

For CI/CD pipelines and deployment automation, `accept-new` provides a good
balance between convenience and security.

---

## Common SSH Configuration Options

| Parameter | Purpose |
|-----------|---------|
| `Port` | SSH server port (default: `22`) |
| `ProxyJump` | Connect through a jump/bastion host |
| `ForwardAgent` | Forward your local SSH agent |
| `ServerAliveInterval` | Send keepalive packets periodically |
| `ServerAliveCountMax` | Number of missed keepalives before disconnecting |
| `ConnectTimeout` | Maximum time to wait for a connection |
| `Compression` | Enable data compression |
| `LocalForward` | Forward a local port to a remote service |
| `RemoteForward` | Forward a remote port back to your local machine |
| `DynamicForward` | Create a SOCKS proxy |
| `ForwardX11` | Forward X11 graphical applications |
| `AddKeysToAgent` | Automatically add the key to `ssh-agent` |
| `IdentityAgent` | Specify a custom `ssh-agent` socket |
| `LogLevel` | Set SSH logging verbosity |
| `ControlMaster` | Reuse a single SSH connection for multiple sessions |
| `ControlPath` | Path to the shared control socket |
| `ControlPersist` | Keep the shared connection alive after the first session exits |

---

## Example Usage

Connect using the configured aliases:

```bash
ssh production-server
```

```bash
ssh cloud-server
```

```bash
ssh workstation
```

```bash
ssh local-server
```

SSH automatically applies the settings defined for each host, including the
username, authentication key, and connection options.

---

## Multiple Accounts on the Same Host

GitHub allows a given SSH key to be registered to only one account. To use a
personal and a work account from the same machine, define a second `Host` alias
that points at the same `HostName` but uses a different `IdentityFile`.

```text
# Personal GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes

# Work GitHub
Host work.github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
```

Three details make this work:

- `HostName` is `github.com` in **both** blocks. `work.github.com` is only a
  local alias — it is never resolved through DNS.
- `User git` is required by GitHub. Authentication identifies you by key, not
  by username.
- `IdentitiesOnly yes` is essential here. Without it, `ssh-agent` may offer the
  personal key on a work connection, and GitHub authenticates you as whichever
  key it accepts first — silently the wrong account.

### Verify each identity

```bash
ssh -T git@github.com
ssh -T git@work.github.com
```

GitHub names the account it authenticated you as:

```text
Hi personal-username! You've successfully authenticated, but GitHub does not provide shell access.
Hi work-username! You've successfully authenticated, but GitHub does not provide shell access.
```

If both lines show the same username, `IdentitiesOnly yes` is missing or the
wrong key is registered.

### Clone with a specific key

Use the alias in place of the real host in the clone URL:

```bash
git clone git@github.com:personal-username/project.git
```

```bash
git clone git@work.github.com:company/project.git
```

### Repoint an existing clone

A repository cloned before the aliases existed still uses `git@github.com`:

```bash
git remote set-url origin git@work.github.com:company/project.git
git remote -v
```

### Set the matching commit identity

The SSH key controls **push access**; it does not set the author on commits.
Configure that per repository so work commits do not carry a personal email:

```bash
git config user.name "Work Name"
git config user.email "work@example.com"
```

---

## Related

- [SSH Key Generation and Management](./generate-keys.md) — create the keypairs
  referenced by `IdentityFile`.
- [Git Setup Guide](../git/git-setup.md) — applies these same options to run
  work and personal GitHub accounts side by side.
- [Allow Multiple SSH Keys](./allow-multiple-ssh.md) — the server-side half:
  which public keys a server accepts.
- [Install SSH](./readme.md) — server-side settings in `/etc/ssh/sshd_config`,
  not to be confused with the client config above.
