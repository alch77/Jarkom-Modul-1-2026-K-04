#!/bin/bash
# Nomor 13 — OpenSSH di Knights + key mika_admin di Mika, PasswordAuthentication no
# Dijalankan di: Knights (server) + Mika (client)
# Cara pakai:
#   Di Knights: sudo ./13-ssh-knights-mika.sh server
#   Di Mika   : ./13-ssh-knights-mika.sh client   (lalu ikuti instruksi ssh-copy-id/ssh)
set -e
MODE="${1:-server}"
SERVER="192.213.3.2"
USER="mika_admin"

if [ "$MODE" = "server" ]; then
  echo "[13] (Knights) Install & konfigurasi OpenSSH server..."
  apk add --no-cache openssh
  ssh-keygen -A
  id "$USER" >/dev/null 2>&1 || adduser -D "$USER"
  echo "mika_admin:mika123" | chpasswd

  # Nonaktifkan password auth, aktifkan pubkey (idempoten)
  grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
  grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

  pkill sshd || true
  /usr/sbin/sshd
  echo "[13] sshd jalan, cek listen 22:"
  netstat -tlpn 2>/dev/null | grep 22 || ss -tlpn 2>/dev/null | grep 22 || true
  echo "[13] SELESAI sisi server. Lanjut di Mika untuk distribusi public key."
  exit 0
fi

echo "[13] (Mika) Install client + buat key mika_admin..."
apk add --no-cache openssh-client
id "$USER" >/dev/null 2>&1 || adduser -D "$USER"
mkdir -p /home/"$USER"/.ssh
chown "$USER":"$USER" /home/"$USER"/.ssh
chmod 700 /home/"$USER"/.ssh

if [ ! -f /home/"$USER"/.ssh/id_ed25519 ]; then
  su "$USER" -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519"
else
  echo "[13] Key sudah ada, dilewati."
fi
su "$USER" -c "cat ~/.ssh/id_ed25519.pub"

echo "[13] Distribusikan public key ke Knights (pilih salah satu):"
echo "  su $USER -c \"ssh-copy-id $USER@$SERVER\""
echo "  # atau manual:"
echo "  su $USER -c \"cat ~/.ssh/id_ed25519.pub | ssh $USER@$SERVER 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'\""
echo ""
echo "[13] Uji login tanpa password:"
echo "  su $USER -c \"ssh $USER@$SERVER\""
echo ""
echo "[13] Analisis Wireshark (capture link Switch3-Knights, filter 'ssh or tcp.port==22'):"
echo "  - Protocol Version Exchange plaintext: 'SSH-2.0-OpenSSH_10.2' dua arah."
echo "  - Key Exchange Init dua arah + PQ/T Hybrid KEX Init/Reply + New Keys."
echo "  - Setelah New Keys semua 'Encrypted packet (len=...)' termasuk auth pubkey & shell."
echo "  - Mengapa tidak plaintext spt Telnet: setelah KEX, kunci sesi disepakati dan"
echo "    seluruh sesi dienkripsi end-to-end, sehingga kredensial tidak bisa di-sniff."
