# Basic Packages Setup

Install the baseline packages a fresh Ubuntu/Debian server needs before adding
third-party APT repositories (Docker, Jenkins, etc.) or pulling files over
HTTPS. Run this first on a new host.

---

## 1. Install

```bash
sudo apt update
sudo apt install -y \
  ca-certificates \
  curl \
  wget \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common
```

---

## 2. What each package does

| Package | What it does |
| ------- | ------------ |
| `ca-certificates` | Trusted root CA certificates, so TLS/HTTPS connections (to APT mirrors, `curl`, `wget`) can be verified. |
| `curl` | Command-line tool to transfer data to/from URLs — download files and call APIs. See [Basic Linux Commands](/linux-commands.md#http-requests-with-curl). |
| `wget` | Non-interactive downloader for fetching files over HTTP(S)/FTP. |
| `gnupg` | GNU Privacy Guard — verifies and imports the GPG signing keys that authenticate third-party APT repositories. |
| `lsb-release` | Provides the `lsb_release` command that reports the distro codename/version; repo setup scripts use it to pick the right package list. |
| `apt-transport-https` | Lets APT fetch packages over HTTPS. Built into modern `apt`, but installed for compatibility with older setups. |
| `software-properties-common` | Provides `add-apt-repository` for adding and managing PPAs and external repositories. |

---

## 3. Verify

```bash
curl --version
gpg --version
lsb_release -a
```

Each command should print a version (or your distro details), confirming the
tools are installed and on `PATH`.