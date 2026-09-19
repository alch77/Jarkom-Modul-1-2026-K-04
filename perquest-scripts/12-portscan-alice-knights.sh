#!/bin/bash
 
# ==== NODE KNIGHTS (Target port scan) ====
nohup sh -c "nc -lvkp 22 & nc -lvkp 80 &" > /tmp/test.out 2>&1 &

# ==== NODE ALICE (Penyerang/scanner) ====
nc -vz 192.213.3.2 22
nc -vz 192.213.3.2 80
nc -vz 192.213.3.2 7777
