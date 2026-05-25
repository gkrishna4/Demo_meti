## how will you extend the `XFS file system`? And how will you reduce it?
To extend an `XFS file system`, the first step is to grow the underlying logical volume or partition using `lvextend` (if it is on LVM) or
by adding physical space, then run `xfs_growfs` on the mounted file system. XFS does not require unmounting — it can grow while active. 
For example, if I need to add 50 GB, I would run `lvextend -L +50G /dev/vg0/lv_data`, then immediately execute `xfs_growfs /mount_point`.
The file system expands within seconds, and the space becomes available to applications right away.

 XFS does not support online reduction. Unlike ext4, there is no native shrink command. The only way to reclaim space is to back up the
 data, destroy the file system, create a new smaller XFS, and restore the data. Some teams use LVM snapshots to make this safer, but the
 process is always offline. That is why planning capacity correctly at the outset matters more with XFS than with some other file systems.

## Suppose storage team given on LUN to you, so you need extra amount of storage? So how will you extend it in the actual VM environment?
When the storage team provides additional space by extending the LUN, the first thing I do is verify whether the Linux server detects
the increased disk size.  I perform a `SCSI rescan` by using the command `rescan-scsi-bus.sh` or 
`echo "- - -" > /sys/class/scsi_host/hostX/scan` without rebooting the server and then validate the new size using commands like
`lsblk` or `fdisk -l`. After confirming that the OS recognizes the additional storage, I check whether the server is using LVM, 
I usually extend the Physical Volume using `pvresize`, then extend the Logical Volume with `lvextend`, and finally grow the filesystem
using `xfs_growfs` for XFS filesystems or `resize2fs` for EXT4. Once the extension is completed, I verify the updated storage using 
commands such as `df -h`, `lvs`, and `vgs`. Before making any changes, I always confirm the filesystem type.

Example:

Extend the Physical Volume
`pvresize /dev/sdX1`

Extend the Logical Volume
`lvextend -L +100G /dev/vg_data/lv_app`

Extend the Filesystem for XFS:
`xfs_growfs /mountpoint`

Extend the Filesystem For EXT4:
`resize2fs /dev/vg_data/lv_app`

## you see that temp is full, then what will you do? What is the command you are executing there?

I check the filesystem usage to identify what is consuming the space, using: `df -h /tmp`

Then I move inside the /tmp directory and identify large files or directories using: `du -sh /tmp/*`

After identifying unnecessary or old temporary files, I verify whether they are actively being used by any application or process.
I check open files using: `lsof /tmp`

If the files are no longer required, I remove them safely using: `rm -rf <file_or_directory>`

If cleanup is not sufficient and the filesystem still requires additional space, then depending on the environment, I either extend 
the filesystem using LVM or coordinate with the storage/VM team for additional storage allocation. Finally, I verify the free space
again using df -h and ensure applications are functioning normally.


## Suppose one file system got full, what will you do next?

If a filesystem becomes full, I verify the filesystem usage using: `df -h`

After identifying which mount point is full, I check what is consuming the space by using: `du -sh /*`
or, if it is a specific filesystem:` du -sh /path/* | sort -hr` This helps identify large files or directories. Then I check
whether unnecessary logs, temporary files, old backups, or application dump files are occupying the space. I also verify deleted 
but still open files using: `lsof | grep deleted`

If cleanup is possible, I remove unnecessary files safely after confirming they are not actively used by applications. If the filesystem
still requires more space, I check whether it is configured with LVM. In most production environments, I extend the filesystem online by
extending the LUN from the storage side, rescanning the disk, extending the Physical Volume, Logical Volume, and finally the filesystem
using `xfs_growfs` or `resize2fs` depending on the filesystem type.then I validate using `df -h`, `lvs`, and ensure applications are 
functioning normally with minimal or no downtime.
