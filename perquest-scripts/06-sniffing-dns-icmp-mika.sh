#!/bin/bash
# Nomor 6 — Generator traffic di Mika + sniffing Wireshark (filter DNS atau ICMP)
# Dijalankan di: Mika (generator) ; Capture: klik kanan link Switch1-Mika -> Start capture (Wireshark)
# Display filter Wireshark:  dns or icmp
# File generator: traffic_protocol7.zip (lihat links.txt Google Drive)
set -e

ZIP_URL="https://drive.google.com/drive/folders/1ZjFvWIjvAQAjE9pPthm7V_bGyaSt93lY?usp=sharing"
echo "[06] Download manual traffic_protocol7.zip dari:"
echo "     $ZIP_URL"
echo "     (lihat links.txt; simpan lalu ekstrak di Mika)"
echo ""

# Jika file generator sudah ada di direktori kerja, jalankan; jika belum, beri contoh traffic manual
if ls ./*.sh ./*.py traffic_* 2>/dev/null | grep -q .; then
  echo "[06] File generator ditemukan, daftar:"
  ls -l ./
  echo "[06] Jalankan file generator yang disediakan (contoh bila .sh):"
  echo "      chmod +x *.sh && ./<nama_generator>.sh"
else
  echo "[06] File generator belum ada di $(pwd). Contoh traffic pengganti (DNS+ICMP)"
  echo "     agar capture tetap menunjukkan pola yang sama seperti README:"
  echo "     - ICMP Echo ke 1.1.1.1 & 8.8.8.8"
  echo "     - DNS query: its.ac.id, example.com, github.com, google.com, cloudflare.com"
fi

echo "[06] Menjalankan traffic contoh (samakan dengan perilaku generator)..."
for HOST in its.ac.id example.com github.com google.com cloudflare.com; do
  nslookup "$HOST" 8.8.8.8 || nslookup "$HOST" || dig "$HOST" || getent hosts "$HOST" || true
done
ping -c 3 1.1.1.1 || true
ping -c 3 8.8.8.8 || true
ping -c 3 its.ac.id || true

echo ""
echo "[06] SELESAI di sisi Mika."
echo "[06] Analisis Wireshark (di host GNS3, bukan di node):"
echo "  1. Start capture pada link Switch1-Mika SEBELUM menjalankan generator."
echo "  2. Terapkan display filter:  dns or icmp"
echo "  3. Harus terlihat: ICMP Echo Request/Reply Mika(192.213.1.3)<->1.1.1.1, <->8.8.8.8,"
echo "     termasuk 103.94.189.5 (its.ac.id); DNS standard query A/AAAA + response tiap domain."
echo "  4. Statistics -> Conversations: ~16 pkt dgn 1.1.1.1, ~26 pkt dgn 8.8.8.8, ~6 pkt/588B dgn 103.94.189.5."
