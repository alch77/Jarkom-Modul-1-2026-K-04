#!/bin/bash
# Nomor 10 — Knights ping stress ke Chisa: payload 128B, interval 0.3s, 77 paket
# Dijalankan di: Knights ; Capture: link Switch2-Chisa, filter: icmp
set -e

TARGET="192.213.2.2"

echo "[10] Ping stress Knights -> Chisa..."
ping -c 77 -s 128 -i 0.3 "$TARGET"

echo ""
echo "[10] SELESAI. Hasil yang diharapkan (lihat README):"
echo "  - Frame length 170 bytes = 14 (Eth) + 20 (IP) + 8 (ICMP hdr) + 128 (payload)"
echo "  - Request: Type 8 Code 0 (Echo Request); Reply: Type 0 Code 0 (Echo Reply)"
echo "  - 0% packet loss (77 tx / 77 rx), RTT ~ min 0.458 / avg 0.601 / max 1.201 / mdev 0.143 ms"
echo "  - Verifikasi di Wireshark: filter 'icmp', cek pasangan Echo Request/Reply per sequence."
