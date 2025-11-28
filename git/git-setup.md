# Git Setup Guide (README)

This guide explains how to set up Git on different operating systems,
generate SSH keys, configure SSH agents, and manage global and
repository-specific Git settings.

---

## \## 1. Install Git

### **Windows**

Download Git for Windows:\
https://git-scm.com/download/win

During installation, choose: - *Use Git from Command Prompt* - *OpenSSH*
(recommended) - *Checkout Windows-style, commit Unix-style*

For easy there is the git GUI for windows you can download it:\
https://central.github.com/deployments/desktop/desktop/latest/win32


### **Linux (Ubuntu/Debian)**

``` bash
sudo apt update
sudo apt install git
```

### **macOS**

``` bash
brew install git
```

---

## 2. Generate SSH Keys

Run:

``` bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Press **Enter** to accept default file path:\
`~/.ssh/id_ed25519`

When asked for a passphrase, enter one or press Enter to skip.

---

## 3. Add SSH Key to SSH Agent

### Start SSH agent

Linux/macOS:

``` bash
eval "$(ssh-agent -s)"
```

Windows (Git Bash):

``` bash
eval $(ssh-agent)
```

### Add key

``` bash
ssh-add ~/.ssh/id_ed25519
```

---

## 4. Add SSH Key to GitHub/GitLab/Bitbucket

Show the public key:

``` bash
cat ~/.ssh/id_ed25519.pub
```

Copy and paste into your Git provider's SSH settings.

---

## 5. Set Global Git Username & Email

``` bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

Check:

``` bash
git config --global --list
```

---

## 6. Set Repo-Specific Username & Email

Inside the repo folder:

``` bash
git config user.name "Other Name"
git config user.email "other_email@example.com"
```

Check:

``` bash
git config --list
```

---

## 7. Git Config File Example

### **Global Config File**

Location: - Linux/macOS: `~/.gitconfig` - Windows:
`C:\Users\USER\.gitconfig`

Example:

    [user]
        name = Your Name
        email = your_email@example.com

    [core]
        editor = nano

---

## 8. Using Multiple Git Accounts (Example: work & personal)

Create SSH keys:

``` bash
ssh-keygen -t ed25519 -C "personal@example.com" -f ~/.ssh/id_ed25519_personal
ssh-keygen -t ed25519 -C "work@example.com" -f ~/.ssh/id_ed25519_work
```

Add both:

``` bash
ssh-add ~/.ssh/id_ed25519_personal
ssh-add ~/.ssh/id_ed25519_work
```

### SSH Config (`~/.ssh/config`)

    # Personal GitHub
    Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519_personal

    # Work GitHub
    Host work.github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519_work

### Clone repo using work profile:

``` bash
git clone git@work.github.com:company/repo.git
```

---

## 9. Test SSH Connection

``` bash
ssh -T git@github.com
ssh -T git@work.github.com
```

---
