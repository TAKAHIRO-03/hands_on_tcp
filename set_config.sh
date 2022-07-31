#!/bin/bash

# senderのルーティング設定
docker exec -it "$(docker ps -a | grep sender | awk '{print $1}')" route add -net 172.20.0.0 netmask 255.255.0.0 gw 172.19.0.3 eth0
docker exec -it "$(docker ps -a | grep sender | awk '{print $1}')" route add -net 172.21.0.0 netmask 255.255.0.0 gw 172.19.0.3 eth0

# reverse_proxyのルーティング設定
docker exec -it "$(docker ps -a | grep reverse_proxy | awk '{print $1}')" route add -net 172.21.0.0 netmask 255.255.0.0 gw 172.20.0.3 eth0
docker exec -it "$(docker ps -a | grep reverse_proxy | awk '{print $1}')" route add -net 172.21.0.0 netmask 255.255.0.0 gw 172.20.0.4 eth0

# proxy1のルーティング設定
docker exec -it "$(docker ps -a | grep proxy1 | awk '{print $1}')" route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.20.0.2 eth0

# proxy2のルーティング設定
docker exec -it "$(docker ps -a | grep proxy2 | awk '{print $1}')" route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.20.0.2 eth0

# reciverのルーティング設定
docker exec -it "$(docker ps -a | grep receiver | awk '{print $1}')" route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.21.0.3 eth0
docker exec -it "$(docker ps -a | grep receiver | awk '{print $1}')" route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.21.0.4 eth0

echo "set routing."

# proxy1のポートフォワード設定
docker exec -it "$(docker ps -a | grep proxy1 | awk '{print $1}')" iptables -t nat -A PREROUTING -p tcp --dport 10080 -j DNAT --to-destination 172.21.0.2:10080
docker exec -it "$(docker ps -a | grep proxy1 | awk '{print $1}')" iptables -t nat -A POSTROUTING -p tcp -d 172.21.0.2 --dport 10080 -j MASQUERADE
docker exec -it "$(docker ps -a | grep proxy1 | awk '{print $1}')" iptables -A FORWARD -p tcp -d 172.21.0.2 --dport 10080 -j ACCEPT
# docker exec -it "$(docker ps -a | grep proxy1 | awk '{print $1}')" iptables -t nat -A OUTPUT -p tcp --dport 10080 -j DNAT --to-destination 172.21.0.2:10080

# proxy2のポートフォワード設定
docker exec -it "$(docker ps -a | grep proxy2 | awk '{print $1}')" iptables -t nat -A PREROUTING -p tcp --dport 10080 -j DNAT --to-destination 172.21.0.2:10080
docker exec -it "$(docker ps -a | grep proxy2 | awk '{print $1}')" iptables -t nat -A POSTROUTING -p tcp -d 172.21.0.2 --dport 10080 -j MASQUERADE
docker exec -it "$(docker ps -a | grep proxy2 | awk '{print $1}')" iptables -A FORWARD -p tcp -d 172.21.0.2 --dport 10080 -j ACCEPT
# docker exec -it "$(docker ps -a | grep proxy2 | awk '{print $1}')" iptables -t nat -A OUTPUT -p tcp --dport 10080 -j DNAT --to-destination 172.21.0.2:10080

echo "set proxy1 and proxy2 port forward."

echo "sucess."