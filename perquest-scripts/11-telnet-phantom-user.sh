#!/bin/bash
 
# ==== NODE CHISA (Server Telnet) ====
apk add --no-cache busybox-extras
adduser -D phantom_user
echo "phantom_user:wired_ghost" | chpasswd
telnetd -F &

# ==== NODE EIRI (Client) ====
telnet 192.213.2.2
# login: phantom_user
# password: wired_ghost