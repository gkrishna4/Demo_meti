## bottleneck means
bottleneck is the component (CPU, memory, disk, network,database,application,gpu,etc.) that is causing the system to perform 
slowly because it has reached its limit.

## suppose customer faces one issue in performance of one of the Linux server. So how do troubleshoot that?

When a customer reports performance issues on a Linux server, I start by checking the `system load` and `resource utilization` to 
find the `bottleneck`. 
I run `uptime` first to see the `load average` over the last `1, 5, and 15 minutes` — that tells me if the server is
CPU-bound right now or if it was stressed earlier. 
Then I check `top` or `htop` to see which processes are consuming the most `CPU and memory`. From there, I check `free -h` 
to see available memory, `iostat` or `iotop` to identify disk I/O issues, and `netstat` or `ss` to look for network bottlenecks
or connection issues.

From the `uptime` command specifically, I look at whether the `load average` is higher than the `number of CPU cores` — that tells me 
the server is under real stress. If load is high but CPU usage is low, it usually points to I/O wait or a process stuck in disk
operations. I also check the timestamp to see when the issue started, then cross-reference with logs in /var/log — syslog, application 
logs — to narrow down what happened around that time.

## cpu bound issue and memory bound issue?
CPU-bound means performance is limited by CPU processing power. I typically see high CPU utilization and load average, and I check it using `top` or `sar -u`.

Memory-bound means the bottleneck is RAM availability, where the server starts using swap or experiences memory pressure. I validate it using `free -h`, `vmstat`
and `sar -r`. In both cases, I identify the resource bottleneck first before taking action

## What happens when the server load is very high, but CPU utilization remains low? How do you identify and troubleshoot that situation?

if the server load average is high but CPU utilization is low, I understand that the issue is usually not CPU-related. In Linux, load average includes not only CPU usage but also processes waiting for resources like disk I/O, storage, network, or filesystem operations.

My first step is to verify the server load and CPU utilization using commands like:

```bash id="t7k2xp"
top
uptime
vmstat 5
```
Note:

  `vmstat` → Reports virtual memory, CPU, processes, I/O, and system activity.
  
  `5` → Refresh interval in seconds.
  
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

## A Linux server is responding very slowly, but CPU and memory utilization appear normal. What could be the possible causes, and how would you troubleshoot the issue?
if a Linux server becomes very slow while CPU and memory utilization are normal, I understand that the issue is likely related to resources other than CPU or RAM.

In real-world production environments, slow server response with normal CPU and memory is commonly caused by:

* high disk I/O wait,
* storage latency,
* network issues,
* NFS mount delays,
* filesystem problems,
* DNS resolution delays,
* application hangs,
* database locks,
* or blocked processes.

My troubleshooting approach is systematic.

First, I verify the overall server load and I/O wait:

```bash
top
uptime
vmstat 5
```

Even if CPU usage is low, a high load average or high `wa` (I/O wait) indicates storage or disk-related bottlenecks.

Then I analyze disk performance:

```bash
iostat -xz 5
iotop
df -h
```

I check for:

* high await times,
* disk queue delays,
* storage latency,
* and filesystem usage.

In production environments, storage issues are one of the most common reasons for slow server performance.

Next, I verify whether any processes are stuck in D state:

```bash
ps -eo state,pid,cmd | grep "^D"
```

Processes in D state usually indicate they are waiting for disk or storage operations.

I also check:

* NFS mount availability,
* SAN/storage connectivity,
* backup jobs,
* or hung application processes.

For network-related delays:

```bash
sar -n DEV
iftop
netstat -i
```

Sometimes DNS delays can also slow applications:

```bash
nslookup
dig
```

Then I analyze system and application logs:

```bash
journalctl -xe
dmesg
tail -f /var/log/messages
```

This helps identify:

* filesystem errors,
* storage disconnections,
* network problems,
* or application failures.

In real-time environments, I also correlate findings with monitoring tools like:

* Nagios for infrastructure and service monitoring

* Grafana dashboards for performance visualization

* Prometheus for collecting server and application metrics

Once the root cause is identified, I take corrective actions such as:

* resolving storage latency,
* restarting hung services,
* clearing stuck mounts,
* coordinating with storage/network teams,
* tuning applications,
* or optimizing filesystem performance.

In my experience, when CPU and memory are normal but the server is slow, the issue is usually related to disk I/O wait, storage latency, or blocked processes rather than compute resources.



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



