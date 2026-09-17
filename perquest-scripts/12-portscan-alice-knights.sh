#!/bin/bash
# Nomor 12 — Alice port-scan Knights: 22 & 80 terbuka, 7777 tertutup
# Analisis: SYN dibalas SYN-ACK (open) vs RST-ACK (closed)
# Dijalankan di: Alice ; Capture: link Switch3-Knights, filter: tcp.port==22 or tcp.port==80 or tcp.port==7777
set -e

TARGET="192.213.3.2"

echo "[12] Pastikan nc tersedia di Alice..."
apk add --no-cache busybox-extras openbsd-netcat 2>/dev/null || (apt-get update && apt-get install -y netcat-openbsd) || true

echo "[12] Scan 22 (SSH), 80 (HTTP), 7777 (closed)..."
nc -zv "$TARGET" 22 || true
nc -zv "$TARGET" 80 || true
nc -zv "$TARGET" 7777 || true

echo ""
echo "[12] Hasil yang diharapkan:"
echo "  - 22   : succeeded/open (SYN -> SYN,ACK; bahkan terlihat banner SSH-2.0-OpenSSH_10.2)"
echo "  - 80   : succeeded/open (SYN -> SYN,ACK, lalu FIN,ACK normal dua arah)"
echo "  - 7777 : connection refused/closed (SYN -> RST,ACK, tidak ada listener)"
echo "[12] Verifikasi di Wireshark dengan filter 'tcp.port==22 or tcp.port==80 or tcp.port==7777'."
