# Basic Linux Commands

A quick reference of the everyday Linux commands used across these docs —
navigating the filesystem, managing files and permissions, inspecting
processes, and administering an Ubuntu/Debian server. Commands are grouped by
task; run any command with `--help` or `man <command>` for full options.

> Most administrative commands need root. Prefix them with `sudo` or run as a
> user with sudo rights.

---

## Navigation

| Command | Description |
| ------- | ----------- |
| `pwd` | Print the current working directory |
| `ls -lah` | List all files, long format, human-readable sizes |
| `cd /path` | Change to a directory (`cd ~` home, `cd -` previous) |
| `tree -L 2` | Show a directory tree two levels deep |
| `find . -name "*.log"` | Find files by name under the current directory |

---

## Files and directories

| Command | Description |
| ------- | ----------- |
| `touch file` | Create an empty file / update its timestamp |
| `mkdir -p a/b/c` | Create nested directories |
| `cp -r src dst` | Copy files/directories recursively |
| `mv old new` | Move or rename |
| `rm -rf dir` | Remove recursively and forcefully |
| `ln -s target link` | Create a symbolic link |

> ⚠️ `rm -rf` is irreversible and does not ask for confirmation. Double-check
> the path before running it.

---

## Viewing and editing

| Command | Description |
| ------- | ----------- |
| `cat file` | Print a whole file |
| `less file` | Page through a file (`q` to quit, `/` to search) |
| `head -n 20 file` | First 20 lines |
| `tail -n 50 file` | Last 50 lines |
| `tail -f file` | Follow a file live (useful for logs) |
| `nano file` / `vim file` | Edit in a terminal editor |

---

## Searching

| Command | Description |
| ------- | ----------- |
| `grep "text" file` | Search for a pattern in a file |
| `grep -rn "text" .` | Recursive search with line numbers |
| `grep -i "text" file` | Case-insensitive search |
| `command \| grep foo` | Filter another command's output |

---

## Permissions and ownership

| Command | Description |
| ------- | ----------- |
| `chmod 644 file` | Set permissions (owner rw, group/other r) |
| `chmod +x script.sh` | Make a file executable |
| `chown user:group file` | Change owner and group |
| `chown -R user:group dir` | Recursively change ownership |

Permission digits are the sum of **read (4) + write (2) + execute (1)** per
owner/group/other — e.g. `755` = `rwxr-xr-x`.

---

## Users and groups

| Command | Description |
| ------- | ----------- |
| `whoami` | Current username |
| `id` | Current user's UID, GID, and groups |
| `sudo adduser bob` | Create a user (interactive) |
| `sudo usermod -aG sudo bob` | Add a user to the `sudo` group |
| `su - bob` | Switch to another user |
| `passwd` | Change your password |

> See [SSH → Create User](/ssh/create-user.md) for the full server user setup.

---

## Processes and resources

| Command | Description |
| ------- | ----------- |
| `ps aux` | List all running processes |
| `top` / `htop` | Live process/resource monitor |
| `kill <pid>` | Send SIGTERM to a process |
| `kill -9 <pid>` | Force kill (SIGKILL) |
| `free -h` | Memory usage, human-readable |
| `df -h` | Disk space per mount |
| `du -sh dir` | Total size of a directory |

---

## Services (systemd)

| Command | Description |
| ------- | ----------- |
| `sudo systemctl status nginx` | Show a service's state |
| `sudo systemctl start/stop nginx` | Start or stop a service |
| `sudo systemctl restart nginx` | Restart a service |
| `sudo systemctl enable --now nginx` | Enable at boot and start now |
| `journalctl -u nginx -f` | Follow a service's logs |

---

## Package management (Ubuntu/Debian)

| Command | Description |
| ------- | ----------- |
| `sudo apt update` | Refresh package lists |
| `sudo apt upgrade` | Upgrade installed packages |
| `sudo apt install <pkg>` | Install a package |
| `sudo apt remove <pkg>` | Remove a package |
| `apt search <term>` | Search available packages |

> See [Basic Packages](/01-basic-packages.md) for the packages installed on a
> fresh server.

---

## Networking

| Command | Description |
| ------- | ----------- |
| `ip a` | Show network interfaces and IPs |
| `ping host` | Test connectivity to a host |
| `wget https://site/file` | Download a file over HTTP(S) |
| `ss -tulpn` | List listening ports and their processes |
| `scp file user@host:/path` | Copy files over SSH |

---

## HTTP requests with curl

`curl` transfers data to and from a URL — use it to download files, test
endpoints, and call APIs from the terminal.

| Command | Description |
| ------- | ----------- |
| `curl https://site` | Fetch a URL and print the body |
| `curl -I https://site` | Headers only (HEAD request) |
| `curl -L https://site` | Follow redirects |
| `curl -o out.html https://site` | Save to a named file |
| `curl -O https://site/file.zip` | Save using the remote filename |
| `curl -fsSL https://site` | Silent, follow redirects, fail on HTTP error |
| `curl -s https://api/x \| jq` | Silent fetch, pipe JSON to `jq` |
| `curl -k https://localhost` | Skip TLS certificate verification |
| `curl -u user:pass https://site` | HTTP basic auth |
| `curl -w "%{http_code}\n" -o /dev/null -s https://site` | Print only the status code |

Send data, headers, and files:

```bash
# POST JSON
curl -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -d '{"name": "bob", "role": "admin"}'

# POST form data
curl -X POST https://example.com/login \
  -d "user=bob&password=secret"

# Send a bearer token
curl https://api.example.com/me \
  -H "Authorization: Bearer $TOKEN"

# Upload a file (multipart)
curl -F "file=@report.pdf" https://example.com/upload
```

> ⚠️ The `curl -fsSL <url> | bash` install pattern runs remote code
> unverified. Only pipe to a shell from sources you trust, and inspect the
> script first when in doubt.

---

## Archives and compression

| Command | Description |
| ------- | ----------- |
| `tar -czf out.tar.gz dir` | Create a gzip-compressed archive |
| `tar -xzf out.tar.gz` | Extract a gzip archive |
| `zip -r out.zip dir` | Create a zip archive |
| `unzip out.zip` | Extract a zip archive |

---

## Done ✅

You now have a lookup table for the common Linux commands used throughout
these docs. Reach for `man <command>` or `<command> --help` whenever you need
the full set of options.
