#!/bin/bash
 
# ==== NODE KNIGHTS (Server SSH) ====
apk add --no-cache openssh
ssh-keygen -A

adduser -D mika_admin
echo "mika_admin:mika123" | chpasswd

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

/usr/sbin/sshd

# ==== NODE MIKA (Client) ====
apk add --no-cache openssh-client
adduser -D mika_admin
su - mika_admin

ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id mika_admin@192.213.3.2
cat ~/.ssh/id_ed25519.pub | ssh mika_admin@192.213.3.2 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

ssh mika_admin@192.213.3.2

# ==== NODE KNIGHTS (Server SSH) ====
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

pkill sshd || true
/usr/sbin/sshd