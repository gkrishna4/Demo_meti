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

## What happens when the server load is very high, but CPU utilization remains low? How do you identify and troubleshoot that situation?
## A Linux server is responding very slowly, but CPU and memory utilization appear normal. What could be the possible causes, and how would you troubleshoot the issue?
I verify the overall server load and I/O wait by running commands like `top`, `uptime`, and `vmstat 5`. Even if CPU usage is low, a high load average or high wa (I/O wait) column indicates storage or disk-related bottlenecks.
This is the most common cause I see in production environments.
```
uptime          # Load average vs CPU cores
vmstat 5        # See %wa (I/O wait) - this is KEY
top             # Quick visual check
```
Then I analyze disk performance using `iostat -xz 5` and `iotop` to check for high await times, disk queue delays, storage latency, and heavy read/write operations. I also check whether any processes are stuck in  `D state` using
`ps -eo state,pid,cmd | grep '^D'`. Processes in `D state` usually indicate they are waiting for disk or storage operations, which is a clear sign the disk is the bottleneck.
```
iostat -xz 5    # Check disk latency and queue depth
iotop           # See which process is hammering the disk
ps -eo state,pid,cmd | grep "^D"  # Find stuck processes
```
Next, I verify NFS mount availability, SAN/storage connectivity, backup jobs, or hung application processes. For network-related delays, I run `sar -n DEV`, `iftop`, and `netstat -i`. Sometimes DNS delays can also slow applications, 
so I check with `nslookup` and `dig`. I also analyze system and application logs using `journalctl -xe`, `dmesg`, and tail logs to identify filesystem errors, storage disconnections, network problems, or application failures.
```
sar -n DEV      # Network stats
iftop           # Real-time traffic
netstat -i      # Interface errors/drops
```

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



