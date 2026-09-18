# Laporan Nomor 14-20 - Praktikum Modul 1 Jarkom 2026

Bagian ini berisi analisis file capture (.pcap) untuk mencari jejak serangan yang dilakukan Eiri di dalam jaringan The Wired. Setiap nomor punya file capture sendiri, dan jawabannya divalidasi lewat socket server yang disediakan asisten.

## Nomor 14 - Brute Force ke Web Login

File yang dianalisis: `soal14_wired_bruteforce.pcapng`

Di Wireshark, file ini dibuka lalu diberi filter `http.request.method == "POST"`. Filter ini dipakai supaya cuma kelihatan paket yang isinya percobaan login (POST ke `/login.php`). Ternyata paket ini muncul berulang-ulang ratusan kali, semua dari IP yang sama menuju IP yang sama - ini tandanya ada serangan brute force (coba password berkali-kali sampai berhasil).

![capture-bruteforce-post](<assets/capture-bruteforce-post.png>)

Dari situ ketahuan IP penyerangnya `172.26.7.50`, menyerang ke `172.26.7.100` di port `8080` (port ini dilihat dengan klik salah satu paket, lalu buka bagian TCP-nya).

Untuk cari percobaan yang berhasil, dicari paket yang response-nya beda dari yang lain (kebanyakan gagal), lalu diklik kanan pilih **Follow > HTTP Stream** biar bisa baca isi percakapannya secara lengkap.

![follow-stream-bruteforce-success](<assets/follow-stream-bruteforce-success.png>)

Dari situ kelihatan password yang berhasil dipakai adalah `wired_pr0tocol_7` untuk user `lain_admin`, dan server yang dipakai adalah `Apache/2.4.62` (tertulis di bagian header response-nya).

**Rangkuman jawaban:**
- IP penyerang: `172.26.7.50`
- IP target dan port: `172.26.7.100:8080`
- Password `lain_admin`: `wired_pr0tocol_7`
- Web server: `Apache/2.4.62`

Jawaban ini dicocokkan ke socket server:
```bash
nc 10.4.89.246 3401
```

![nc-validasi-soal14](<assets/nc-validasi-soal14.png>)

Hasilnya benar dan dapat flag: `KOMJAR26{W1r3d_Brut3_BzlXG07JT1ofoaP9qUA7b7QH9}`

## Nomor 15 - Nyuri Data Lewat Keyboard USB

File yang dianalisis: `soal15_wired_usb_hid.pcap`

Di file ini, direkam data dari sebuah keyboard USB yang tersambung ke komputer. Untuk cari tahu merek keyboard-nya, dipakai filter `usb.bDescriptorType == 0x01` yang nampilin data device saat pertama kali keyboard itu dicolok.

![capture-usb-descriptor](<assets/capture-usb-descriptor.png>)

Dari situ ketahuan keyboard ini buatan **Logitech** dengan Vendor ID `0x046d` dan Product ID `0xc31c` (tipe Keyboard K120).

Selanjutnya, filter diganti jadi `usb.transfer_type == 0x01` untuk lihat semua data yang dikirim keyboard tiap kali tombol ditekan.

![capture-usb-interrupt](<assets/capture-usb-interrupt.png>)

Dari sini ketahuan juga keyboard itu terdaftar sebagai **Device nomor 7** di sistem.

Bagian paling seru adalah decode pesan rahasianya. Setiap tombol yang ditekan itu terekam sebagai kode angka (bukan huruf langsung), jadi harus dicocokkan satu-satu pakai tabel kode keyboard USB (namanya tabel HID Usage ID).

![capdata-usb-hid](<assets/capdata-usb-hid.png>)

Setelah semua kode angka itu dicocokkan jadi huruf, ketemu pesan rahasianya: `Wired_Protocol_7_is_alive_2026`

**Rangkuman jawaban:**
- Vendor ID: `0x046d`
- Product ID: `0xc31c`
- Nomor device: `7`
- Pesan rahasia: `Wired_Protocol_7_is_alive_2026`

Jawaban ini dicocokkan ke socket server:
```bash
nc 10.4.89.246 3402
```

![nc-validasi-soal15](<assets/nc-validasi-soal15.png>)

Hasilnya benar dan dapat flag: `KOMJAR26{USB_K3ystr0k3_NTe1qJAkSti7cpeda3Pgzc4OS}`

## Nomor 16 - Malware Dicuri Lewat FTP

File yang dianalisis: `soal16_wired_ftp_theft.pcapng`

Di file ini ada beberapa percakapan FTP yang berbeda, jadi supaya gak ketuker, dipakai filter khusus `ip.addr == 198.51.100.7 && ftp` yang cuma nampilin percakapan menuju server FTP yang mencurigakan.

![capture-ftp-theft-session](<assets/capture-ftp-theft-session.png>)

Dari situ ketahuan server FTP-nya kasih salam pembuka (banner) `Welcome to Wired FTP Server (vsftpd 3.0.5)`, terus ada yang login pakai username `knights_agent` dan password `N4v1_s3cur3_2026`.

Untuk cari ukuran file malware-nya, dicari perintah `SIZE knights_payload.exe` di percakapan yang sama.

![ftp-size-response](<assets/ftp-size-response.png>)

**Rangkuman jawaban:**
- IP server FTP: `198.51.100.7`
- Banner FTP: `vsftpd 3.0.5`
- Kredensial login: `knights_agent:N4v1_s3cur3_2026`
- Ukuran file malware: `524288` bytes

Jawaban ini dicocokkan ke socket server:
```bash
nc 10.4.89.246 3403
```

![nc-validasi-soal16](<assets/nc-validasi-soal16.png>)

## Nomor 17 - Malware Diunduh Lewat Website

File yang dianalisis: `soal17_wired_http_c2.pcapng`

Di file ini ada beberapa alamat website yang diakses, tapi cuma satu yang penting: yang mengunduh file `.exe`. Cara nyarinya pakai filter `http.request` lalu dicari baris yang path-nya berakhiran `.exe` (yang lain cuma trafik biasa/pengalih perhatian).

![capture-http-c2-requests](<assets/capture-http-c2-requests.png>)

Ditemukan permintaan mengunduh file dari domain `wired-update.net`, nama filenya `navi_agent.exe`.

![capture-http-c2-response](<assets/capture-http-c2-response.png>)

**Rangkuman jawaban:**
- Domain tempat malware diunduh: `wired-update.net`
- IP server penyerang: `203.0.113.42`
- Nama file malware: `navi_agent.exe`
- Kode status HTTP: `200`

Jawaban ini dicocokkan ke socket server:
```bash
nc 10.4.89.246 3404
```

![nc-validasi-soal17](<assets/nc-validasi-soal17.png>)

## Nomor 18 - Malware Disebar Lewat File Sharing Windows (SMB)

File yang dianalisis: `soal18_wired_smb_transfer.pcapng`

File ini merekam trafik protokol SMB, yaitu protokol yang dipakai Windows buat berbagi file antar komputer. Dipakai filter `smb2` untuk lihat semua trafiknya.

![capture-smb-overview](<assets/capture-smb-overview.png>)

Filter diganti `smb2.cmd == 3` untuk lihat percobaan "masuk" ke folder komputer korban. Ternyata penyerang masuk ke folder khusus bernama `ADMIN$` (folder sistem Windows).

![capture-smb-treeconnect](<assets/capture-smb-treeconnect.png>)

Filter diganti lagi `smb2.cmd == 5` untuk lihat file apa yang dibuat di situ. Ketemu file `wired_trojan_payload.exe` di dalam folder `System32`.

![capture-smb-create-write](<assets/capture-smb-create-write.png>)

**Rangkuman jawaban:**
- Protokol: SMB2
- IP pengirim: `10.7.3.100`
- IP korban: `10.7.1.50`
- Nama share/folder tujuan: `ADMIN$`
- Nama file malware: `wired_trojan_payload.exe`

Jawaban ini dicocokkan ke socket server:
```bash
nc 10.4.89.246 3405
```

![nc-validasi-soal18](<assets/nc-validasi-soal18.png>)

Hasilnya benar dan dapat flag: `KOMJAR26{SMB_Tr4nsf3r_sprNhRiD8FIjzaRrvnlrXkNL0}`

## Nomor 19 - Email Ancaman/Pemerasan

File yang dianalisis: `soal19_wired_smtp_threat.pcapng`

Di file ini ada beberapa email yang lewat, tapi yang dicari adalah email dari alamat aneh `185.234.72.19` menuju server email `203.0.113.100`. Diklik kanan salah satu paketnya lalu pilih **Follow > TCP Stream** buat baca isi emailnya secara lengkap.

![follow-stream-smtp-threat](<assets/follow-stream-smtp-threat.png>)

Isi emailnya ternyata ancaman/pemerasan dari Eiri, ditujukan ke `victim@protocol7.co.jp`. Di dalam isi emailnya disebutkan password yang diklaim bocor, jenis malware yang katanya sudah disebar, batas waktu yang diberikan, dan kode ID pengirim.

**Rangkuman jawaban:**
- Email korban: `victim@protocol7.co.jp`
- Password yang diklaim bocor: `pr0tocol_7_user`
- Jenis malware: Ransomware
- Batas waktu: 72 jam (3 hari)
- MailClientID: `7719980706`

Jawaban ini dicocokkan ke socket server:
```bash
nc 10.4.89.246 3406
```

![nc-validasi-soal19](<assets/nc-validasi-soal19.png>)

## Nomor 20 - Malware Sembunyi di Balik HTTPS (TLS)

File yang dianalisis: `wired_tls_decrypt.pcapng`, dibantu file `keyslogfile.txt`

Trafik HTTPS itu terenkripsi, jadi gak bisa dibaca langsung. Makanya dipasang file kunci (`keyslogfile.txt`) lewat menu **Edit > Preferences > Protocols > TLS**, biar Wireshark bisa buka enkripsinya dan isinya bisa dibaca.

![tls-preferences-keylog](<assets/tls-preferences-keylog.png>)

Setelah kunci terpasang, dipakai filter `tls.handshake.type == 1` untuk lihat info awal koneksi HTTPS-nya (nama ini disebut Client Hello). Dari situ ketahuan versi TLS yang dipakai dan nama domain (SNI) yang diakses.

![capture-tls-clienthello](<assets/capture-tls-clienthello.png>)

Setelah dibuka enkripsinya, filter diganti jadi `http` supaya bisa baca isi percakapan yang sebelumnya tersembunyi.

![capture-tls-decrypted-http](<assets/capture-tls-decrypted-http.png>)

Isinya ternyata request `HEAD /` ke domain `example.com`, dengan software pengirim (`User-Agent`) bernama `curl/7.62.0`.

**Rangkuman jawaban:**
- Versi TLS: TLS 1.2
- Domain (SNI): `example.com`
- IP server: `93.184.216.34`
- User-Agent: `curl/7.62.0`
- Method dan path: `HEAD /`

Jawaban ini dicocokkan ke socket server:
```bash
nc 10.4.89.246 3407
```

![nc-validasi-soal20](<assets/nc-validasi-soal20.png>)
