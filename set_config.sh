#!/bin/bash

# senderのルーティング設定
docker exec -d sender route add -net 172.20.0.0 netmask 255.255.0.0 gw 172.19.0.2 eth0

# receiverのルーティング設定
docker exec -d receiver route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.20.0.2 eth0

echo "set routing."