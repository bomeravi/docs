# Ansible Quick Start Guide

## ✅ Overview
Ansible is an agentless automation tool for provisioning, configuration management, and application deployment. This guide covers setup, usage, and examples for Windows, Ubuntu, and macOS.

## ⚙️ Setup

### 1) Install Python (required)
Ansible runs on Python. Install Python 3.11+ on your controller machine (the one you run Ansible from).

### 2) Create a virtual environment (recommended)
```bash
python3 -m venv ~/.ansible-venv
source ~/.ansible-venv/bin/activate
```

### 3) Install Ansible
```bash
python -m pip install --upgrade pip
python -m pip install ansible
```

## 💻 Platform-specific instructions

### Ubuntu (WSL2 or native Linux)
```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip
python3 -m venv ~/.ansible-venv
source ~/.ansible-venv/bin/activate
python -m pip install --upgrade pip
python -m pip install ansible
```

### macOS
```bash
brew update
brew install python
python3 -m venv ~/.ansible-venv
source ~/.ansible-venv/bin/activate
python -m pip install --upgrade pip
python -m pip install ansible
```

### Windows (PowerShell + Windows Subsystem for Linux recommended)
Use WSL2 with Ubuntu for best compatibility.
1. Install WSL2 and Ubuntu from Microsoft Store.
2. Open Ubuntu shell and follow the Ubuntu steps above.

If using native Windows PowerShell (less common):
```powershell
python -m venv C:\Users\<you>\ansible-venv
C:\Users\<you>\ansible-venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install ansible
```

## 🧪 Quick usage

### 1) Check Ansible version
```bash
ansible --version
```

### 2) Inventory file
Create `inventory.ini`:
```ini
[local]
127.0.0.1 ansible_connection=local
```

### 3) Basic ad-hoc command
```bash
ansible -i inventory.ini local -m ping
```

## 🧩 Example Playbook
Create `playbook.yml`:
```yaml
- name: Example Ansible playbook
  hosts: local
  gather_facts: false
  tasks:
    - name: Ensure hello.txt exists
      copy:
        dest: /tmp/hello.txt
        content: "Hello from Ansible!\n"
    - name: Show hello.txt contents
      command: cat /tmp/hello.txt
      register: catout
    - debug:
        msg: "File output: {{ catout.stdout }}"
```

Run it:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

## 📦 Example: Install Nginx (Ubuntu)
Create `nginx-playbook.yml`:
```yaml
- name: Install Nginx on target hosts
  hosts: local
  become: true
  tasks:
    - name: Update apt cache
      apt:
        update_cache: true
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Ensure nginx service is running
      service:
        name: nginx
        state: started
        enabled: true
```

Run:
```bash
ansible-playbook -i inventory.ini nginx-playbook.yml
```

## 📌 Tips
- Keep your inventory in `inventory.ini` or `hosts.yml`.
- Use `ansible-lint` for playbook quality checks (`pip install ansible-lint`).
- For Windows targets, set `ansible_connection=winrm` and configure WinRM.

## 🔗 Resources
- Official docs: https://docs.ansible.com/
- Ansible examples: https://github.com/ansible/ansible-examples
