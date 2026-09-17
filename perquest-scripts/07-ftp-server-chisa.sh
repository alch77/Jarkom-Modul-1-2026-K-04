#!/bin/bash
# Nomor 7 — FTP Server di Chisa, shared folder /var/wired/data
# Kebijakan: alice = read & write, mika = read-only, eiri = blacklist (tanpa akses)
# Dijalankan di: Chisa (image alpinet/Alpine -> pakai apk)
set -e

echo "[07] Install vsftpd..."
apk update && apk add vsftpd

echo "[07] Siapkan folder & user..."
mkdir -p /var/wired/data
for U in alice mika eiri; do
  id "$U" >/dev/null 2>&1 || adduser -D "$U"
  echo "  user $U OK"
done
# Set password bila belum tahu (ganti sesuai kebutuhan praktikum)
# echo "alice:alice123" | chpasswd
# echo "mika:mika123" | chpasswd
# echo "eiri:eiri123" | chpasswd

echo "[07] Tulis /etc/vsftpd/vsftpd.conf ..."
mkdir -p /etc/vsftpd/user_conf
cat > /etc/vsftpd/vsftpd.conf <<'EOF'
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES

local_root=/var/wired/data

chroot_local_user=YES
allow_writeable_chroot=YES

pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30100
pasv_promiscuous=YES

userlist_enable=YES
userlist_deny=NO
userlist_file=/etc/vsftpd/user_list

user_config_dir=/etc/vsftpd/user_conf

local_umask=022
seccomp_sandbox=NO
EOF

echo "[07] Whitelist hanya alice & mika (eiri otomatis ditolak = blacklist)..."
printf "alice\nmika\n" > /etc/vsftpd/user_list

echo "[07] Per-user override: alice RW, mika read-only..."
echo "write_enable=YES" > /etc/vsftpd/user_conf/alice
echo "write_enable=NO"  > /etc/vsftpd/user_conf/mika

echo "[07] Jalankan vsftpd..."
pkill vsftpd || true
vsftpd /etc/vsftpd/vsftpd.conf &
sleep 1
netstat -tlpn 2>/dev/null | grep 21 || ss -tlpn 2>/dev/null | grep 21 || echo "(cek manual: pastikan listen port 21)"

echo "[07] Uji cepat dari server:"
ls -ld /var/wired/data
cat /etc/vsftpd/user_list
cat /etc/vsftpd/user_conf/alice /etc/vsftpd/user_conf/mika

echo "[07] SELESAI. Bukti manual (dari client lain, pakai lftp):"
echo "  # alice read&write OK:"
echo "  lftp -u alice 192.213.2.2 -e 'put signal_alice.txt; ls; bye'"
echo "  # eiri harus 530 Permission denied:"
echo "  lftp -u eiri 192.213.2.2 -e 'ls; bye'"
