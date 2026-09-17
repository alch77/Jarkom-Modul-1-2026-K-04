#!/bin/bash
# Nomor 9 — Mika unduh Protokol Tujuh via akun mika (read-only), bukti gagal upload (550)
# Dijalankan di: Chisa (bagian A: siapkan file) + Mika (bagian B: get + put)
# Cara pakai:
#   Di Chisa: sudo ./09-download-mika-readonly.sh server
#   Di Mika : ./09-download-mika-readonly.sh client
set -e
MODE="${1:-client}"
FTP_SERVER="192.213.2.2"
FTP_USER="mika"

if [ "$MODE" = "server" ]; then
  echo "[09] (Chisa) Siapkan /var/wired/data/protokol_tujuh.doc ..."
  echo "Isi Dokumen Protokol Tujuh" > /var/wired/data/protokol_tujuh.doc
  chmod 644 /var/wired/data/protokol_tujuh.doc
  ls -l /var/wired/data/
  echo "[09] SELESAI sisi server."
  exit 0
fi

echo "[09] (Mika) Pastikan lftp ada..."
apk add --no-cache lftp 2>/dev/null || (apt-get update && apt-get install -y lftp) || true

echo "[09] Unduh protokol_tujuh.doc (harus BERHASIL)..."
lftp -u "$FTP_USER" "$FTP_SERVER" -e "get protokol_tujuh.doc; ls; bye"
ls -l protokol_tujuh.doc
echo "--- isi file ---"
cat protokol_tujuh.doc || true

echo "[09] Coba upload file_baru.txt (harus GAGAL 550 Permission denied)..."
echo "Uji coba unggah file dari Mika" > file_baru.txt
set +e
lftp -u "$FTP_USER" "$FTP_SERVER" -e "put file_baru.txt; bye"
RC=$?
set -e
echo "[09] Exit code lftp put: $RC (put mika memang diharapkan gagal/550)."
echo "[09] Pada capture Wireshark terlihat server membalas '550 Permission denied' untuk STOR dari mika,"
echo "     bukti write_enable=NO pada /etc/vsftpd/user_conf/mika bekerja."
