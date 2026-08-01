# Allow Multiple SSH Keys

Grant several people or machines access to the same server account by listing
multiple public keys in `~/.ssh/authorized_keys`. Each person keeps their own
private key, so access can be revoked individually without disturbing anyone
else.

> Never share a private key between people. Add one public key per person —
> that is what makes revocation possible.

---

## How `authorized_keys` works

The file holds **one public key per line**. SSH accepts a login if the
presented private key matches *any* line in the file, so adding a line grants
access and deleting it removes access.

```bash
cat ~/.ssh/authorized_keys
```

The comment at the end of each line (e.g. `alice@laptop`) is free text — use it
to record whose key it is, since that is the only practical way to tell them
apart later.

---

## 1. Add a Single Public Key

Ask the person for the contents of their `~/.ssh/id_ed25519.pub`, then append
it:

```bash
echo "ssh-ed25519 AAAAC3NzaC1... alice@laptop" >> ~/.ssh/authorized_keys
```

> ⚠️ Use `>>` (append), never `>` (overwrite). A single `>` erases every
> existing key in the file and can lock out everyone, including you.

From your own machine, `ssh-copy-id` does the same thing safely:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@YOUR_SERVER_IP
```

---

## 2. Import Public Keys from GitHub

GitHub publishes every user's public keys at `https://github.com/<user>.keys`,
which makes onboarding a teammate a one-liner:

```bash
curl https://github.com/GITHUB_USERNAME.keys >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

> This imports **all** keys currently on that GitHub account. Review the result
> with `cat ~/.ssh/authorized_keys` so you know exactly what you granted.

---

## 3. Add Keys for Another User

To grant access to a different account on the server (for example the `ubuntu`
deploy user), write to that user's home directory and hand ownership over:

```bash
sudo mkdir -p /home/ubuntu/.ssh
sudo curl https://github.com/GITHUB_USERNAME.keys >> /home/ubuntu/.ssh/authorized_keys
sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
sudo chmod 700 /home/ubuntu/.ssh
sudo chmod 600 /home/ubuntu/.ssh/authorized_keys
```

The `chown` matters — a `.ssh` directory still owned by `root` leaves the
target user unable to log in.

---

## 4. Fix Permissions

SSH refuses to use an `authorized_keys` file that is group- or world-writable,
and it fails **silently**: the login simply falls back to a password prompt or
is rejected outright.

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

## 5. Verify

Test from another terminal, keeping your current session open:

```bash
ssh ubuntu@SERVER_IP
```

See which key was offered and accepted:

```bash
ssh -v ubuntu@SERVER_IP 2>&1 | grep -i "offering\|accepted"
```

Count the keys currently authorized:

```bash
grep -c '^ssh-' ~/.ssh/authorized_keys
```

---

## 6. Revoke Access

Delete that person's line from the file:

```bash
nano ~/.ssh/authorized_keys
```

Removal takes effect on the next login attempt — no service reload is needed.
Existing sessions stay connected, so terminate them too if the revocation is
urgent:

```bash
# list active sessions
who

# disconnect a specific session
sudo pkill -9 -t pts/1
```

---

## Troubleshooting

### Still prompted for a password

Permissions are the usual cause:

```bash
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

Expect `drwx------` on the directory and `-rw-------` on the file.

### Key rejected by the server

Check what `sshd` logged:

```bash
sudo journalctl -u ssh -n 50
```

### Confirm the server config permits keys

```bash
sudo sshd -T | grep -i "pubkeyauthentication\|authorizedkeysfile"
```

---

## Summary

| Task | Command |
| ---- | ------- |
| Append one key | `echo "ssh-ed25519 …" >> ~/.ssh/authorized_keys` |
| Copy your own key | `ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host` |
| Import from GitHub | `curl https://github.com/USER.keys >> ~/.ssh/authorized_keys` |
| Fix permissions | `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys` |
| Count authorized keys | `grep -c '^ssh-' ~/.ssh/authorized_keys` |
| Revoke | Delete that key's line from `authorized_keys` |

---

## Done ✅

Multiple people can now log into the account with their own keys, and any one
of them can be revoked without affecting the others.

---

## Related

- [SSH Key Generation and Management](./generate-keys.md) — create the keypairs
  being added here.
- [Create a Deployer User](./create-user.md) — set up the account these keys
  grant access to.
- [Disable Root Login](./disable-root-ubuntu.md) — harden access once key login
  is confirmed working.
