## What happens when the server load is very high, but CPU utilization remains low? How do you identify and troubleshoot that situation?

if the server load average is high but CPU utilization is low, I understand that the issue is usually not CPU-related. In Linux, load average includes not only CPU usage but also processes waiting for resources like disk I/O, storage, network, or filesystem operations.

My first step is to verify the server load and CPU utilization using commands like:

```bash id="t7k2xp"
top
uptime
vmstat 5
```

If CPU idle is high and load average is still increasing, I check the I/O wait value because high I/O wait generally indicates storage or disk bottlenecks.

Then I analyze disk performance using:

```bash id="v4m9qd"
iostat -xz 5
iotop
```

I verify:

* disk latency,
* high await times,
* queue utilization,
* and heavy read/write operations.

I also check whether any processes are stuck in D state:

```bash id="p6w1rz"
ps -eo state,pid,cmd | grep "^D"
```

This usually indicates processes waiting for disk or storage operations.

In production environments, I also verify:

* NFS mount delays,
* backup jobs,
* database locks,
* filesystem issues,
* or storage latency problems.

Additionally, I check logs using:

```bash id="m8x3cn"
journalctl -xe
dmesg
```

Based on the findings, I take corrective actions such as:

* stopping heavy I/O processes,
* coordinating with storage teams,
* optimizing application performance,
* increasing resources,
* or resolving storage/network issues.

In my experience, high load with low CPU usage is commonly related to disk I/O wait or blocked processes rather than actual CPU bottlenecks.

## How do you identify bottlenecks?
“I identify bottlenecks by checking CPU, memory, disk I/O, network, and application performance using Linux monitoring tools.

I usually start with:

```bash id="t6p1wy"
top
vmstat
iostat
free -m
sar
```

These commands help identify whether the issue is related to high CPU usage, memory exhaustion, disk latency, or network congestion.

I also analyze logs and monitoring dashboards using tools like Grafana and Nagios.

Once the bottleneck is identified, I perform tuning or coordinate with the respective teams to resolve the issue.”


## How do you troubleshoot to SELinux issues?
my first step is to identify whether SELinux is actually blocking the application or service.

First, I check the SELinux status:

```bash id="r5n8wx"
getenforce
sestatus
```

If SELinux is in Enforcing mode and the application is failing, I verify SELinux denial logs.

On RHEL/CentOS systems, SELinux denials are usually logged in:

```bash id="m4k2zp"
/var/log/audit/audit.log
```

I use commands like:

```bash id="q9v7ct"
ausearch -m AVC
```

or

```bash id="p1x6ld"
grep denied /var/log/audit/audit.log
```

This helps identify which policy is blocking the process.

Then I analyze the issue using:

```bash id="k7t3yn"
sealert -a /var/log/audit/audit.log
```

The `sealert` command gives detailed explanations and recommended fixes.

Common SELinux issues I troubleshoot include:

* incorrect file contexts,
* web server permission denials,
* custom application access blocks,
* non-standard ports,
* and NFS/shared mount access issues.

If the issue is related to incorrect file context, I verify contexts:

```bash id="v6c1jq"
ls -Z
```

Then I restore the correct context:

```bash id="w3f9rm"
restorecon -Rv /path
```

If the application uses a custom port, I allow it using:

```bash id="d2n8ky"
semanage port -a -t http_port_t -p tcp 8080
```

Sometimes booleans need to be enabled:

```bash id="x5p4sv"
getsebool -a
setsebool -P httpd_can_network_connect on
```

For temporary troubleshooting only, I may switch SELinux to permissive mode to confirm whether SELinux is causing the issue:

```bash id="u7m1zc"
setenforce 0
```

If the application works in permissive mode, it confirms an SELinux policy issue. After troubleshooting, I immediately re-enable enforcing mode:

```bash id="h8q2lt"
setenforce 1
```

In production environments, I avoid disabling SELinux permanently. Instead, I implement proper policies, file contexts, booleans, or port labeling to 
maintain system security while resolving the issue.

