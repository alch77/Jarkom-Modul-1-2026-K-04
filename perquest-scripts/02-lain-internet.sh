#!/bin/bash
# Nomor 2 — Router Lain tersambung ke internet publik via NAT/DHCP (eth0)
# Dijalankan di: Lain (image debinet:latest, eth0 -> NAT1)
# Topologi: eth0 -> NAT, eth1 -> Switch1, eth2 -> Switch2, eth3 -> Switch3
set -e

echo "[02] Konfigurasi eth0 DHCP (NAT/DHCP)..."

# Pastikan entri eth0 dhcp ada (idempoten)
if ! grep -q "^iface eth0 inet dhcp" /etc/network/interfaces 2>/dev/null; then
  cat >> /etc/network/interfaces <<'EOF'
auto eth0
iface eth0 inet dhcp
EOF
  echo "[02] Entri eth0 ditambahkan ke /etc/network/interfaces"
else
  echo "[02] Entri eth0 dhcp sudah ada, dilewati"
fi

echo "[02] Restart interface eth0..."
ifdown eth0 || true
ifup eth0

echo "[02] Verifikasi IP eth0 (harusnya 192.168.122.x/24 dari NAT):"
ip -br a show eth0 || ip a show eth0

echo "[02] Verifikasi resolv.conf upstream (harusnya 192.168.122.1):"
cat /etc/resolv.conf || true

echo "[02] Uji konektivitas internet:"
ping -c 3 8.8.8.8
ping -c 3 google.com

echo "[02] SELESAI: Lain terhubung internet via eth0 (DHCP NAT)."
