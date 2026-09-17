#!/bin/bash
# Nomor 4 — Firewall/iptables NAT Masquerade + DNS resolver agar tiap Client mandiri ke internet
# Dijalankan di: Lain (iptables) + tiap Client (resolv.conf)
# Upstream DNS Lain dari DHCP NAT: 192.168.122.1 ; resolver utama: 8.8.8.8
# Cara pakai:
#   Di Lain  : sudo ./04-nat-masquerade-dns.sh lain
#   Di Client: sudo ./04-nat-masquerade-dns.sh client
set -e
MODE="${1:-lain}"

configure_lain() {
  echo "[04] Aktifkan ip_forward..."
  sysctl -w net.ipv4.ip_forward=1

  echo "[04] Terapkan NAT Masquerade + FORWARD (idempoten, cek dulu)..."
  iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  for IN in eth1 eth2 eth3; do
    iptables -C FORWARD -i "$IN" -o eth0 -j ACCEPT 2>/dev/null || iptables -A FORWARD -i "$IN" -o eth0 -j ACCEPT
  done

  echo "[04] Upstream DNS Lain:"
  cat /etc/resolv.conf || true
  echo "[04] Tabel NAT:"
  iptables -t nat -L -v -n
}

configure_client() {
  echo "[04] Set DNS resolver client..."
  echo -e "nameserver 8.8.8.8\nnameserver 192.168.122.1" > /etc/resolv.conf
  cat /etc/resolv.conf
  echo "[04] Uji mandiri ke internet:"
  ping -c 3 8.8.8.8
  ping -c 3 google.com
}

case "$MODE" in
  lain) configure_lain ;;
  client) configure_client ;;
  *) echo "Gunakan: $0 [lain|client]"; exit 1 ;;
esac
echo "[04] SELESAI."
