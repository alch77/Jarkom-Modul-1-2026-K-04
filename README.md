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

**Revisi**    
9. Mika mengunduh dokumen Protokol Tujuh menggunakan akun mika, lalu buktikan pembatasan read-only saat mencoba upload (error 550).

File yang akan diunduh Mika diambil langsung dari link Google Drive yang disediakan pada soal, lalu diletakkan di shared folder FTP:
```bash
# di Chisa
cd /var/wired/data
wget -O protocol7_manifesto.zip "https://drive.google.com/drive/folders/1S3hG0dnZBTkCta4uILWwKVc6dSYYGRJ6?usp=sharing"
```

![download protocol7 manifesto](<assets/download-protocol7-manifesto.png>)

File berhasil diunduh (303.131 bytes / ~296 KB). Service `vsftpd` kemudian di-restart agar shared folder ter-refresh:
```bash
vsftpd /etc/vsftpd/vsftpd.conf &
```

![chisa ftp restart](<assets/chisa-ftp-restart.png>)

Dari node Mika, file diunduh menggunakan akun `mika` (harus berhasil karena masih diizinkan read), lalu dicoba upload file baru (harus gagal karena write-only ditolak):
```bash
echo "Mencoba upload file baru" > file_baru.txt
lftp mika@192.213.2.2
put file_baru.txt
get protocol7_manifesto.zip
bye
```

![mika ftp readonly test](<assets/mika-ftp-readonly-test.png>)

Hasilnya persis sesuai kebijakan yang diterapkan di poin 7:
- `put file_baru.txt` → ditolak dengan `550 Permission denied` (write_enable=NO untuk user mika)
- `get protocol7_manifesto.zip` → berhasil, 303131 bytes transferred (read masih diizinkan)

Ini membuktikan pembatasan read-only untuk user `mika` berhasil diterapkan sesuai konfigurasi `write_enable=NO` pada `/etc/vsftpd/user_conf/mika`, tanpa memengaruhi hak baca (`get`) yang tetap berfungsi normal.

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

**Revisi**
11. Buat akun `phantom_user` / `wired_ghost` pada telnetd di Chisa, login dari Eiri, capture di Wireshark, tunjukkan kredensial plaintext via Follow TCP Stream.

Karena node Chisa berbasis Alpine, `telnetd` sudah tersedia bawaan BusyBox — cukup dibuat akunnya:
```bash
# di Chisa
adduser -D phantom_user
echo "phantom_user:wired_ghost" | chpasswd
```

![setup-phantom-user-chisa](<assets/setup-phantom-user-chisa.png>)

Dari node Eiri, dilakukan koneksi telnet dan login menggunakan akun tersebut:
```bash
# di Eiri
telnet 192.213.2.2
```

![eiri-telnet-chisa](<assets/eiri-telnet-chisa.png>)

Login berhasil (`Welcome to Alpine!`) dan sesi interaktif berjalan normal (`whoami`, `ls`, `exit`):

![eiri-telnet-session](<assets/eiri-telnet-session.png>)

Pada capture Wireshark di link Switch2–Chisa, filter `telnet` menunjukkan puluhan paket berukuran kecil (2, 7, 15, 25, 27, 34 bytes data) yang masing-masing membawa 1–beberapa karakter saja — pola inilah yang membuktikan mode character-at-a-time. Klik kanan salah satu paket → Follow → TCP Stream menampilkan isi sesi secara plaintext:

![follow stream telnet creds](<assets/follow-stream-telnet-creds.png>)

Bukti tambahan tanpa filter (packet list mentah) memperlihatkan pola bolak-balik `192.213.3.3 → 192.213.2.2` dan sebaliknya, dengan panjang data 1 byte untuk hampir setiap paket di awal sesi (fase pengetikan username/password karakter-per-karakter), baru bertambah jadi beberapa byte sekaligus (2, 8, 13, 14 bytes) saat sistem mengirim balasan echo/prompt yang lebih panjang:

![capture telnet raw packets](<assets/capture-telnet-raw-packets.png>)

Setiap karakter yang diketik terkirim sebagai paket TCP terpisah karena Telnet secara default berjalan dalam mode character-at-a-time: tiap tombol langsung dikirim ke server agar server dapat melakukan echo balik secara real-time, bukan dikumpulkan dulu menjadi satu baris sebelum dikirim.

Pada Follow TCP Stream yang benar (diambil sejak awal koneksi), terlihat jelas:
- Prompt `Chisa login`: diikuti karakter demi karakter `phantom_user` (ditandai warna merah, dikirim dari sisi client)
- Prompt `Password`: diikuti karakter demi karakter `wired_ghost`, juga terkirim polos tanpa masking di level paket TCP sekalipun terminal menyembunyikannya secara visual
- Respons server `Welcome to Alpine!` menandakan autentikasi berhasil

Ini membuktikan kelemahan fundamental Telnet: tidak ada enkripsi sama sekali, sehingga siapa pun yang bisa melakukan sniffing di jalur jaringan (seperti Eiri melakukan MITM atau siapa pun dengan akses ke link yang sama) dapat membaca username dan password korban secara langsung.

**Revisi**
12. Alice memindai port Knights: 22 (SSH) dan 80 (HTTP) harus terbuka, 7777 harus tertutup. Analisis perbedaan TCP flag SYN-ACK vs RST-ACK.

Di Knights, port 22 sudah otomatis terbuka karena `sshd` asli (dari setup poin 13) sedang berjalan di sana. Untuk port 80, cukup dibuka listener sederhana pakai `nc`, sementara port 7777 sengaja dibiarkan tertutup:
```bash
# di Knights
nohup sh -c "nc -lvkp 22 & nc -lvkp 80 &" > /tmp/test.out 2>&1 &
```

![setup nc listener knights](<assets/setup-nc-listener-knights.png>)

Catatan: karena `sshd` sudah lebih dulu memegang port 22, `nc -lvkp 22` di atas sebenarnya gagal bind (port sudah dipakai) dan yang menjawab scan di port 22 tetap `sshd` asli — inilah kenapa nanti muncul banner asli `SSH-2.0-OpenSSH_10.2` di hasil capture, bukan sekadar listener kosong.

Dari node Alice, port 22, 80, dan 7777 di-scan:
```bash
# di Alice
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

**Revisi**
13. Install OpenSSH di Knights, buat key di Mika untuk user mika_admin, konfigurasi `PasswordAuthentication no`, koneksi SSH, dan jelaskan mengapa kredensial tidak terlihat plaintext.

Di Knights (server), OpenSSH diinstal lewat `apk`, lalu dibuat user `mika_admin`. `PasswordAuthentication` sengaja dibiarkan `yes` dulu agar proses penyalinan public key dari Mika bisa berjalan (baru dinonaktifkan setelah key terpasang):
```bash
# di Knights
apk add --no-cache openssh
ssh-keygen -A
adduser -D mika_admin
echo "mika_admin:mika123" | chpasswd

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
/usr/sbin/sshd
```

![install ssh knights](<assets/install-ssh-knights.png>)

Di Mika (client), dipasang `openssh-client`, dibuat user lokal `mika_admin`, lalu digenerate SSH key pair:
```bash
# di Mika
apk add --no-cache openssh-client
adduser -D mika_admin
su - mika_admin
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```

![mika ssh keygen](<assets/mika-ssh-keygen.png>)

Public key didistribusikan ke Knights memakai `ssh-copy-id` (berhasil setelah `PasswordAuthentication` diizinkan sementara di atas — sempat gagal sebelumnya karena bug `ssh-copy-id` di lingkungan Alpine/BusyBox saat `PasswordAuthentication` sudah `no` duluan):
```bash
ssh-copy-id mika_admin@192.213.3.2
# password diminta SEKALI di sini: mika123
ssh mika_admin@192.213.3.2
```

![mika ssh copyid success](<assets/mika-ssh-copyid-success.png>)

Login berhasil langsung tanpa diminta password (`Welcome to Alpine!`), membuktikan autentikasi berbasis public-key berjalan — SSH client secara otomatis mencoba metode public-key terlebih dahulu sebelum jatuh ke password, dan karena key sudah cocok, password tidak pernah diminta.

Untuk penyelesaian akhir sesuai soal (memastikan hanya public-key yang diterima), setelah key terbukti berfungsi, `PasswordAuthentication` di Knights dikembalikan ke `no` dan `sshd` di-restart:
```bash
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
pkill sshd && /usr/sbin/sshd
```

Capture Wireshark pada link Switch3–Knights dengan filter `ssh or tcp.port==22`:

![capture ssh handshake](<assets/capture-ssh-handshake.png>)

Ditemukan tahapan berikut secara berurutan:

| Tahap | Isi Paket |
| :---: | :---: |
| Protocol Version Exchange | `Client: Protocol (SSH-2.0-OpenSSH_10.2)` dan `Server: Protocol (SSH-2.0-OpenSSH_10.2)` — masih plaintext |
| Key Exchange Init | `Client: Key Exchange Init` & `Server: Key Exchange Init`, dilanjutkan `PQ/T Hybrid Key Exchange Init/Reply` dan `New Keys` |
| Setelah Key Exchange | Seluruh paket berikutnya berlabel `Encrypted packet (len=...)`, termasuk proses autentikasi public-key dan seluruh sesi shell |

Pada capture Wireshark ditemukan paket Protocol Version Exchange (string `SSH-2.0-OpenSSH_10.2` yang dipertukarkan plaintext) dan Key Exchange Init (negosiasi algoritma key exchange/cipher/MAC, termasuk skema PQ/T Hybrid pada versi OpenSSH terbaru). Kredensial tidak terlihat plaintext seperti pada Telnet karena setelah proses key exchange selesai (ditandai pesan `New Keys`), seluruh sesi — termasuk proses autentikasi public-key dan seluruh input/output shell — dienkripsi end-to-end menggunakan kunci sesi yang telah disepakati kedua pihak.

# Laporan Nomor 14-20 

Bagian ini berisi analisis file capture (.pcap) untuk mencari jejak serangan yang dilakukan Eiri di dalam jaringan The Wired. Setiap nomor punya file capture sendiri, dan jawabannya divalidasi lewat socket server yang disediakan asisten.

## Nomor 14 - Brute Force ke Web Login

File yang dianalisis: `soal14_wired_bruteforce.pcapng`

Di Wireshark, file ini dibuka lalu diberi filter `http.request.method == "POST"`. Filter ini dipakai supaya cuma kelihatan paket yang isinya percobaan login (POST ke `/login.php`). Ternyata paket ini muncul berulang-ulang ratusan kali, semua dari IP yang sama menuju IP yang sama - ini tandanya ada serangan brute force (coba password berkali-kali sampai berhasil).

![capture-bruteforce-post](<assets/capture-bruteforce-post.png>)

Dari situ ketahuan IP penyerangnya `172.26.7.50`, menyerang ke `172.26.7.100` di port `8080` (port ini dilihat dengan klik salah satu paket, lalu buka bagian TCP-nya).

Untuk cari percobaan yang berhasil, dicari paket yang response-nya beda dari yang lain (kebanyakan gagal), lalu diklik kanan pilih **Follow > HTTP Stream** biar bisa baca isi percakapannya secara lengkap.

![follow-stream-bruteforce-success](<assets/follow-stream-bruteforce-success.png>)

Dari situ kelihatan password yang berhasil dipakai adalah `wired_pr0tocol_7` untuk user `lain_admin`, dan server yang dipakai adalah `Apache/2.4.62` (tertulis di bagian header response-nya).

**Dapat disimpulkan**
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

Setiap tombol yang ditekan itu terekam sebagai kode angka (bukan huruf langsung), jadi harus dicocokkan satu-satu pakai tabel kode keyboard USB (namanya tabel HID Usage ID).

![capdata-usb-hid](<assets/capdata-usb-hid.png>)

Setelah semua kode angka itu dicocokkan jadi huruf, ketemu pesan rahasianya: `Wired_Protocol_7_is_alive_2026`

**Dapat disimpulkan**
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

**Dapat disimpulkan**
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

**Dapat disimpulkan**
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

**Dapat disimpulkan**
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
![nc-validasi-soal18](<assets/nc-validasi-soal182.png>)


Hasilnya benar dan dapat flag: `KOMJAR26{SMB_Tr4nsf3r_sprNhRiD8FIjzaRrvnlrXkNL0}`

## Nomor 19 - Email Ancaman/Pemerasan

File yang dianalisis: `soal19_wired_smtp_threat.pcapng`

Di file ini ada beberapa email yang lewat, tapi yang dicari adalah email dari alamat aneh `185.234.72.19` menuju server email `203.0.113.100`. Diklik kanan salah satu paketnya lalu pilih **Follow > TCP Stream** buat baca isi emailnya secara lengkap.

![follow-stream-smtp-threat](<assets/follow-stream-smtp-threat.png>)

Isi emailnya ternyata ancaman/pemerasan dari Eiri, ditujukan ke `victim@protocol7.co.jp`. Di dalam isi emailnya disebutkan password yang diklaim bocor, jenis malware yang katanya sudah disebar, batas waktu yang diberikan, dan kode ID pengirim.

**Dapat disimpulkan**
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

**Dapat disimpulkan**
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
