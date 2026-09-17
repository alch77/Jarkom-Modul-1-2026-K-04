# JARKOM MODUL 1 2026 K-04

## Anggota

| Nama | NRP |
| :---: | :---: |
| Albert Chen | 5027251034 |
| Boma Sahya Aryaguna | 5027251125 |

## Laporan

1. Untuk mempersiapkan pembangunan The Wired, Lain yang berperan sebagai Router membuat tiga Switch/Gateway: Switch 1 menuju dua Entitas yaitu Alice dan Mika, Switch 2 menuju Chisa, sedangkan Switch 3 menuju Knights dan Eiri. Kelima Entitas tersebut dikonfigurasi sebagai Client di GNS3.

![Topologi](<assets/topology.png>)

Router `Lain` dibuat menggunakan image `ardhptr21/debinet:latest` dengan 4 network adapter, kemudian ditambahkan 3 node **Ethernet switch** dan 5 node client menggunakan image `ardhptr21/alpinet:latest`. Interface `eth1` dihubungkan ke `Switch 1` (menuju Alice & Mika), `eth2` ke `Switch 2` (menuju Chisa), dan `eth3` ke `Switch 3` (menuju Knights & Eiri). `NAT1` dihubungkan ke `eth0` router sebagai jalur keluar ke internet publik.

2. Karena menurut Lain pada saat itu The Wired masih terisolasi dari dunia luar, konfigurasikan router Lain agar dapat tersambung langsung ke jaringan internet publik melalui NAT/DHCP pada interface eth0.

Interface `eth0` pada router Lain dihubungkan ke node NAT bawaan GNS3, kemudian dikonfigurasi untuk mendapatkan IP secara dinamis melalui DHCP pada file `/etc/network/interfaces`:

```bash
auto eth0
iface eth0 inet dhcp
```

Setelah konfigurasi diterapkan, interface `eth0` berhasil mendapatkan alokasi IP `192.168.122.168/24` dari NAT cloud, dan router dapat melakukan resolusi domain sekaligus ping ke `google.com` (0% packet loss, RTT rata-rata ~21.7 ms).

![Inet Lain](<assets/inet-lain.png>)

3. Setelah router Lain terhubung ke internet, pastikan seluruh Entitas (Client) di bawah Switch 1, Switch 2, dan Switch 3 dapat saling terhubung dan berkomunikasi satu sama lain melalui konfigurasi routing.

Ketiga interface router (`eth1`, `eth2`, `eth3`) dikonfigurasi dengan IP static sebagai gateway masing-masing subnet:

```bash
auto eth1
iface eth1 inet static
    address 192.213.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 192.213.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 192.213.3.1
    netmask 255.255.255.0
```

Karena router bersifat **multi-homed** (terhubung langsung ke ketiga subnet) dan `net.ipv4.ip_forward` diaktifkan, tidak diperlukan static route tambahan — paket antar subnet otomatis diteruskan oleh kernel Linux router begitu `ip_forward=1`.

![iface-lain](<assets/iface-lain.png>)

Verifikasi dengan `ip a` pada router Lain menunjukkan seluruh interface sudah teralokasi IP sesuai rencana: `eth0` = `192.168.122.168/24` (dari DHCP NAT), `eth1` = `192.213.1.1/24`, `eth2` = `192.213.2.1/24`, `eth3` = `192.213.3.1/24`.

![iface-lain-ipa](<assets/iface-lain-ipa.png>)

Setiap client kemudian dikonfigurasi dengan IP static dan gateway menunjuk ke interface router pada subnet masing-masing:
**Alice**
```bash
auto eth0
iface eth0 inet static
    address 192.213.1.2
    netmask 255.255.255.0
    gateway 192.213.1.1
```
**Mika**
```bash
auto eth0
iface eth0 inet static
    address 192.213.1.3
    netmask 255.255.255.0
    gateway 192.213.1.1
```
**Chisa**
```bash
auto eth0
iface eth0 inet static
    address 192.213.2.2
    netmask 255.255.255.0
    gateway 192.213.2.1
```
**Knights**
```bash
auto eth0
iface eth0 inet static
    address 192.213.3.2
    netmask 255.255.255.0
    gateway 192.213.3.1
```
**Eiri**
```bash
auto eth0
iface eth0 inet static
    address 192.213.3.3
    netmask 255.255.255.0
    gateway 192.213.3.1
```

Hasil akhir konfigurasi interface tiap client:

![iface-alice](<assets/iface-alice.png>)

![iface-mika](<assets/iface-mika.png>)

![iface-chisa](<assets/iface-chisa.png>)

![iface-knights](<assets/iface-knights.png>)

![iface-eiri](<assets/iface-eiri.png>)

Pengujian ping antar client (lintas subnet) untuk membuktikan seluruh entitas dapat saling terhubung:

**Alice to Others**
![alice-ping-others](<assets/alice-ping-others.png>)

**Mika to Others**
![mika-ping-others](<assets/mika-ping-others.png>)

**Chisa to Others**
![chisa-ping-others](<assets/chisa-ping-others.png>)

**Knights to Others**
![knights-ping-others](<assets/knights-ping-others.png>)

**Eiri to Others**
![eiri-ping-others](<assets/eiri-ping-others.png>)

Seluruh pengujian ping lintas subnet di atas berhasil dengan 0% packet loss pada setiap node ke setiap node lainnya, membuktikan router Lain berhasil meneruskan traffic antar ketiga subnet hanya dengan `ip_forward` aktif, tanpa memerlukan static route tambahan.

4. Lain ingin agar setiap Entitas (Client) memiliki kemandirian di The Wired. Konfigurasikan firewall/iptables (NAT Masquerade) dan DNS resolver agar setiap Client dapat terhubung ke internet secara mandiri.

Sebelum dikonfigurasi ke client, dicek dulu nameserver upstream yang didapat router Lain dari DHCP NAT lewat `/etc/resolv.conf`:

![lain-resolve-dns](<assets/lain-resolve-dns.png>)

Terlihat nameserver-nya adalah `192.168.122.1`. IP inilah yang ditambahkan (bersama `8.8.8.8` sebagai resolver utama) ke `/etc/resolv.conf` tiap client:
```bash
echo -e "nameserver 8.8.8.8\nnameserver 192.168.122.1" > /etc/resolv.conf
```

Agar traffic dari ketiga subnet client dapat diteruskan keluar melalui `eth0`, diterapkan rule `iptables` NAT Masquerade pada router Lain:
```bash
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth0 -j ACCEPT
```

![iptables-masquerade-lain](<assets/iptables-masquerade-lain.png>)

- `MASQUERADE` menerjemahkan (translate) IP privat client menjadi IP publik router saat keluar lewat `eth0`.
- `FORWARD` rule mengizinkan paket dari tiap subnet client diteruskan router menuju `eth0`.

Verifikasi bahwa `/etc/resolv.conf` sudah benar diterapkan di seluruh client (Alice, Mika, Chisa, Knights, Eiri):
![client-resolve-config](<assets/client-resolve-config.png>)

Pengujian dari client Alice memakai IP maupun domain:
```bash
ping -c 3 8.8.8.8
ping -c 3 google.com
```

![alice-ping-8888](<assets/alice-ping-8888.png>)

Kedua pengujian berhasil (0% packet loss). Hal yang sama diuji ulang secara serentak dari seluruh client lain (Mika, Chisa, Knights, Eiri) yang juga berhasil melakukan resolusi `google.com` dan ping keluar tanpa packet loss, membuktikan setiap client dapat terhubung ke internet secara mandiri:

![all-clients-ping-google](<assets/all-clients-ping-google.png>)

5. Untuk mengantisipasi restart tiba-tiba, pastikan seluruh konfigurasi jaringan tidak hilang saat semua node di-restart. Buat script verifikasi di `/root/cek_status.sh`.

Karena container Docker di GNS3 bersifat ephemeral (state runtime hilang saat restart, kecuali file yang tersimpan di `/root` dan konfigurasi di `/etc/network/interfaces`), seluruh perintah `sysctl` dan `iptables` disisipkan sebagai baris `up` pada interface `eth0` di file `/etc/network/interfaces` router Lain:
```bash
auto eth0
iface eth0 inet dhcp
    up sysctl -w net.ipv4.ip_forward=1
    up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    up iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
    up iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
    up iptables -A FORWARD -i eth3 -o eth0 -j ACCEPT
```

Dengan cara ini, setiap kali interface `eth0` diaktifkan (`ifup`, termasuk otomatis saat boot), seluruh rule `ip_forward` dan `iptables` ikut dijalankan ulang tanpa perlu diketik manual.

Script verifikasi `/root/cek_status.sh` dibuat untuk menampilkan ringkasan interface dan tabel NAT:
```bash
cat > /root/cek_status.sh << 'EOF'
#!/bin/bash
echo "===== RINGKASAN INTERFACE ====="
ip -br a
echo ""
echo "===== TABEL NAT IPTABLES ====="
iptables -t nat -L -v -n
EOF
chmod +x /root/cek_status.sh
```

Setelah node Lain di-restart (Stop lalu Start dari GNS3) untuk mensimulasikan kondisi restart tiba-tiba, script dijalankan kembali dan hasilnya membuktikan seluruh interface serta rule NAT tetap ada tanpa konfigurasi ulang manual:

![cek-status-lain](<assets/cek-status-lain.png>)

Sebagai pembuktian tambahan bahwa NAT benar-benar memproses traffic (bukan hanya rule kosong), dilakukan kembali ping dari client Alice ke `8.8.8.8` (lihat screenshot pada poin 4), lalu counter pada rule `MASQUERADE` diperiksa kembali dan terbukti bertambah dari `0 packets, 0 bytes` menjadi `1 packets, 84 bytes`:

![cek-status-lain-after-ping](<assets/cek-status-lain-after-ping.png>)

Catatan: counter hanya bertambah 1 meskipun `ping -c 3` mengirim 3 paket ICMP, karena `iptables`/`netfilter` menggunakan connection tracking — keputusan NAT hanya dievaluasi sekali di awal sebuah flow/koneksi (paket pertama), sedangkan paket berikutnya dalam flow ICMP yang sama langsung memakai entry translasi yang sudah tercatat di conntrack table.

6. Mika mencurigai adanya anomali traffic pada segmen jaringannya. Jalankan generator traffic yang disediakan pada node Mika, lalu lakukan packet sniffing menggunakan Wireshark dengan filter khusus untuk protokol DNS atau ICMP.

Capture dijalankan pada link Switch1–Mika (klik kanan link → Start capture), lalu file generator traffic dijalankan pada node Mika. Display filter `dns or icmp` diterapkan untuk menyaring paket yang relevan:

![capture-wireshark-mika](<assets/capture-wireshark-mika.png>)

Dari hasil filter terlihat:
- Paket ICMP: Echo Request/Reply antara Mika (`192.213.1.3`) dengan `1.1.1.1` dan `8.8.8.8`, termasuk hasil resolusi domain seperti `103.94.189.5` (IP dari `its.ac.id`).
- Paket DNS: standard query untuk beberapa domain — `its.ac.id` (A & AAAA), `example.com`, `github.com`, `google.com`, `cloudflare.com` — beserta response-nya masing-masing.

Ringkasan traffic dikonfirmasi lewat Statistics → Conversations, yang menunjukkan Mika bertukar 16 paket dengan `1.1.1.1`, 26 paket dengan `8.8.8.8`, dan 6 paket (588 bytes) dengan `103.94.189.5`:

![conversations-summary-mika](<assets/conversations-summary-mika.png>)

7. Chisa memutuskan mendirikan FTP Server pada node miliknya dengan shared folder di `/var/wired/data`. Terapkan kebijakan akses: user alice (read & write), user mika (read-only), dan user eiri (blacklist, tanpa akses).

Karena node Chisa menggunakan image `ardhptr21/alpinet:latest` (berbasis Alpine Linux), instalasi paket memakai `apk`, bukan `apt`:
```bash
apk update && apk add vsftpd
mkdir -p /var/wired/data
adduser alice
adduser mika
adduser eiri
```

![installed-vsftpd-chisa](<assets/installed-vsftpd-chisa.png>)

Konfigurasi diterapkan pada `/etc/vsftpd/vsftpd.conf` (lokasi default vsftpd di Alpine):
```bash
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES

local_root=/var/wired/data

chroot_local_user=YES
allow_writeable_chroot=YES

pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30100
pasv_promiscuous=YES

userlist_enable=YES
userlist_deny=NO
userlist_file=/etc/vsftpd/user_list

user_config_dir=/etc/vsftpd/user_conf

local_umask=022
seccomp_sandbox=NO
```

`userlist_deny=NO` dikombinasikan dengan `userlist_file` berisi hanya `alice` dan `mika` (tanpa `eiri`) berfungsi sebagai whitelist, sehingga `eiri` otomatis ditolak saat login:
```bash
echo -e "alice\nmika" > /etc/vsftpd.userlist
```

Pembatasan read-only untuk `mika` diterapkan lewat per-user override config:
```bash
mkdir -p /etc/vsftpd/user_conf
echo "write_enable=YES" > /etc/vsftpd/user_conf/alice
echo "write_enable=NO"  > /etc/vsftpd/user_conf/mika
```

Service dijalankan di background dan dipastikan sudah listen pada port 21:
```bash
vsftpd /etc/vsftpd/vsftpd.conf &
netstat -tlpn | grep 21
```

![chisa-ftp-running-ok](<assets/chisa-ftp-running-ok.png>)

Bukti user `alice` bisa read & write — membuat file `signal_alice.txt` lalu upload:

![proof-alice-ftp-readwrite](<assets/proof-alice-ftp-readwrite.png>)

Bukti user `eiri` ditolak login (blacklist) — server langsung membalas `530 Permission denied` sebelum sempat autentikasi lebih lanjut:

![proof-eiri-ftp-denied](<assets/proof-eiri-ftp-denied.png>)

8. Kelompok rahasia Knights mengirimkan dokumen laporan intelijen ke FTP Server Chisa menggunakan akun alice. Analisis sesi Wireshark: perintah STOR, kode status 226, dan port data PASV.

Capture dijalankan pada link Switch2–Chisa, kemudian dari node Knights dibuat file `laporan_intelijen.txt` dan diunggah menggunakan akun `alice`:
```bash
echo "Dokumen Intelijen Konfidensial" > laporan_intelijen.txt
lftp -u alice 192.213.2.2
put laporan_intelijen.txt
```

![knights-ftp-upload](<assets/knights-ftp-upload.png>)

Pada capture Wireshark dengan filter `ftp or ftp-data`, ditemukan:

![capture-knights-ftp](<assets/capture-knights-ftp.png>)

| Temuan | Nilai |
| :---: | :---: |
| Perintah upload | `STOR laporan_intelijen.txt` |
| Kode status sukses | `226 Transfer complete` |
| Response PASV | `227 Entering Passive Mode (192,213,2,2,117,66)` |
| Port data yang dinegosiasikan | `117 × 256 + 66 = 30018` (sesuai rentang `pasv_min_port`–`pasv_max_port` yang dikonfigurasi) |

9. Mika mengunduh dokumen Protokol Tujuh menggunakan akun mika, lalu buktikan pembatasan read-only saat mencoba upload (error 550).

File `protokol_tujuh.doc` terlebih dulu disiapkan di server Chisa:
```bash
echo "Isi Dokumen Protokol Tujuh" > /var/wired/data/protokol_tujuh.doc
chmod 644 /var/wired/data/protokol_tujuh.doc
```

![prepare-protokol-tujuh](<assets/prepare-protokol-tujuh.png>)

Dari node Mika, file diunduh menggunakan akun `mika` (berhasil), lalu dicoba upload file baru (harus gagal):
```bash
lftp -u mika 192.213.2.2
get protokol_tujuh.doc
put file_baru.txt
```

![mika-ftp-download](<assets/mika-ftp-download.png>)

![proof-mika-ftp-readonly](<assets/proof-mika-ftp-readonly.png>)

Server membalas dengan `550 Permission denied` saat `mika` mencoba mengirim `STOR`/`put`, membuktikan pembatasan read-only berhasil diterapkan sesuai konfigurasi `write_enable=NO` pada `/etc/vsftpd/user_conf/mika`.

10. Knights mengirimkan ping ke Chisa dengan payload 128 bytes, interval 0.3 detik, sebanyak 77 paket.
```bash
ping -c 77 -s 128 -i 0.3 192.213.2.2
```

![ping-stress-from-knights](<assets/ping-stress-from-knights.png>)

Capture pada link Switch2–Chisa dengan filter `icmp` menunjukkan pasangan Echo Request/Reply untuk setiap sequence, dengan panjang frame 170 bytes (14 byte Ethernet + 20 byte IP + 8 byte ICMP header + 128 byte payload):

![capture-ping-stress](<assets/capture-ping-stress.png>)

| Item | Hasil |
| :---: | :---: |
| ICMP Type/Code Request | Type 8, Code 0 (Echo Request) |
| ICMP Type/Code Reply | Type 0, Code 0 (Echo Reply) |
| Packet loss | 0% (77 paket terkirim, 77 diterima) |
| RTT min/avg/max/mdev | 0.458 / 0.601 / 1.201 / 0.143 ms |

11. Buat akun `phantom_user` dengan password `wired_ghost` pada telnetd di Chisa, login dari Eiri, capture di Wireshark, tunjukkan kredensial plaintext via Follow TCP Stream.

Karena node Chisa berbasis Alpine, `telnetd` sudah tersedia bawaan BusyBox — cukup dibuat akunnya:
```bash
adduser -D phantom_user
echo "phantom_user:wired_ghost" | chpasswd
```

![setup-phantom-user-chisa](<assets/setup-phantom-user-chisa.png>)

Dari node Eiri, dilakukan koneksi telnet dan login menggunakan akun tersebut:
```bash
telnet 192.213.2.2
```

![eiri-telnet-chisa](<assets/eiri-telnet-chisa.png>)

Login berhasil (`Welcome to Alpine!`) dan sesi interaktif berjalan normal (`whoami`, `ls`, `exit`):

![eiri-telnet-session](<assets/eiri-telnet-session.png>)

Pada capture Wireshark di link Switch2–Chisa, filter `telnet` menunjukkan puluhan paket berukuran kecil (2, 7, 15, 25, 27, 34 bytes data) yang masing-masing membawa 1–beberapa karakter saja — pola inilah yang membuktikan mode character-at-a-time. Klik kanan salah satu paket → Follow → TCP Stream menampilkan isi sesi secara plaintext:

![follow stream telnet creds](<assets/follow-stream-telnet-creds.png>)

Setiap karakter yang diketik terkirim sebagai paket TCP terpisah karena Telnet secara default berjalan dalam mode character-at-a-time: tiap tombol langsung dikirim ke server agar server dapat melakukan echo balik secara real-time, bukan dikumpulkan dulu menjadi satu baris sebelum dikirim.

Pada Follow TCP Stream yang benar (diambil sejak awal koneksi), terlihat jelas:
- Prompt `Chisa login`: diikuti karakter demi karakter `phantom_user` (ditandai warna merah, dikirim dari sisi client)
- Prompt `Password`: diikuti karakter demi karakter `wired_ghost`, juga terkirim polos tanpa masking di level paket TCP sekalipun terminal menyembunyikannya secara visual
- Respons server `Welcome to Alpine!` menandakan autentikasi berhasil

Ini membuktikan kelemahan fundamental Telnet: tidak ada enkripsi sama sekali, sehingga siapa pun yang bisa melakukan sniffing di jalur jaringan (seperti Eiri melakukan MITM atau siapa pun dengan akses ke link yang sama) dapat membaca username dan password korban secara langsung.

12. Alice memindai port Knights: 22 (SSH) dan 80 (HTTP) harus terbuka, 7777 harus tertutup. Analisis perbedaan TCP flag SYN-ACK vs RST-ACK.
```bash
nc -zv 192.213.3.2 22
nc -zv 192.213.3.2 80
nc -zv 192.213.3.2 7777
```

![alice nc to knights](<assets/alice-nc-to-knights.png>)

Hasilnya: port `22` dan `80` succeeded, sedangkan port `7777` connection refused. Capture Wireshark pada link Switch3–Knights dengan filter `tcp.port==22 or tcp.port==80 or tcp.port==7777` mengonfirmasi hal ini pada level paket:

![capture portscan alice knights](<assets/capture-portscan-alice-knights.png>)

| Port | Status | TCP Flag Response |
| :---: | :---: | :---: |
| 22 | Open | `SYN` dibalas `SYN, ACK` — bahkan sempat terlihat banner `SSH-2.0-OpenSSH_10.2` sebelum koneksi ditutup |
| 80 | Open | `SYN` dibalas `SYN, ACK`, lalu ditutup normal dengan `FIN, ACK` dari kedua sisi |
| 7777 | Closed | `SYN` langsung dibalas `RST, ACK` — tidak ada proses yang listen di port tersebut |

13. Install OpenSSH di Knights, buat key di Mika untuk user mika_admin, konfigurasi `PasswordAuthentication no`, koneksi SSH, dan jelaskan mengapa kredensial tidak terlihat plaintext.

Di Knights (server), OpenSSH diinstal lewat `apk`, lalu dibuat user `mika_admin` dan `PasswordAuthentication` dinonaktifkan:
```bash
apk add --no-cache openssh
ssh-keygen -A
adduser -D mika_admin
echo "mika_admin:mika123" | chpasswd
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
pkill sshd || true
/usr/sbin/sshd
```

![install ssh knights](<assets/install-ssh-knights.png>)

Di Mika (client), dipasang `openssh-client`, dibuat user lokal `mika_admin`, lalu digenerate SSH key pair:
```bash
apk add --no-cache openssh-client
adduser -D mika_admin
su - mika_admin
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```

![mika ssh keygen](<assets/mika-ssh-keygen.png>)

Public key didistribusikan ke Knights memakai   `ssh-copy-id` (atau cara manual `cat pubkey | ssh ... "cat >> authorized_keys"` sebagai alternatif):
```bash
ssh-copy-id mika_admin@192.213.3.2
ssh mika_admin@192.213.3.2
```

![mika ssh to knights](<assets/mika-ssh-to-knights.png>)

Login berhasil langsung tanpa diminta password (`Welcome to Alpine!`), membuktikan autentikasi berbasis public-key berjalan.

Capture Wireshark pada link Switch3–Knights dengan filter `ssh or tcp.port==22`:

![capture ssh handshake](<assets/capture-ssh-handshake.png>)

Ditemukan tahapan berikut secara berurutan:

| Tahap | Isi Paket |
| :---: | :---: |
| Protocol Version Exchange | `Client: Protocol (SSH-2.0-OpenSSH_10.2)` dan `Server: Protocol (SSH-2.0-OpenSSH_10.2)` — masih plaintext |
| Key Exchange Init | `Client: Key Exchange Init` & `Server: Key Exchange Init`, dilanjutkan `PQ/T Hybrid Key Exchange Init/Reply` dan `New Keys` |
| Setelah Key Exchange | Seluruh paket berikutnya berlabel `Encrypted packet (len=...)`, termasuk proses autentikasi public-key dan seluruh sesi shell |

Pada capture Wireshark ditemukan paket Protocol Version Exchange (string `SSH-2.0-OpenSSH_10.2` yang dipertukarkan plaintext) dan Key Exchange Init (negosiasi algoritma key exchange/cipher/MAC, termasuk skema PQ/T Hybrid pada versi OpenSSH terbaru). Kredensial tidak terlihat plaintext seperti pada Telnet karena setelah proses key exchange selesai (ditandai pesan `New Keys`), seluruh sesi — termasuk proses autentikasi public-key dan seluruh input/output shell — dienkripsi end-to-end menggunakan kunci sesi yang telah disepakati kedua pihak.