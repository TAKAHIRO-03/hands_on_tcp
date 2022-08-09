# TCP/UDP送受信検証手順

## 日付
2022-08-10

## ホストOSにインストールする資材
* Docker
* Windows Terminal

※ 最新バージョンをお使い下さい。
※ Windows Terminal は必須ではありません。

## ベースイメージOS
* CentOS7.9.2009

## イメージインストールパッケージ
* nc
* tc
* tcpdump

※ yum install時の最新バージョンをお使い下さい。

## システム構成
写真リンク

## 事前準備

1. Dockerコンテナ起動
```
$ ~ docker-copmpose up -d
```

2. ルーティング設定
```
$ ~ docker exec -d sender route add -net 172.20.0.0 netmask 255.255.0.0 gw 172.19.0.2 eth0 
$ ~ docker exec -d receiver route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.20.0.2 eth0
```

3. データ作成
```
$ ~ docker exec -it sender bash
[root@sender ~]# fallocate -l 5G 5GB.dat # UDP向け
[root@sender ~]# fallocate -l 500MB 500MB.dat # TCP送信用
```

4. 疎通確認
```
$ ~ docker exec -it sender bash
[root@sender ~]# ping 172.20.0.3
```


## 送信端末から宛先にパケットを送信中に、通信の経路でルーターが再起動（一時的に停止）する。
　Windows Terminalで画面を4分割し、ホストOS、Senderコンテナ×2、Receiverコンテナにログインする。
```
$ ~ docker exec -it sender bash # Senderコンテナにログイン
$ ~ docker exec -it receiver bash # Receiverコンテナにログイン

[root@receiver ~]# はReceiverコンテナで操作しています。
[root@sender ~]# はSenderコンテナで操作しています。
[root@router ~]# はRouterコンテナで操作しています。
$ ~ はホストOSで操作しています。
```

### TCP
1. [root@receiver ~]# nc -lk 10080 # tcpメッセージをリッスン
2. [root@sender ~]# tcpdump -i eth0 -tttt -nn tcp port 10080 -w /root/volume/tcp.pcap # tcpdumpでTCPパケットをキャプチャ
3. [root@sender ~]# nc 172.20.0.3 10080 < 500MB.dat # TCPメッセージを送信する。
4. $ ~ docker restart router # Routerコンテナを再起動する。
5. 同ディレクトリのvolume配下にtcp.pcapが出力されるので、それをWiresharkで結果を確認
6. [root@router ~]# journalctl --list-boots # 再起動の時刻を確認

### UDP
1. [root@receiver ~]# nc -lu 10080 # tcpメッセージをリッスン
2. [root@sender ~]# tcpdump -i eth0 -tttt -nn udp port 10080 -w /root/volume/udp.pcap # tcpdumpでUDPパケットをキャプチャ
3. [root@sender ~]# nc -u 172.20.0.3 10080 < 3GB.dat # UDPメッセージを送信する。
4. $ ~ docker restart router # Routerコンテナを再起動する。
5. 同ディレクトリのvolume配下にudp.pcapが出力されるので、それをWiresharkで結果を確認
6. [root@router ~]# journalctl --list-boots # 再起動の時刻を確認



## 送信端末からパケットロスを意図的に起こし送信する。

### TCP
tc qdisc add dev enp0s3 root netem loss 10%

