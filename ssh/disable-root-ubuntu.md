# Disable Root Login on Ubuntu (SSH Hardening Guide)

This guide explains how to securely disable root login on an Ubuntu
server after system upgrades.

------------------------------------------------------------------------

## 1. Edit SSH Server Configuration

Open the SSH server configuration file:

``` bash
sudo nano /etc/ssh/sshd_config
```

⚠️ Make sure you are editing:

    /etc/ssh/sshd_config

NOT:

    /etc/ssh/ssh_config

------------------------------------------------------------------------

## 2. Disable Root Login

If the line does not exist, add it manually:

    PermitRootLogin no

This completely disables SSH login for the root user.

------------------------------------------------------------------------

## 3. Disable Password Authentication (Recommended)

If you are using SSH keys, also ensure:

    PasswordAuthentication no

------------------------------------------------------------------------

## 4. Validate SSH Configuration

Before restarting SSH, test the configuration:

``` bash
sudo sshd -t
```

If there is no output, the configuration is valid.

------------------------------------------------------------------------

## 5. Restart SSH Service

``` bash
sudo systemctl restart ssh
```

or

``` bash
sudo systemctl restart sshd
```

------------------------------------------------------------------------

## 6. Verify Active Configuration

Check the active SSH setting:

``` bash
sudo sshd -T | grep permitrootlogin
```

Expected output:

    permitrootlogin no

------------------------------------------------------------------------

## 7. Important Safety Note

Before disabling root login: - Ensure you have a non-root sudo user. -
Confirm SSH key login works. - Test login in a new terminal before
closing your current session.

------------------------------------------------------------------------

## Production-Ready SSH Hardening Recommendations

-   Disable root login
-   Disable password authentication
-   Use SSH key authentication only
-   Change default SSH port (optional)
-   Enable UFW firewall
-   Install fail2ban

------------------------------------------------------------------------

## Basic Firewall Setup (Optional)

``` bash
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status
```

------------------------------------------------------------------------

## Summary

By setting:

    PermitRootLogin no
    PasswordAuthentication no

Your server becomes significantly more secure against brute-force and
unauthorized root access attempts.

------------------------------------------------------------------------
