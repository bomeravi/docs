---
pagination_label: Troubleshooting
---

# Troubleshooting

Diagnosis and recovery guides for systems that are already broken — boot
failures, restores gone wrong, and other "it worked yesterday" situations. Each
page walks through the symptoms, the investigation, the root cause, and the
fix.

---

## Guides in this folder

- [GRUB and EFI Boot Repair](./grub-efi-boot-repair.md): recover a machine that
  drops to the `grub>` prompt or into emergency mode after an image restore,
  caused by a stale EFI partition UUID in `/etc/fstab`.
