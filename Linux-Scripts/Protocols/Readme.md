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







