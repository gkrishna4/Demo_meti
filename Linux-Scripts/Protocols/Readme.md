## You are unable to connect to a server using its hostname, but you can connect successfully using the IP address. 
## What could be the issue, and how would you troubleshoot it?

I would first validate DNS using `nslookup` or `dig`, then check `/etc/resolv.conf` for correct nameserver entries and search domains.
I would verify `/etc/hosts` for static mappings, test hostname resolution using `ping hostname`, check `/etc/nsswitch.conf` to ensure
DNS lookup is enabled, and confirm DNS server reachability. Usually, the issue is DNS misconfiguration, missing hostname entries,
or an unreachable DNS server.

## So what is the service that we use to join to the domain?

we generally use `SSSD` for authentication and identity management to integrate Linux with Active Directory. We use the 
`realm join` command through realmd to join the server to the domain, and sssd handles authentication and user lookup.
I verify the join using realm list and ensure the sssd service is running.

                Common domain join command:-       realm join <domain-name> -U <username>
                Verify domain join:-               realm list
                Check SSSD service:-               systemctl status sssd
                Configuration file:-               /etc/sssd/sssd.conf

## What service runs after domain join?
The primary service is sssd, which handles authentication, caching, and communication with Active Directory.

## What is Packet Droping?
Linux server or network device does not accept or send some network packets and removes them instead of processing them. 
This can happen when the server is busy, network traffic is too high, firewall rules block traffic, memory or buffers are 
full, or there are network/interface problems.

Check whether the issue is at OS, NIC, network, firewall, or application level. I usually start with interface statistics
using `ip -s link` or `ethtool -S`, then verify CPU, memory, and load using `top`, `sar`, and `vmstat`. I check for 
`RX/TX drops`, `kernel-level drops` through `netstat -s`, firewall drops through `iptables` or `firewalld logs`, and
finally validate connectivity using `tcpdump` for packet-level analysis. If required, I coordinate with the network team
to verify switch port errors, MTU mismatch, or bandwidth saturation.



## Samba Server
Samba is a free and open‑source software that helps different operating systems share files, folders, and printers with 
each other.
## What problem does Samba solve?
<img width="1080" height="540" alt="Screenshot (21)" src="https://github.com/user-attachments/assets/28e3f7dc-96b4-4a53-ada7-48435f45e724" />

Normally:
    1) Linux shares files with Linux using NFS,
    2) Windows shares files with Windows using DFS,
    3) Mac uses AFP,
    
  These systems cannot easily share with each other.
  When different operating systems (Linux, Windows, Mac, etc.) need to share resources, it becomes difficult.
👉 Samba solves this problem.

<img width="1920" height="1080" alt="Screenshot (22)" src="https://github.com/user-attachments/assets/a1d0abd2-0c9c-4a6e-a64a-ad6f5d27dea0" />
It uses a common file‑sharing system called CIFS (Common Internet File System) and the SMB protocol, which works over TCP/IP (the same network protocol used by all systems).

## How Samba works (simple view)
A Linux server runs Samba, Files are shared from that server, Clients from different operating systems (Windows, Mac, Linux) 
access those files All communication happens over TCP/IP using SMB/CIFS.

<img width="1920" height="1080" alt="Screenshot (19)" src="https://github.com/user-attachments/assets/155ae68f-2ea0-436b-9427-9d74348eaf4c" />
Imagine you have one Linux server running Samba. This Linux server is called the Samba Server.
From this Samba server, you have shared different resources, such as:
DVD drive, Pen drive, Tape drive, Folder.
 
Each resource on the Linux server: Is mounted at a specific location

<img width="1920" height="1080" alt="Screenshot (20)" src="https://github.com/user-attachments/assets/fc184567-d0c4-4356-98ce-ee9aeb7b9e48" />







