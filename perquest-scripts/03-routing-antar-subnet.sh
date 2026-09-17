#!/bin/bash
# Nomor 3 — Routing antar subnet: seluruh Entitas saling terhubung via Lain
# Dijalankan di: Lain (bagian A) + tiap Client (bagian B)
# Skema IP:
#   Lain eth1=192.213.1.1/24 (gw Switch1: Alice .1.2, Mika .1.3)
#   Lain eth2=192.213.2.1/24 (gw Switch2: Chisa .2.2)
#   Lain eth3=192.213.3.1/24 (gw Switch3: Knights .3.2, Eiri .3.3)
# Cara pakai:
#   Di Lain        : sudo ./03-routing-antar-subnet.sh lain
#   Di Client      : sudo ./03-routing-antar-subnet.sh client <nama>   (nama: alice|mika|chisa|knights|eiri)
#   Tanpa argumen  : otomatis deteksi — jika ada eth1/eth2/eth3 dianggap Lain, jika tidak dianggap client (wajib isi variabel CLIENT_IP/GW manual)
set -e

MODE="${1:-auto}"
CNAME="${2:-}"

configure_lain() {
  echo "[03] Konfigurasi gateway Lain eth1/eth2/eth3..."
  for IFACE in eth1 eth2 eth3; do
    # Hapus blok lama iface tersebut bila ada agar idempoten
    if grep -q "^iface $IFACE inet static" /etc/network/interfaces 2>/dev/null; then
      echo "[03] $IFACE sudah static, dilewati (cek manual bila perlu diubah)"
    fi
  done

  # Tambahkan yang belum ada
  grep -q "^iface eth1 inet static" /etc/network/interfaces 2>/dev/null || cat >> /etc/network/interfaces <<'EOF'
auto eth1
iface eth1 inet static
    address 192.213.1.1
    netmask 255.255.255.0
EOF
  grep -q "^iface eth2 inet static" /etc/network/interfaces 2>/dev/null || cat >> /etc/network/interfaces <<'EOF'
auto eth2
iface eth2 inet static
    address 192.213.2.1
    netmask 255.255.255.0
EOF
  grep -q "^iface eth3 inet static" /etc/network/interfaces 2>/dev/null || cat >> /etc/network/interfaces <<'EOF'
auto eth3
iface eth3 inet static
    address 192.213.3.1
    netmask 255.255.255.0
EOF

  echo "[03] Aktifkan ip_forward..."
  sysctl -w net.ipv4.ip_forward=1
  # Persist agar survive reboot (Debian)
  grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

  echo "[03] Nyalakan interface..."
  ifup eth1 || ip addr add 192.213.1.1/24 dev eth1 2>/dev/null || true
  ifup eth2 || ip addr add 192.213.2.1/24 dev eth2 2>/dev/null || true
  ifup eth3 || ip addr add 192.213.3.1/24 dev eth3 2>/dev/null || true
  ip -br a
  echo "[03] Lain siap me-routing antar subnet (multi-homed + ip_forward, tanpa static route tambahan)."
}

configure_client() {
  # Pemetaan nama -> IP/GW sesuai README
  case "$CNAME" in
    alice)   IP="192.213.1.2"; GW="192.213.1.1" ;;
    mika)    IP="192.213.1.3"; GW="192.213.1.1" ;;
    chisa)   IP="192.213.2.2"; GW="192.213.2.1" ;;
    knights) IP="192.213.3.2"; GW="192.213.3.1" ;;
    eiri)    IP="192.213.3.3"; GW="192.213.3.1" ;;
    *) echo "Gunakan: $0 client <alice|mika|chisa|knights|eiri>"; exit 1 ;;
  esac
  echo "[03] Konfigurasi client $CNAME -> $IP/24 gw $GW ..."
  cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $IP
    netmask 255.255.255.0
    gateway $GW
EOF
  ifdown eth0 || true
  ifup eth0
  ip -br a
  echo "[03] Uji ping lintas subnet dari $CNAME:"
  # Ping gateway sendiri + satu node beda subnet sebagai sampel
  ping -c 3 "$GW"
  echo "[03] Lanjut ping manual ke semua node lain untuk bukti 0% loss (lihat README):"
  echo "  Alice .1.2 | Mika .1.3 | Chisa .2.2 | Knights .3.2 | Eiri .3.3"
}

case "$MODE" in
  lain) configure_lain ;;
  client) configure_client ;;
  auto)
    if ip link show eth1 >/dev/null 2>&1 && ip link show eth3 >/dev/null 2>&1; then
      configure_lain
    else
      echo "Mode auto: terdeteksi sebagai client. Jalankan dengan argumen nama client."
      echo "Contoh: $0 client alice"
      exit 1
    fi
    ;;
  *) echo "Gunakan: $0 [lain|client <nama>]"; exit 1 ;;
esac
