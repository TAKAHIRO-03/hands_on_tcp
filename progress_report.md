# 成果報告書整理

## 目的
* 成果報告書の内容を整理すること向けに本資料を活用する。

## テーマ
ハンズオンで学ぶTCP

## テーマの目的
TCPの確認応答、フロー制御、順序制御、輻輳制御の振る舞いをコマンド実行を基に確認する。

## 自分自身の中ではっきりさせたいことは？
* TCPの機能を列挙したい。
  * 確認応答
  * フロー制御
  * 順序制御
  * 輻輳制御
[仕組みが一目瞭然、インターネットを支えるTCPとUDPを完全図解](https://xtech.nikkei.com/atcl/nxt/column/18/00780/052700004/)

* LinuxのTCPに関連するカーネルパラメータを列挙したい。
```
net.ipv4.tcp_rmem ★フロー制御
net.ipv4.tcp_wmem ★フロー制御
net.core.rmem_max	要検証	TCPの受信バッファサイズの最大値を設定する ★フロー制御
net.core.somaxconn	要検証	TCPソケットが受け付けた接続要求を格納するキューの最大長
net.core.wmem_max	要検証	TCPの送信バッファサイズの最大値
net.ipv4.ip_local_port_range	要検証	TCP/IPの送信用ポート範囲の変更
net.ipv4.tcp_fin_timeout	5〜30	FINパケットのタイムアウト時間
net.ipv4.tcp_keepalive_intvl	sec<75	TCP keepalive packetを送信する間隔(秒単位)
net.ipv4.tcp_keepalive_time	sec<7200	TCP keepalive packetを送信するまでの時間(秒単位)
net.ipv4.tcp_keepalive_probes	count<9	keepalive packetを送信する回数
net.ipv4.tcp_max_syn_backlog	要検証	ソケット当たりのSYNを受け付けてACKを受け取っていない状態のコネクションの保持可能数
net.ipv4.tcp_max_tw_buckets	要検証	システムが同時に保持するTIME_WAITソケットの最大数
net.ipv4.tcp_orphan_retries	要検証	こちらからクローズしたTCPコネクションを終了する前の再送回数
net.ipv4.tcp_rfc1337	1	RFC1337に準拠させる
※TIME_WAIT状態のときにRSTを受信した場合、TIME_WAIT期間の終了を待たずにそのソケットをクローズする
net.ipv4.tcp_slow_start_after_idle	0	通信がアイドル状態になった後のスロースタートを無効にする ★ 輻輳制御
net.ipv4.tcp_syn_retries	3	tcpのSYNを送信するリトライ回数 ★ 確認応答
net.ipv4.tcp_tw_reuse	1	TIME_WAIT状態のコネクションを再利用
net.ipv4.tcp_congestion_control = cubic ★ 輻輳制御
net.ipv4.tcp_autocorking = 1 ★ MSSまで溜めて送信するか否か
```
[Linuxのカーネルパラメータについて](https://qiita.com/sheep_san_white/items/28dac8865cef5ddf9816)

* システム構成を考えたい。
Senderのコンテナ、Reciverのコンテナを用意。ブリッジ接続
docker-comopseで作る

* パケットロスをどう再現するか？
ルーティング用のコンテナを作る。ルーターコンテナを停止して、パケロスを起こす。
[Dockerで経路制御によりブリッジネットワーク間で通信してみる！](https://qiita.com/BooookStore/items/5862515209a31658f88c)

* パケットの順序をどう変えるか？
MSSを小さくして、MSSに満たしていなくても送信してみる。
[【図解】MTUとMSS, パケット分割の考え方 ~IPフラグメンテーションとTCPセグメンテーション~](https://milestone-of-se.nesuke.com/nw-basic/grasp-nw/mtu-mss-fragment-segment/)
[ソケットオプションの使い方(TCP_CORK)](https://hana-shin.hatenablog.com/entry/2022/01/10/184155)

まあ最悪パケットの中身を解説すれば良い。

## ハンズオンの中身

* 確認応答
再送するところを見たい！

1. $ reciver ~ nc -kl 10080
2. $ sender ~ nc 172.20.0.3 11111
3. $ sender ~ tcpdump -i eth0 -nn tcp port 11111 and ip
4. $ sender ~ nc 172.20.0.3 11111
Hello world!
5. $ docker stop $(docker ps -a | grep router | awk '{print $1}')
再送確認
5. $ docker start $(docker ps -a | grep router | awk '{print $1}')
時間が経ってもちゃんと送信される。

* フロー制御
1GBのデータを送信する。
win（ウィンドウサイズ）に併せて送信していることが分かる。

1. nc 192.168.2.100 11111 < test.dat

* 順序制御
[tcコマンドの使い方](https://hana-shin.hatenablog.com/entry/2022/03/13/183444)

* 輻輳制御
スロースタートを無効化・有効化してからパケットを送りまくる
輻輳回避アルゴリズムを変更する。

## 便利コマンド
docker exec -it $(docker ps -a | grep sender | awk '{print $1}') bash
docker exec -it $(docker ps -a | grep receiver | awk '{print $1}') bash
docker exec -it $(docker ps -a | grep router | awk '{print $1}') bash

