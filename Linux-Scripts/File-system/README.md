## how will you extend the `XFS file system`? And how will you reduce it?
To extend an `XFS file system`, the first step is to grow the underlying logical volume or partition using `lvextend` (if it is on LVM) or
by adding physical space, then run `xfs_growfs` on the mounted file system. XFS does not require unmounting — it can grow while active. 
For example, if I need to add 50 GB, I would run `lvextend -L +50G /dev/vg0/lv_data`, then immediately execute `xfs_growfs /mount_point`.
The file system expands within seconds, and the space becomes available to applications right away.

 XFS does not support online reduction. Unlike ext4, there is no native shrink command. The only way to reclaim space is to back up the
 data, destroy the file system, create a new smaller XFS, and restore the data. Some teams use LVM snapshots to make this safer, but the
 process is always offline. That is why planning capacity correctly at the outset matters more with XFS than with some other file systems.

 
