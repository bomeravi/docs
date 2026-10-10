# tmux

> **tmux** is a terminal multiplexer. It keeps shells running inside
> persistent sessions on the server, so long-running processes survive SSH
> disconnects and you can split one terminal into many windows and panes.

This guide covers installing tmux, the everyday keybindings, a server-friendly
`~/.tmux.conf`, and ready-to-use recipes for running background processes —
Laravel queue workers, the scheduler, Node/Python apps, builds and log tails.

---

## Table of Contents

- [How tmux Works](#how-tmux-works)
- [1. Install](#_1-install)
- [2. Sessions](#_2-sessions)
- [3. Windows and Panes](#_3-windows-and-panes)
- [4. Scrollback and Copy Mode](#_4-scrollback-and-copy-mode)
- [5. Configuration (~/.tmux.conf)](#_5-configuration-tmuxconf)
- [6. Running Background Processes](#_6-running-background-processes)
- [7. Laravel on tmux](#_7-laravel-on-tmux)
- [8. Other Common Background Jobs](#_8-other-common-background-jobs)
- [9. One-Command Workspace Script](#_9-one-command-workspace-script)
- [10. Start Sessions on Boot](#_10-start-sessions-on-boot)
- [11. tmux vs Supervisor vs systemd](#_11-tmux-vs-supervisor-vs-systemd)
- [12. Troubleshooting](#_12-troubleshooting)
- [Cheat Sheet](#cheat-sheet)

---

## How tmux Works

```text
tmux server (one per user)
 └── session  "laravel"          ← survives SSH disconnect
      ├── window 0 "queue"       ← like a browser tab
      │    ├── pane 0 (worker)   ← split regions inside a window
      │    └── pane 1 (logs)
      └── window 1 "schedule"
```

- **Prefix key**: every shortcut starts with the prefix, `Ctrl+b` by default
  (written `C-b` below). Press and release it, then press the command key.
- **Detach** leaves everything running on the server; **attach** reconnects
  to it later from any SSH session.
- Sessions belong to the **user** that created them. `sudo tmux ls` will not
  show sessions started by `ubuntu` or `www-data`.

> ⚠️ tmux sessions do **not** survive a server reboot. For processes that must
> always be running in production, see
> [tmux vs Supervisor vs systemd](#_11-tmux-vs-supervisor-vs-systemd).

---

## 1. Install

### Ubuntu / Debian

```bash
sudo apt update && sudo apt install tmux -y
```

### RHEL / Rocky / Amazon Linux

```bash
sudo dnf install tmux -y
```

### macOS

```bash
brew install tmux
```

Verify:

```bash
tmux -V
```

---

## 2. Sessions

### Create

```bash
# New named session (always name sessions on servers)
tmux new -s laravel

# Attach if it exists, otherwise create it
tmux new -A -s laravel

# Create a detached session that runs a command
tmux new -d -s queue 'php artisan queue:work'
```

### Detach, list, attach

| Action                       | Command / Keys          |
| ---------------------------- | ----------------------- |
| Detach from current session  | `C-b d`                 |
| List sessions                | `tmux ls`               |
| Attach to last session       | `tmux a`                |
| Attach to a named session    | `tmux a -t laravel`     |
| Switch session (interactive) | `C-b s`                 |
| Rename current session       | `C-b $`                 |

### Kill

```bash
# Kill one session
tmux kill-session -t laravel

# Kill every session except the one you are in
tmux kill-session -a

# Stop the tmux server (kills all sessions)
tmux kill-server
```

---

## 3. Windows and Panes

### Windows (tabs)

| Action                 | Keys             |
| ---------------------- | ---------------- |
| New window             | `C-b c`          |
| Rename window          | `C-b ,`          |
| Next / previous window | `C-b n` / `C-b p`|
| Go to window N         | `C-b 0` … `C-b 9`|
| List windows           | `C-b w`          |
| Close window           | `C-b &`          |

### Panes (splits)

| Action                     | Keys                    |
| -------------------------- | ----------------------- |
| Split left/right           | `C-b %`                 |
| Split top/bottom           | `C-b "`                 |
| Move between panes         | `C-b` + arrow key       |
| Zoom / unzoom pane         | `C-b z`                 |
| Resize pane                | `C-b` + `Ctrl`+arrow    |
| Cycle layouts              | `C-b Space`             |
| Show pane numbers          | `C-b q`                 |
| Close pane                 | `C-b x` (or `exit`)     |
| Break pane into new window | `C-b !`                 |

---

## 4. Scrollback and Copy Mode

Normal mouse-wheel scrolling does not work by default — use copy mode.

| Action                  | Keys                              |
| ----------------------- | --------------------------------- |
| Enter copy mode         | `C-b [`                           |
| Scroll                  | arrows / `PgUp` / `PgDn`          |
| Search up / down        | `?` / `/` (then `n` for next)     |
| Start / copy selection  | `Space` / `Enter`                 |
| Paste                   | `C-b ]`                           |
| Exit copy mode          | `q`                               |

Save a pane's whole scrollback to a file:

```bash
tmux capture-pane -pS - -t laravel:queue > ~/queue-output.log
```

---

## 5. Configuration (~/.tmux.conf)

A minimal, server-friendly config:

```bash
cat > ~/.tmux.conf <<'EOF'
# Mouse: click panes, drag to resize, wheel to scroll
set -g mouse on

# Bigger scrollback (default is 2000 lines)
set -g history-limit 50000

# Start numbering at 1 (matches the keyboard)
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Faster Esc (helps vim)
set -sg escape-time 10

# 256 colours
set -g default-terminal "screen-256color"

# Intuitive splits that keep the current directory
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# Reload config with C-b r
bind r source-file ~/.tmux.conf \; display "tmux.conf reloaded"

# Status bar: session name + hostname
set -g status-left "#[bold][#S] "
set -g status-right "#H | %Y-%m-%d %H:%M"
EOF
```

Reload inside a running session:

```bash
tmux source-file ~/.tmux.conf
```

---

## 6. Running Background Processes

The general pattern: **one session per project, one window per process**.

### Start a process detached (no need to attach)

```bash
tmux new -d -s myapp -n web 'npm run start'
```

### Add another process as a new window

```bash
tmux new-window -t myapp -n worker 'node worker.js'
```

### Keep the window open after the process exits

By default a window closes when its command ends, hiding the error. Start a
shell first and send the command into it instead:

```bash
tmux new -d -s myapp -n web
tmux send-keys -t myapp:web 'cd /var/www/myapp && npm run start' Enter
```

Or keep dead panes visible:

```bash
tmux set -t myapp remain-on-exit on
```

### Check, restart, stop a process without attaching

```bash
# See what is running
tmux ls
tmux list-windows -t myapp

# Peek at the last 50 lines of output
tmux capture-pane -p -t myapp:web | tail -n 50

# Stop the process (sends Ctrl+C)
tmux send-keys -t myapp:web C-c

# Start it again
tmux send-keys -t myapp:web 'npm run start' Enter

# Kill just that window
tmux kill-window -t myapp:web
```

### Log output to a file as well

```bash
tmux pipe-pane -o -t myapp:web 'cat >> ~/logs/myapp-web.log'
```

---

## 7. Laravel on tmux

Assumes the app is at `/var/www/laravel` and you run commands as the user that
owns the files (often `www-data` or your deploy user).

### 7.1 Queue worker

```bash
tmux new -d -s laravel -n queue -c /var/www/laravel
tmux send-keys -t laravel:queue \
  'php artisan queue:work --sleep=3 --tries=3 --timeout=90 --max-time=3600' Enter
```

| Flag              | Meaning                                                         |
| ----------------- | --------------------------------------------------------------- |
| `--sleep=3`       | Seconds to wait when the queue is empty                         |
| `--tries=3`       | Attempts before a job is marked failed                          |
| `--timeout=90`    | Kill a job running longer than 90 s                             |
| `--max-time=3600` | Exit after 1 h (frees memory; use a restart loop — see below)   |
| `--queue=high,default` | Process queues in priority order                           |

Specific connection / queue:

```bash
php artisan queue:work redis --queue=emails,default
```

### 7.2 Auto-restart loop

`queue:work` exits on `--max-time`, `--max-jobs`, `queue:restart`, or a fatal
error. Wrap it in a loop so tmux keeps it alive:

```bash
tmux send-keys -t laravel:queue \
  'while true; do php artisan queue:work --tries=3 --max-time=3600; echo "worker exited, restarting in 3s"; sleep 3; done' Enter
```

### 7.3 Multiple workers

```bash
for i in 1 2 3; do
  tmux new-window -t laravel -n "queue-$i" -c /var/www/laravel
  tmux send-keys -t "laravel:queue-$i" \
    'while true; do php artisan queue:work --tries=3 --max-time=3600; sleep 3; done' Enter
done
```

### 7.4 Scheduler (instead of cron)

```bash
tmux new-window -t laravel -n schedule -c /var/www/laravel
tmux send-keys -t laravel:schedule 'php artisan schedule:work' Enter
```

### 7.5 Horizon (Redis queues)

```bash
tmux new-window -t laravel -n horizon -c /var/www/laravel
tmux send-keys -t laravel:horizon 'php artisan horizon' Enter
```

### 7.6 Reverb / WebSockets, Vite, logs

```bash
# Reverb websocket server
tmux new-window -t laravel -n reverb -c /var/www/laravel
tmux send-keys -t laravel:reverb 'php artisan reverb:start --host=0.0.0.0 --port=8080' Enter

# Vite dev server (staging/dev only)
tmux new-window -t laravel -n vite -c /var/www/laravel
tmux send-keys -t laravel:vite 'npm run dev -- --host' Enter

# Tail the Laravel log
tmux new-window -t laravel -n logs -c /var/www/laravel
tmux send-keys -t laravel:logs 'tail -f storage/logs/laravel.log' Enter
```

### 7.7 Restart workers after a deploy

Workers keep the old code in memory. After `git pull` / `composer install`:

```bash
cd /var/www/laravel
php artisan queue:restart     # workers finish the current job, then exit
                              # the while-loop from 7.2 starts them again
```

Horizon:

```bash
php artisan horizon:terminate
```

### 7.8 Useful queue commands

```bash
php artisan queue:failed            # list failed jobs
php artisan queue:retry all         # retry all failed jobs
php artisan queue:retry <id>        # retry one job
php artisan queue:forget <id>       # delete one failed job
php artisan queue:flush             # delete all failed jobs
php artisan queue:clear redis --queue=default   # empty a queue
php artisan queue:monitor redis:default --max=100
```

### 7.9 Run as the web user

If files are owned by `www-data`, run tmux as that user so cache/log files keep
the right owner:

```bash
sudo -u www-data tmux new -d -s laravel -n queue -c /var/www/laravel
sudo -u www-data tmux send-keys -t laravel:queue 'php artisan queue:work --tries=3' Enter

# Attach later
sudo -u www-data tmux a -t laravel
```

> ⚠️ `www-data` usually has no login shell. If the window closes immediately,
> pass a shell explicitly: `sudo -u www-data tmux new -d -s laravel /bin/bash`.

---

## 8. Other Common Background Jobs

### Node.js / Express

```bash
tmux new -d -s node -n api -c /var/www/api
tmux send-keys -t node:api 'NODE_ENV=production node server.js' Enter
```

### Python / Django / FastAPI

```bash
tmux new -d -s django -n web -c /var/www/django
tmux send-keys -t django:web 'source venv/bin/activate && gunicorn config.wsgi:application -b 0.0.0.0:8000 -w 3' Enter

tmux new-window -t django -n celery -c /var/www/django
tmux send-keys -t django:celery 'source venv/bin/activate && celery -A config worker -l info' Enter
```

```bash
tmux new -d -s fastapi -c /var/www/fastapi \
  'source venv/bin/activate && uvicorn main:app --host 0.0.0.0 --port 8000'
```

### Go binary

```bash
tmux new -d -s goapp -c /opt/goapp './goapp --port 8080'
```

### Long builds, migrations, backups

```bash
tmux new -d -s build -c /var/www/react 'npm ci && npm run build; read -p "done, press enter"'
tmux new -d -s migrate -c /var/www/laravel 'php artisan migrate --force; bash'
tmux new -d -s dbdump 'mysqldump -u root -p mydb | gzip > ~/mydb-$(date +%F).sql.gz; bash'
```

> The trailing `; bash` (or `read`) keeps the window open so you can see the
> result after it finishes.

### Docker logs and monitoring dashboard

```bash
tmux new -d -s monitor -n top 'htop'
tmux split-window -h -t monitor:top 'docker stats'
tmux split-window -v -t monitor:top 'docker compose -f /opt/app/docker-compose.yml logs -f'
tmux select-layout -t monitor:top tiled
tmux a -t monitor
```

---

## 9. One-Command Workspace Script

Save as `~/bin/laravel-tmux.sh` to create (or reattach to) the full Laravel
workspace in one go:

```bash
#!/usr/bin/env bash
set -euo pipefail

SESSION="laravel"
APP_DIR="/var/www/laravel"
WORKERS=2

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already running."
  [ -t 1 ] && exec tmux attach -t "$SESSION"
  exit 0
fi

tmux new -d -s "$SESSION" -n shell -c "$APP_DIR"

for i in $(seq 1 "$WORKERS"); do
  tmux new-window -t "$SESSION" -n "queue-$i" -c "$APP_DIR"
  tmux send-keys -t "$SESSION:queue-$i" \
    'while true; do php artisan queue:work --tries=3 --timeout=90 --max-time=3600; echo "restarting..."; sleep 3; done' Enter
done

tmux new-window -t "$SESSION" -n schedule -c "$APP_DIR"
tmux send-keys -t "$SESSION:schedule" 'php artisan schedule:work' Enter

tmux new-window -t "$SESSION" -n logs -c "$APP_DIR"
tmux send-keys -t "$SESSION:logs" 'tail -f storage/logs/laravel.log' Enter

tmux select-window -t "$SESSION:shell"
echo "Started session '$SESSION'."
[ -t 1 ] && exec tmux attach -t "$SESSION"
```

```bash
chmod +x ~/bin/laravel-tmux.sh
~/bin/laravel-tmux.sh
```

---

## 10. Start Sessions on Boot

Because tmux does not survive reboots, start the workspace from cron or
systemd.

### Option A — crontab `@reboot`

```bash
crontab -e
```

```text
@reboot /home/ubuntu/bin/laravel-tmux.sh >> /home/ubuntu/laravel-tmux.log 2>&1
```

### Option B — systemd unit

```bash
sudo tee /etc/systemd/system/laravel-tmux.service > /dev/null <<'EOF'
[Unit]
Description=Laravel tmux workspace
After=network.target mysql.service redis-server.service

[Service]
Type=forking
User=ubuntu
ExecStart=/home/ubuntu/bin/laravel-tmux.sh
ExecStop=/usr/bin/tmux kill-session -t laravel
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now laravel-tmux
```

---

## 11. tmux vs Supervisor vs systemd

| Need                                             | Use                    |
| ------------------------------------------------ | ---------------------- |
| Run something now, watch it, survive SSH drop    | **tmux**               |
| Interactive debugging of a worker / one-off task | **tmux**               |
| Queue workers that must always run in production | **Supervisor** or **systemd** |
| Auto-restart on crash, start on boot, log rotate | **Supervisor** or **systemd** |

tmux is ideal for staging, small servers, and hands-on work. For production
queue workers, the Laravel-recommended Supervisor config looks like this:

```ini
; /etc/supervisor/conf.d/laravel-worker.conf
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/laravel/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/laravel/storage/logs/worker.log
stopwaitsecs=3600
```

```bash
sudo apt install supervisor -y
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start "laravel-worker:*"
```

---

## 12. Troubleshooting

| Problem                                   | Fix                                                                 |
| ----------------------------------------- | ------------------------------------------------------------------- |
| `no server running on /tmp/tmux-1000/...` | No sessions exist for this user — start one with `tmux new -s name` |
| `sessions should be nested with care`     | You are already inside tmux. Detach first or use `C-b s` to switch  |
| Session missing after reboot              | Expected — use [Start Sessions on Boot](#_10-start-sessions-on-boot) |
| Can't see another user's session          | Run tmux as that user: `sudo -u www-data tmux ls`                   |
| Window closes instantly, error lost       | Use `send-keys` into a shell, or `set remain-on-exit on`            |
| Queue runs old code after deploy          | `php artisan queue:restart`                                         |
| Mouse scroll prints garbage               | Add `set -g mouse on` to `~/.tmux.conf`                             |
| Colours look wrong                        | `set -g default-terminal "screen-256color"`                         |

---

## Cheat Sheet

| Task                         | Command                                        |
| ---------------------------- | ---------------------------------------------- |
| New named session            | `tmux new -s name`                             |
| New detached session + cmd   | `tmux new -d -s name 'cmd'`                    |
| Attach or create             | `tmux new -A -s name`                          |
| List sessions                | `tmux ls`                                      |
| Attach                       | `tmux a -t name`                               |
| Detach                       | `C-b d`                                        |
| New window with command      | `tmux new-window -t name -n win 'cmd'`         |
| Send a command to a window   | `tmux send-keys -t name:win 'cmd' Enter`       |
| Stop a process (Ctrl+C)      | `tmux send-keys -t name:win C-c`               |
| Read output without attaching| `tmux capture-pane -p -t name:win`             |
| Kill session                 | `tmux kill-session -t name`                    |
| Laravel worker               | `tmux new -d -s queue 'php artisan queue:work'`|
| Laravel scheduler            | `tmux new -d -s schedule 'php artisan schedule:work'` |
| Restart workers after deploy | `php artisan queue:restart`                    |

---

## Done ✅

You can now run queue workers, schedulers, and other long-running processes in
named tmux sessions that survive SSH disconnects, inspect and restart them
without attaching, and bring the whole workspace back with one script.
