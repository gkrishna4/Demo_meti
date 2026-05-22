## Satellite server is down. how you will patch that server. The production team also need to patch that server immediately.
In real-time production environments, I perform Linux patching using a structured approach to avoid downtime and production impact.

First, I identify the servers that require patching and verify the maintenance window approved through the change management process.

Before patching, I perform pre-checks on the server such as:

* CPU and memory utilization
* disk space availability
* failed services
* application status
* backup and snapshot verification

Commands I use:

```bash
df -h
free -m
top
uptime
systemctl --failed
```

Then I verify whether the server is part of a load-balanced or clustered environment.

If it is an HA environment, I first remove one server from the load balancer to avoid user impact and confirm that traffic is shifted to other healthy nodes.

After isolating the server, I check available updates:

```bash
yum check-update
```

Then I apply patches:

```bash
yum update -y
```

For security patches only:

```bash
yum update --security -y
```

If kernel packages are updated, I reboot the server:

```bash
reboot
```

After reboot, I perform post-validation checks:

```bash
uname -r
uptime
systemctl status
journalctl -p err
```

I verify:

* new kernel version loaded successfully
* all services are running
* application is accessible
* no monitoring alerts are generated

Then I coordinate with the application team for application validation.

Once validation is successful, I add the server back to the load balancer and continue the same process for the remaining servers one by one.

In large environments, we automate this process using Ansible and AWX to patch multiple servers consistently.

If any issue occurs after patching, I follow rollback procedures such as:

* reverting VM snapshots,
* package rollback,
* or restoring backups.

Finally, I update the change ticket with implementation details, validation results, reboot information, and patch compliance status before closing the activity.”
