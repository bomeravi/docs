# Fix Missing sudo Access

For DigitalOcean Droplet


## Problem

After creating a droplet and disabling root login, sudo access was not
granted:

``` bash
ubuntu is not in the sudoers file
```

------------------------------------------------------------------------

## Root Cause

The `ubuntu` user is not part of the `sudo` group.

------------------------------------------------------------------------

## Recovery Steps (Recovery Mode)

### 1. Boot into Recovery Mode

-   Power off droplet
-   Enable Recovery ISO
-   Open console
-   Mount filesystem (drive)
-   Use Interactive bash

------------------------------------------------------------------------

### 2. Identify Disk

``` bash
lsblk
```

Typical output:

``` bash
vda
└─vda1
```

------------------------------------------------------------------------

### 3. Mount Filesystem

``` bash
mkdir -p /mnt
mount /dev/vda1 /mnt
```

------------------------------------------------------------------------

### 4. Fix .ssh Permission (if needed)

If `.ssh` shows missing execute (`x`) permission:

``` bash
chmod 700 /mnt/home/ubuntu/.ssh
```

------------------------------------------------------------------------

### 5. Bind System Directories

``` bash
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
```

------------------------------------------------------------------------

### 6. Chroot into System

``` bash
chroot /mnt
```

------------------------------------------------------------------------

### 7. Add sudo Access

``` bash
usermod -aG sudo ubuntu
```

Verify:

``` bash
groups ubuntu
```

Expected:

``` bash
ubuntu : ubuntu sudo
```

------------------------------------------------------------------------

### 8. Fallback (Force sudo)

If group method fails:

``` bash
echo "ubuntu ALL=(ALL:ALL) ALL" >> /etc/sudoers
```

------------------------------------------------------------------------

### 9. Exit and Reboot

``` bash
exit
reboot
```

Then switch droplet back to **Normal Boot**.

------------------------------------------------------------------------

### 10. Test

``` bash
sudo whoami
```

Expected output:

``` bash
root
```

------------------------------------------------------------------------

## Notes

-   `.ssh` must have `700` permission (`drwx------`)
-   Directory needs execute (`x`) to allow `cd`
-   Always ensure at least one sudo user before disabling root login

------------------------------------------------------------------------

## Troubleshooting

Run from recovery environment:

``` bash
cat /mnt/etc/passwd | grep ubuntu
cat /mnt/etc/group | grep sudo
```

------------------------------------------------------------------------

## Common Mistakes

-   Not running `chroot`
-   Mounting wrong partition (`vda` instead of `vda1`)
-   Forgetting bind mounts (`/dev`, `/proc`, `/sys`)
-   Not switching back to normal boot
