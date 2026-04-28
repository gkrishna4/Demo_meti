## /boot partition is completely wiped out or corrupted in RHEL
If the /boot partition is corrupted or wiped in Red Hat Enterprise Linux, attach the installation ISO to the VM and boot
into `Troubleshooting → Rescue Mode`, then `select option 1 (Continue)` so the system mounts your Linux installation 
under `/mnt/sysimage`. Once mounted, enter the environment using `chroot /mnt/sysimage` and verify disk and partition status with `lsblk` 
and `df -h`. If the `/boot` directory is empty or damaged, mount the ISO using `mount /dev/sr0 /mnt` and navigate to `/mnt/Packages` 
to reinstall required packages. Reinstall the kernel only if it is missing using a command like
`rpm -ivh kernel-<version>.el7.x86_64.rpm --force`,
then reinstall GRUB packages such as `grub2 and grub2-tools`. After that, install the bootloader correctly on the disk (not partition) 
using `grub2-install /dev/sda`, and regenerate the GRUB configuration file with `grub2-mkconfig -o /boot/grub2/grub.cfg`. Optionally 
reinstall redhat-logos if needed, then exit the `chroot environment` and `reboot` the system. Before rebooting, ensure `/boot` contains 
kernel and GRUB files so the system can boot properly.

## initramfs file missing or corrupted in CentOS  / RHEL 
If the `initramfs` file is missing or corrupted in Red Hat Enterprise Linux, the system may fail to boot and show a `kernel panic error`. 
To fix this, reset the VM and boot into Rescue Mode from the ISO, then log in as root. Navigate to the `/boot` directory and verify
the kernel version using `uname -r`. If the initramfs file is missing, recreate it using any equivalent `dracut` command such as 
`dracut initramfs-$(uname -r).img $(uname -r)`. If the file is corrupted, `force` regeneration using `dracut -f initramfs-$(uname -r).img
$(uname -r)`. These commands rebuild the initramfs image required for booting. After execution, confirm the file is created in `/boot `
using ls -l. Once verified, reboot the system using `init 6` or `reboot`, then select normal boot mode. The system should now 
start successfully without kernel panic errors.

## grub.cfg file missing or corrupted in CentOS  / RHEL 
If the `grub.cfg` file is missing or corrupted in Red Hat Enterprise Linux, the system may fail to boot because GRUB has no 
configuration to load the kernel. To fix this, attach the OS ISO to your VM and restart it, then choose `Troubleshooting → Rescue` Mode
and `select 1 (Continue)` so your system is mounted under `/mnt/sysimage`. Enter your system environment using `chroot /mnt/sysimage`,
then check disks using `lsblk` to confirm the correct boot disk (usually /dev/sda). Reinstall the bootloader using
`grub2-install /dev/sda` to ensure GRUB is properly placed on the disk. Next, go to the GRUB directory using `cd /boot/grub2` 
and run `ls` to confirm that `grub.cfg` is missing. To recreate it, run `grub2-mkconfig -o /boot/grub2/grub.cfg`, which scans 
the system and generates a new configuration file. Verify again with `ls` that `grub.cfg` is now present. Finally, exit from the
chroot environment, remove the ISO from the VM, and reboot the system. The system should now boot normally without errors.

## MBR corrupted in CentOS 7 / RHEL 7
If the `MBR (Master Boot Record)` is corrupted in Red Hat Enterprise Linux, the system may fail to start and display the error
“FATAL: no bootable medium found! system halted.” To resolve this, attach the installation ISO to the VM and reboot into
`Troubleshooting → Rescue ` Mode, then select `option 1 (Continue)` so the system mounts your installed OS under `/mnt/sysimage`.
Once inside the rescue environment, verify mounts using `df -h` and switch into the installed system using `chroot /mnt/sysimage`.
After confirming the environment, reinstall the bootloader to the primary disk (not a partition) using `grub2-install /dev/sda`,
which restores the MBR and boot code. Then exit the chroot environment, remove the ISO from the VM, and reboot the system.
After restart, the system should boot normally without the error.


## Critical files missing from the system CentOS  / RHEL, for example /bin/mount missing
If `Critical files/important system files` like `/bin/mount` are missing in Red Hat Enterprise Linux, the system may not boot properly
or basic commands may fail. To fix this, first attach the OS DVD/ISO to your VM and restart it. From the boot menu, choose
`Troubleshooting → Rescue Mode`, then `select 1 (Continue)` so the system automatically mounts your installed OS under 
the directory `/mnt/sysimage`. You can check this using `df -h`. To work inside your actual system, run `chroot /mnt/sysimage`,
which makes `/mnt/sysimage` behave like the `root (/)` of your system. If needed, exit back to the rescue shell and create a 
directory like `/mnt/source`, then mount the ISO using `mount /dev/sr0 /mnt/source`. This ISO contains all required packages 
inside `/mnt/source/Packages`. Go into that folder and locate the correct package (for /bin/mount, it belongs to util-linux). 
Install it using `rpm -ivh util-linux-<version>.x86_64.rpm --root /mnt/sysimage --force`, which installs the missing files directly 
into your system mounted at `/mnt/sysimage`. After installation, enter again using `chroot /mnt/sysimage` and confirm the file is
restored with `ls -l /bin/mount`. Once verified, exit from `chroot`, unmount the ISO using `umount /mnt/source`, remove the ISO from
the VM, and reboot the system. The system should now boot normally with all required files restored.

## /etc/fstab file corruption in CentOS  / RHEL
If the `/etc/fstab` file is corrupted in Red Hat Enterprise Linux, the system may fail to boot properly and drop you into emergency
mode asking for the root password. After entering the root password, you will get a shell prompt. First, check the current contents 
of the file using `cat /etc/fstab` to identify incorrect or missing entries (such as wrong UUIDs, mount points, or filesystem types).
Then open the file in an editor using `vi /etc/fstab` and carefully correct the entries—ensure that each line has the correct device
(preferably UUID), mount point (like /, /boot, /home), filesystem type (e.g., `xfs, ext4`), and proper options. After saving the 
changes, verify again using `cat /etc/fstab`. Once everything looks correct, reboot the system using init 6 or reboot. If the entries
are fixed properly, the system will boot normally without errors.

## If a server shows a kernel panic error after reboot in Red Hat Enterprise Linux / CentOS
🔍 1. Observe the error message
    
    Carefully read what is shown on screen
    
      Common clues:
           1) VFS: unable to mount root filesystem
           2) initramfs missing
           3) not syncing
This tells you where the failure is happening

🔹 2. Try booting with previous kernel

      1) Restart system 
      2)At GRUB menu:-> Select older kernel 
      3)If system boots → problem is with new kernel 
      👉 Then fix permanently using:
```
grub2-set-default 1
grub2-mkconfig -o /boot/grub2/grub.cfg
```

🔹 3. Boot into Rescue Mode (if system won’t boot)

     1) Attach ISO
     2) Go to:  Troubleshooting → Rescue Mode → 1 (Continue)
     3) Enter system: 
```
chroot /mnt/sysimage
```
🔍 4. Check common causes

✅ (A) initramfs issue
```
ls /boot
```
If missing/corrupt:
```
dracut -f /boot/initramfs-$(uname -r).img $(uname -r)
```
✅ (B) /boot or GRUB issue
```
ls /boot/grub2
```
If missing:
```
grub2-install /dev/sda
grub2-mkconfig -o /boot/grub2/grub.cfg
```
✅ (C) /etc/fstab issue
```
cat /etc/fstab
```
Check wrong UUIDs or mount points
Fix using `vi /etc/fstab`

✅ (D) Missing kernel
```
rpm -qa | grep kernel
```
If missing → reinstall from ISO

✅ (E) Disk / filesystem issue
```
lsblk
fsck /dev/sdaX
```
🔍 5. Check logs (if accessible)
```
journalctl -xb
dmesg
```
🔹 6. Exit and reboot
```
exit
reboot
```
