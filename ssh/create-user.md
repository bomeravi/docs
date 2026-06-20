# Create a Deployer User

A practical, copy-paste guide to set up a dedicated `deployer` user for
CI/CD. By the end you'll have a user that:

- Logs in over **SSH with keys only** (no password).
- Has **no account password** at all.
- Runs `sudo` **without a password prompt**, so **Jenkins** can run
  deployment commands non-interactively.

Run everything below as `root` or a `sudo` user. Replace `deployer` and
`your_server_ip` with your own values.

---

## 1. Create the passwordless user

```bash
sudo adduser --disabled-password --gecos "" deployer
```

- `--disabled-password` → no usable password; the user can only log in
  via SSH keys.
- `--gecos ""` → skips the interactive name/phone prompts.

### Or: create a user *with* a password

If you want a password (e.g. for console access or `su`), create it
interactively — you'll be prompted to set and confirm the password:

```bash
sudo adduser deployer
```

Or set it non-interactively (handy for scripts):

```bash
sudo adduser --gecos "" deployer
echo "deployer:YourStrongPassword" | sudo chpasswd
```

> Even with a password set, the SSH key + passwordless-sudo steps below
> still apply. To later switch a password user back to key-only, lock the
> password with `sudo passwd -l deployer`.

### Add it to the `sudo` group

```bash
sudo usermod -aG sudo deployer
```

---

## 2. Give it your SSH key

The `deployer` user needs an `authorized_keys` file with the public keys
allowed to log in. Pick **one** source below — they all do the same
thing: put trusted public keys into `/home/deployer/.ssh/authorized_keys`.

```bash
sudo mkdir -p /home/deployer/.ssh
```

**From your current login user** (the keys you used to reach this server):

```bash
sudo cp "$HOME/.ssh/authorized_keys" /home/deployer/.ssh/authorized_keys
```

**From root** (common on fresh cloud servers where you first log in as root):

```bash
sudo cp /root/.ssh/authorized_keys /home/deployer/.ssh/authorized_keys
```

**From another existing user** (e.g. `ubuntu`):

```bash
sudo cp /home/ubuntu/.ssh/authorized_keys /home/deployer/.ssh/authorized_keys
```

---

## 3. Fix ownership and permissions

SSH **refuses** key login if these are wrong — do this every time you
copy files in as root:

```bash
sudo chown -R deployer:deployer /home/deployer/.ssh
sudo chmod 700 /home/deployer/.ssh
sudo chmod 600 /home/deployer/.ssh/authorized_keys
```

---

## 4. Test the login

From your **local machine**:

```bash
ssh deployer@your_server_ip
```

You should land in a shell with **no password prompt**. If it asks for a
password, the key or permissions in step 2–3 are wrong.

---

## 5. Passwordless sudo for Jenkins

Jenkins runs commands non-interactively, so `deployer` must use `sudo`
without being prompted. Add a sudoers drop-in (never edit `/etc/sudoers`
directly — a typo there locks out sudo):

```bash
echo "deployer ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/deployer
sudo chmod 440 /etc/sudoers.d/deployer
sudo visudo -c
```

`visudo -c` should print:

```
/etc/sudoers.d/deployer: parsed OK
```

**Tighter alternative** — grant only what the pipeline needs instead of
`ALL`:

```bash
echo "deployer ALL=(ALL) NOPASSWD: /usr/bin/systemctl, /usr/bin/docker" \
  | sudo tee /etc/sudoers.d/deployer
sudo chmod 440 /etc/sudoers.d/deployer
```

Verify it works:

```bash
sudo -u deployer sudo whoami   # → root, with no password prompt
```

---

## 6. (Optional) Give deployer its own outbound key

If Jenkins (running as `deployer`) needs to clone private Git repos or
SSH to other servers, generate a **dedicated** key for it — don't copy
root's private key around:

```bash
sudo -u deployer ssh-keygen -t ed25519 -N "" -f /home/deployer/.ssh/id_ed25519
sudo cat /home/deployer/.ssh/id_ed25519.pub   # add this to GitHub/GitLab deploy keys
```

---

## Recap

| Step | Command |
| ---- | ------- |
| Create user | `sudo adduser --disabled-password --gecos "" deployer` |
| Add to sudo | `sudo usermod -aG sudo deployer` |
| Copy keys | `sudo cp <source>/.ssh/authorized_keys /home/deployer/.ssh/` |
| Fix perms | `chown -R deployer:deployer`, `chmod 700` / `600` |
| Passwordless sudo | `deployer ALL=(ALL) NOPASSWD:ALL` in `/etc/sudoers.d/deployer` |
| Validate | `sudo visudo -c` |

`deployer` now logs in by key with no password and runs `sudo` silently —
ready to drop into a Jenkins SSH credential.
