#!/bin/bash
# Nomor 11 — Telnet plaintext: akun phantom_user/wired_ghost di Chisa, login dari Eiri
# Dijalankan di: Chisa (bagian server) + Eiri (bagian client)
# Capture: link Switch2-Chisa, filter: telnet ; Follow TCP Stream -> kredensial plaintext
# Cara pakai:
#   Di Chisa: sudo ./11-telnet-phantom-user.sh server"
#   Di Eiri : ./11-telnet-phantom-user.sh client
set -e
MODE="${1:-server}"

if [ "$MODE" = "server" ]; then
  echo "[11] (Chisa/Alpine-BusyBox) Buat akun phantom_user..."
  id phantom_user >/dev/null 2>&1 || adduser -D phantom_user
  echo "phantom_user:wired_ghost" | chpasswd
  echo "[11] telnetd BusyBox sudah bawaan Alpine, tidak perlu install."
  echo "      Pastikan inetd/telnetd aktif menerima koneksi port 23."
  echo "      (Alpine: telnetd berjalan via inetd/xinetd atau manual sesuai image.)"
  echo "[11] SELESAI sisi server. Lanjut login dari Eiri."
  exit 0
fi

echo "[11] (Eiri) Koneksi telnet ke Chisa 192.213.2.2 ..."
echo "      Login: phantom_user / Password: wired_ghost"
echo "      Perintah interaktif: whoami, ls, exit"
apk add --no-cache busybox-extras 2>/dev/null || true  # memastikan client telnet ada bila image minimal
telnet 192.213.2.2

echo ""
echo "[11] Analisis Wireshark (capture link Switch2-Chisa, filter 'telnet'):"
echo "  - Terlihat puluhan paket kecil (data 2/7/15/25/27/34 bytes): tiap ketikan 1 paket"
echo "    = bukti mode character-at-a-time + echo real-time dari server."
echo "  - Klik kanan paket -> Follow -> TCP Stream sejak awal koneksi terlihat plaintext:"
echo "      'Chisa login:' + 'phantom_user' (merah/client), 'Password:' + 'wired_ghost',"
echo "      lalu 'Welcome to Alpine!' = autentikasi berhasil."
echo "  - Kesimpulan: Telnet tanpa enkripsi; sniffing link membaca user+password langsung."
