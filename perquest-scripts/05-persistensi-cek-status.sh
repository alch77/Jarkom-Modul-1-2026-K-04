#!/bin/bash
# Nomor 5 — Persistensi konfigurasi (anti-hilang saat restart) + script verifikasi /root/cek_status.sh
# Dijalankan di: Lain
# Prinsip: container GNS3 ephemeral, jadi perintah sysctl/iptables disisipkan sebagai baris "up" pada eth0
#           di /etc/network/interfaces agar otomatis jalan saat ifup/boot.
set -e

echo "[05] Sisipkan perintah persistensi pada blok eth0..."
# Pastikan blok eth0 dhcp ada
if ! grep -q "^iface eth0 inet dhcp" /etc/network/interfaces; then
  echo "ERROR: blok 'iface eth0 inet dhcp' tidak ditemukan. Jalankan script 02 dulu."
  exit 1
fi

# Tambahkan baris up bila belum ada (idempoten)
add_up() {
  grep -qF "$1" /etc/network/interfaces || echo "    $1" >> /etc/network/interfaces
}
# Catatan: baris "up ..." harus berada di dalam stanza iface eth0 agar dieksekusi saat ifup eth0.
# Skrip ini append sederhana; pastikan secara manual baris-baris berikut berada di bawah blok eth0
# (sesuai screenshot README iface-lain).
add_up "up sysctl -w net.ipv4.ip_forward=1"
add_up "up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
add_up "up iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT"
add_up "up iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT"
add_up "up iptables -A FORWARD -i eth3 -o eth0 -j ACCEPT"

echo "[05] Isi /etc/network/interfaces saat ini:"
cat /etc/network/interfaces

echo "[05] Buat /root/cek_status.sh ..."
cat > /root/cek_status.sh <<'EOF'
#!/bin/bash
echo "===== RINGKASAN INTERFACE ====="
ip -br a
echo ""
echo "===== TABEL NAT IPTABLES ====="
iptables -t nat -L -v -n
EOF
chmod +x /root/cek_status.sh

echo "[05] Jalankan verifikasi:"
/root/cek_status.sh

echo "[05] SELESAI. Uji: restart node (Stop/Start GNS3) lalu jalankan /root/cek_status.sh lagi."
echo "      Counter MASQUERADE bertambah (mis. 1 packets, 84 bytes) setelah ping dari client"
echo "      karena conntrack hanya menghitung paket pertama tiap flow (lihat README poin 5)."
