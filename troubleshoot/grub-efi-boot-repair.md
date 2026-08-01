# GRUB and EFI Boot Repair After a Restore

A case study in diagnosing and fixing a system that drops to the `grub>` prompt
or into emergency mode after restoring an Ubuntu image onto a disk that
previously held another OS. The root cause is almost always a stale EFI
partition UUID in `/etc/fstab`.

> ⚠️ The UUIDs, device paths, and partition layout below are from one specific
> machine. Read your own values with `sudo blkid` and `lsblk` — never copy these
> verbatim.

---

## Scenario

| | |
| --------------- | ------------------------------------------ |
| Original OS     | Ubuntu 24.04                               |
| Temporary OS    | Ubuntu 26, installed on the same disk       |
| Backup tool     | Rescuezilla                                |
| Restore target  | The same NVMe SSD                          |

Rescuezilla reported a successful restore, but afterwards the system dropped to
the `grub>` prompt, intermittently entered emergency mode, and `grub-install`
failed with:

```text
grub-install: error: cannot find EFI directory.
```

---

## Symptoms

### 1. GRUB prompt

The system stopped at:

```text
grub>
```

Ubuntu could still be booted manually from that prompt:

```text
set root=(hd0,gpt5)
set prefix=(hd0,gpt5)/boot/grub
insmod normal
normal
```

### 2. Emergency mode

Some boots landed in:

```text
You are in emergency mode.
```

Booting eventually continued, which made the fault look intermittent.

### 3. `grub-install` failure

```bash
sudo grub-install /dev/nvme0n1
```

Output:

```text
Installing for x86_64-efi platform.
grub-install: error: cannot find EFI directory.
```

---

## Investigation

### 1. Confirm the boot mode

```bash
test -d /sys/firmware/efi && echo "UEFI" || echo "Legacy BIOS"
```

Output:

```text
UEFI
```

The system is UEFI, so a mounted EFI System Partition (ESP) is required.

### 2. Check the partition table

```bash
sudo fdisk -l /dev/nvme0n1
```

Result on this machine:

| Partition | Size   | Type                 |
| --------- | ------ | -------------------- |
| p1        | 100 MB | EFI System           |
| p2        | 16 MB  | Microsoft Reserved   |
| p3        | 552 GB | Microsoft Basic Data |
| p4        | 716 MB | Windows Recovery     |
| p5        | 401 GB | Ubuntu Root          |

The ESP exists — so the problem is not a missing partition.

### 3. Check what is actually mounted

```bash
lsblk
```

Result:

```text
nvme0n1p5 mounted on /
nvme0n1p1 NOT mounted
```

```bash
findmnt /boot/efi
```

No output — confirming `/boot/efi` is not mounted.

### 4. Read the real EFI UUID

```bash
sudo blkid
```

Output:

```text
/dev/nvme0n1p1
UUID="7C5A-386A"
TYPE="vfat"
```

### 5. Compare against `/etc/fstab`

```bash
cat /etc/fstab
```

It contained:

```text
/dev/disk/by-uuid/F675-B7F7 /boot/efi vfat defaults 0 1
```

| | UUID |
| ------------------- | ----------- |
| Referenced in fstab | `F675-B7F7` |
| Actually on disk    | `7C5A-386A` |

The temporary Ubuntu install reformatted the EFI partition, giving it a new
UUID. The restored `/etc/fstab` still pointed at the old one.

---

## Root Cause

Ubuntu tried to mount `UUID=F675-B7F7`, which no longer existed. With the ESP
unmounted, everything downstream failed:

- GRUB could not write its configuration.
- `grub-install` could not find the EFI directory.
- Boot dropped to the `grub>` prompt.
- The failed mount unit pushed the system into emergency mode.

---

## Fix

> ⚠️ A malformed `/etc/fstab` can make the system unbootable. Always run
> `sudo mount -a` and confirm it exits cleanly **before** rebooting.

### 1. Correct the fstab entry

```bash
sudo nano /etc/fstab
```

Replace the stale line:

```text
/dev/disk/by-uuid/F675-B7F7 /boot/efi vfat defaults 0 1
```

with the UUID reported by `blkid`:

```text
UUID=7C5A-386A /boot/efi vfat umask=0077 0 1
```

> `umask=0077` restricts the ESP to root, which is what the Ubuntu installer
> writes by default. Adding `nofail` to the options makes a future ESP problem
> degrade into a normal boot instead of emergency mode.

### 2. Test the fstab before rebooting

```bash
sudo mount -a
```

No output means every entry mounted successfully.

### 3. Verify the EFI mount

```bash
findmnt /boot/efi
```

Expected:

```text
TARGET     SOURCE
/boot/efi  /dev/nvme0n1p1
```

### 4. Reinstall GRUB

```bash
sudo grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot/efi \
  --bootloader-id=ubuntu

sudo update-grub
```

Expected:

```text
Installation finished. No error reported.
```

### 5. Reboot

```bash
sudo reboot
```

The system should now boot straight to Ubuntu — no GRUB prompt, no emergency
mode, no EFI errors.

---

## Diagnostic Command Reference

| Command | Shows |
| ------- | ----- |
| `test -d /sys/firmware/efi && echo UEFI \|\| echo BIOS` | Whether the machine booted in UEFI or legacy BIOS mode |
| `lsblk` | Block devices, partitions, and current mount points |
| `sudo blkid` | Partition UUIDs and filesystem types |
| `findmnt` | Every mounted filesystem |
| `findmnt /boot/efi` | Whether the EFI partition is mounted |
| `sudo efibootmgr -v` | UEFI boot entries and their boot order |
| `sudo fdisk -l /dev/nvme0n1` | Full partition table for the disk |
| `systemctl --failed` | Units that failed during boot |
| `journalctl -b -p err` | Errors logged during the current boot |

---

## Summary

| Step | Command |
| ---- | ------- |
| Find the real ESP UUID | `sudo blkid` |
| Fix the stale entry | `sudo nano /etc/fstab` |
| Test before rebooting | `sudo mount -a` |
| Confirm the mount | `findmnt /boot/efi` |
| Reinstall the bootloader | `sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu` |
| Regenerate the config | `sudo update-grub` |

---

## Lessons Learned

When restoring Ubuntu onto a disk that previously hosted another OS:

1. Verify the EFI System Partition UUID with `blkid` before trusting `fstab`.
2. Confirm `/boot/efi` is actually mounted — `grub-install` fails silently on
   this if it is not.
3. Check `/etc/fstab` for stale UUIDs; a restored image carries the old ones.
4. Reinstall GRUB after any restore where the EFI partition changed.
5. Always test with `sudo mount -a` before rebooting.

An unmounted EFI partition is what produces both the GRUB prompt loop and the
intermittent emergency mode — fixing the mount fixes both.

---

## Done ✅

The system boots directly into Ubuntu, `/boot/efi` mounts from `/etc/fstab` on
every boot, and `grub-install` completes without error.
