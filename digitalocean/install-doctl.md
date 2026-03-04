# DigitalOcean CLI (doctl)

DigitalOcean CLI tool (`doctl`) allows you to manage DigitalOcean resources directly from the command line.

## Installation on Ubuntu

### Method 1: Using Snap (Easiest)

Snap is the recommended method for most Ubuntu users as it provides automatic updates.

```bash
sudo snap install doctl
```

Verify the installation:
```bash
doctl version
```

### Method 2: Snap Package (Official Latest)

To install the latest version of `doctl` using Snap on Ubuntu (or other supported OS), run:

```bash
sudo snap install doctl
```

For security, Snap packages run in isolation. Some `doctl` commands require additional interfaces:

- For `doctl` integration with `kubectl` (kube config access):

```bash
sudo snap connect doctl:kube-config
```

- For `doctl compute ssh` (SSH key access):

```bash
sudo snap connect doctl:ssh-keys :ssh-keys
```

- For `doctl registries login` (Docker config access):

```bash
sudo snap connect doctl:dot-docker
```

Verify the installation:

```bash
doctl version
```

### Method 3: Using Binary (Manual Installation)

If you prefer manual control:

```bash
# Download the latest release
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.146.0/doctl-1.146.0-linux-amd64.tar.gz

# Extract the archive
tar xf ~/doctl-1.146.0-linux-amd64.tar.gz

# Move to system path
sudo mv doctl /usr/local/bin

# Verify installation
doctl version
```

---

## Authentication Setup

### Step 1: Generate API Token

1. Log in to [DigitalOcean Control Panel](https://cloud.digitalocean.com)
2. Go to **Settings** → **API** → **Tokens/Keys**
3. Click **Generate New Token**
4. Enter a token name (e.g., "doctl-token")
5. Select appropriate scopes (Full access recommended for beginners)
6. Click **Generate Token**
7. Copy the token immediately (it won't be shown again)

### Step 2: Configure doctl with Authentication

Run the authentication command:
```bash
doctl auth init
```

You will be prompted to:
1. Enter your API token (paste the token from Step 1)
2. Provide a context name (default: "default")

```
DigitalOcean access token: [paste your token here]
Use the following credentials in the default context? (Y/n): Y
```

### Step 3: Verify Authentication

Test your authentication:
```bash
doctl auth list
```

This will show your configured contexts.

### Step 4: Test API Access

```bash
doctl account get
```

This command should display your account information if authentication is successful.

---

## Configuration File

The authentication configuration is stored in:
```
~/.config/doctl/config.yaml
```

Sample configuration file:
```yaml
auth:
  access_token: dop_v1_xxxxxxxxxxxxxxxxxxxx
current-context: default
doit:
  disable_colors: false
  format: table
```

### Managing Multiple Contexts

You can have multiple DigitalOcean accounts configured:

```bash
# Set up another context
doctl auth init --context production

# List all contexts
doctl auth list

# Switch to a different context
doctl auth switch --context production

# Use specific context for a command
doctl -t production account get
```

---

## Common Examples

### Account Management

```bash
# View account details
doctl account get

# View billing history
doctl billing history
```

### Droplet (Virtual Machine) Management

```bash
# List all droplets
doctl compute droplet list

# Create a new droplet
doctl compute droplet create my-droplet \
  --region nyc3 \
  --image ubuntu-22-04-x64 \
  --size s-1vcpu-1gb

# Resize a droplet
doctl compute droplet resize my-droplet-id --size s-2vcpu-2gb

# Delete a droplet
doctl compute droplet delete my-droplet-id

# Reboot a droplet
doctl compute droplet-action reboot my-droplet-id

# Power off a droplet
doctl compute droplet-action power-off my-droplet-id

# Power on a droplet
doctl compute droplet-action power-on my-droplet-id

# Get droplet info
doctl compute droplet get my-droplet-id
```

### Networking

```bash
# List floating IPs
doctl compute floating-ip list

# Create a floating IP
doctl compute floating-ip create --region nyc3

# Assign floating IP to droplet
doctl compute floating-ip-action assign <floating-ip> <droplet-id>

# List domains
doctl compute domain list

# Create a domain
doctl compute domain create example.com --ip-address 192.168.1.1
```

### SSH Keys

```bash
# List SSH keys
doctl compute ssh-key list

# Add SSH key
doctl compute ssh-key create my-key --public-key-file ~/.ssh/id_rsa.pub

# Delete SSH key
doctl compute ssh-key delete <key-id>
```

### Database Management

```bash
# List databases
doctl databases list

# Create a database cluster
doctl databases create my-db \
  --engine pg \
  --region nyc3 \
  --num-nodes 3 \
  --size db-s-1vcpu-1gb

# Get database details
doctl databases get my-db-id
```

### Spaces (Object Storage)

```bash
# List spaces
doctl compute spaces list

# Create a space
doctl compute spaces create my-space --region nyc3
```

### Kubernetes Management

```bash
# List Kubernetes clusters
doctl kubernetes cluster list

# Create a cluster
doctl kubernetes cluster create my-cluster \
  --region nyc3 \
  --version 1.27.0 \
  --node-pool name=default-pool

# Get cluster kubeconfig
doctl kubernetes cluster kubeconfig save my-cluster-id

# Delete a cluster
doctl kubernetes cluster delete my-cluster-id
```

### App Platform

```bash
# List apps
doctl apps list

# Create an app
doctl apps create --spec app.yaml

# View app details
doctl apps get <app-id>
```

---

## Useful Aliases

Add these to your `.bashrc` or `.zshrc` for convenience:

```bash
# Edit ~/.bashrc or ~/.zshrc and add:
alias dcl='doctl compute droplet list'
alias dcc='doctl compute droplet create'
alias dic='doctl databases list'
alias dkl='doctl kubernetes cluster list'
alias dac='doctl account get'

# Usage:
# dcl
# dcc my-new-droplet --region nyc3 --image ubuntu-22-04-x64
```

---

## Useful Flags and Options

```bash
# Output format options (default: table)
doctl compute droplet list --format ID,Name,PublicIPv4
doctl compute droplet list --output json  # JSON format
doctl compute droplet list --no-header    # Remove header

# Filter and sort
doctl compute droplet list --sort name
doctl compute droplet list --sort created_at

# Limit results
doctl compute droplet list --limit 5

# Full resource details
doctl compute droplet get <droplet-id> --format ID,Name,PublicIPv4,Status,Memory,VCPUS,Disk
```

---

## Troubleshooting

### Authentication Issues

```bash
# Check if token is valid
doctl auth list

# Reset authentication
doctl auth init --context default

# Remove a context
doctl auth remove-context <context-name>
```

### Command Not Found

If you get "command not found" after installation:

```bash
# For snap installation
sudo snap install doctl

# Add snap to your PATH (if needed)
sudo ln -s /snap/bin/doctl /usr/local/bin/doctl

# Verify
doctl version
```

### API Errors

```bash
# Enable debug mode to see detailed error information
doctl --help

# Run with verbose flag
doctl compute droplet list --verbose
```

---

## Updating doctl

### Update via Snap
```bash
sudo snap refresh doctl
```

### Update Manual Binary
Simply download the latest release and replace the binary in `/usr/local/bin`.

---

## Resources

- [Official doctl GitHub](https://github.com/digitalocean/doctl)
- [DigitalOcean API Documentation](https://docs.digitalocean.com/reference/api/)
- [doctl Commands Reference](https://docs.digitalocean.com/reference/doctl/)
