#!/bin/bash

# ==== NODE CHISA (Server FTP) ====
cd /var/wired/data
wget -O protocol7_manifesto.zip "https://drive.google.com/drive/folders/1S3hG0dnZBTkCta4uILWwKVc6dSYYGRJ6?usp=sharing"
sed -i 's/write_enable=YES/write_enable=NO/' /etc/vsftpd/user_conf/mika
vsftpd /etc/vsftpd/vsftpd.conf &

# ==== NODE MIKA (Client) ====
echo "Mencoba upload file baru" > file_baru.txt
lftp mika@192.213.2.2
# > put file_baru.txt
# > get protocol7_manifesto.zip
# > bye
