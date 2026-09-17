#!/bin/bash
# Nomor 8 — Knights kirim dokumen intelijen ke FTP Chisa via akun alice
# Analisis Wireshark: perintah STOR, kode 226, port data PASV
# Dijalankan di: Knights (pengirim) ; Capture: link Switch2-Chisa, filter: ftp or ftp-data
# Prasyarat: script 07 sudah jalan di Chisa (192.213.2.2)
set -e

FTP_SERVER="192.213.2.2"
FTP_USER="alice"
FILE="laporan_intelijen.txt"

echo "[08] Pastikan lftp terinstal di Knights..."
apk add --no-cache lftp 2>/dev/null || (apt-get update && apt-get install -y lftp) || true

echo "[08] Buat dokumen intelijen..."
echo "Dokumen Intelijen Konfidensial" > "$FILE"
ls -l "$FILE"

echo "[08] Upload via akun alice (prompt password bila diminta)..."
# File knights_report.zip (links.txt) adalah sumber alternatif bila ada; default pakai file teks di atas.
lftp -u "$FTP_USER" "$FTP_SERVER" -e "put $FILE; ls; bye"

echo "[08] SELESAI upload."
echo "[08] Analisis Wireshark (di host, capture link Switch2-Chisa, filter 'ftp or ftp-data'):"
echo "  - Perintah upload : STOR laporan_intelijen.txt"
echo "  - Status sukses  : 226 Transfer complete"
echo "  - Response PASV  : mis. 227 Entering Passive Mode (192,213,2,2,117,66)"
echo "  - Port data      : 117*256+66 = 30018 (dalam rentang pasv 30000-30100)"
