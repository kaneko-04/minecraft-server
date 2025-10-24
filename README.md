# Minecraftサーバー構築記録


## 概要
身内向けMinecraftサーバーをDebian環境で構築した際の記録。
安定したマルチプレイ環境の実現を目的に、Cloudflareによるドメイン管理、HAProxyによるリバースプロキシ構成、iptablesとFail2Banによるアクセス制御を組み合わせた堅牢なネットワーク設計を行った。  
小規模ながら実運用を通して、セキュリティと可用性の両立を実践的に学んだ。


## 使用技術
- **OS / セキュリティ**: Debian, UFW, iptables, Fail2Ban  
- **ネットワーク / プロキシ**: HAProxy, Velocity (Minecraft Proxy Server)  
- **DNS / ドメイン運用**: Cloudflare DNS  
- **アプリケーション環境**: Java (JDK), Minecraft Server (Fabric)  

## システム構成
```
クライアント
   ↓
[Cloudflare DNS] — (A/SRVレコード)
   ↓
[HAProxy]
   ↓
[Fail2Ban + iptables]
   ↓
[Velocity Proxy]
   ↓
[Minecraft Server (Fabric)]
```

## 実施した主な設定

### 1.セキュリティ設定
- **必要最小限のポート開放**
  - 外部接続用にリバースプロキシ（HAProxy）を介する25577番ポートのみ公開
  - 上記以外のポートは全てファイアウォール(UFW)で遮断
  - サーバー内部でのプロセス間通信（Velocity ⇔ Minecraft）は内部ポートで安全に行われる構成
  - SSHはローカルネットワークからの接続のみに限定
- **Fail2Banによる侵入防止**
  - Velocityログを監視し、短時間で一定回数の接続失敗を検出すると自動でBANする仕組みを導入
  - iptablesと連携し、指定時間アクセスを拒否
  - 総当たり攻撃やボットによる不正接続を12時間遮断できるように設定
- **国外IPアドレスからのアクセス遮断**
  - iptablesのカスタムチェーン `DROP_EXCEPT_JP` をを参考にHAProxyとの連携機能を追加
  - 日本国内のIPレンジのみ許可し、それ以外をドロップ
  - 不正アクセス対策として実装
  - **参考元**: https://pcvogel.sarakura.net/2020/09/09/32067

### 2.ネットワーク設定
- **リバースプロキシ（HAProxy）の導入**
  - 通信を一度HAProxyで受け取り、内部のVelocityサーバーへ転送する構成を採用
  - これにより、Minecraftサーバーの実IPを外部に公開せず、接続経路を制御可能
  - また、将来的な複数サーバー運用を見越し、負荷分散や接続ルーティングの基盤を先行して整備
  - TCPモードでのプロキシ運用によって、Minecraftの非HTTP通信にも対応
  - こちらにも簡易的なレート制限を設けることで、DDoSやスパムの防止
- **CloudflareによるDNS管理**
  - 独自ドメインをCloudflareで取得し、AレコードでサーバーのグローバルIPを登録
  - SRVレコードを用いてMinecraft専用ポートを指定することでクライアントはドメイン名のみで接続可能
  - Minecraftの通信、Fail2Ban、UFWの実IPの識別のため、CloudflareはDNSのみでの運用
- **内部ポート構成の明確化**
  - 外部公開ポート：25577
    - クライアントが接続するポート
    - Cloudflare経由でHAProxyが受け取り、内部サーバーに転送
  - 内部通信ポート：25596
    - HAProxyからVelocity（プロキシサーバー）へ転送されるポート
    - 外部からはアクセス不可能（UFWによる遮断）
  - Minecraftサーバーポート：25565
    - Velocityとのみ通信を行う内部専用ポート
    - こちらも外部からはアクセス不可能（UFWによる遮断）

### 3.サーバー環境構築
- **Java環境の整備**
  - OpenJDKを導入し、MinecraftサーバーおよびVelocityプロキシサーバーの動作環境を構築
  - システム環境変数を設定し、javaコマンドによる直接実行を可能に
- **MinecraftサーバーとVelocityのセットアップ**
  - modサーバーとVelocity間の通信を最適化するため、server.propertiesとvelocity.tomlの設定を調整
  - 起動スクリプトを作成し、サーバーが強制終了しても自動で再起動するよう設定
  - また、screen を用いてバックグラウンドでデタッチ可能に

## 課題と学び
- **課題1：ドメイン経由でのみアクセス制限**
  - 問題点：ドメイン経由でのみアクセスを許可し、グローバルIPによる直接アクセスを禁止したかったが未実現
  - 原因：Minecraftプロトコルの特性とDNS設定の制約により
  - 今後の対応：方法の模索
- **課題2：コンテナ化未実施**
  - 現状：直接Debian上にインストール
  - 問題点：
    - 環境の再現性が低い
    - バージョン管理が煩雑
    - 他サーバーへの移行が困難
  - 今後の改善：Dockerによるコンテナ化を検討中

## 今後の改善予定
- Dockerによるサーバー環境のコンテナ化
- 自動バックアップスクリプトの導入
- モニタリングツールの導入（Prometheus / Grafana)
- CI/CDパイプラインの構築
- ドメインのみでアクセス許可の実装

## 運用実績
- 稼働期間：必要時に起動し、プレイ時に長期稼働
- 利用者数：身内プレイヤー数名
- ダウンタウン：ほぼなし（メンテナンス時を除く）
- 安定稼働を維持

## まとめ
本プロジェクトでは、単なるMinecraftサーバー構築に留まらず、
Linux環境でのセキュリティ設計・ネットワーク構成・運用自動化の基礎を体系的に学ぶことができた。
特に、
- リバースプロキシ（HAProxy）とVelocityの連携構成
- UFW / iptables / Fail2Ban の三層防御
- Cloudflareによるドメイン運用
といった設計を通じて、実運用に耐える安全な通信基盤の構築ノウハウを得た。
今後はコンテナ技術の習得と、より高度な自動化・監視体制の構築に取り組み、小規模ながら実運用サーバーとしての完成度を高めることを目標とする。


## 使用したリソース
- 公式ドキュメント
  - [HAProxy公式ドキュメント](https://www.haproxy.com/documentation/)
  - [Cloudflareラーニングセンター](https://www.cloudflare.com/ja-jp/learning/)
  - [Fail2Ban公式Wiki](https://github.com/fail2ban/fail2ban/wiki)
  - [Velocity公式ドキュメント](https://docs.papermc.io/velocity/)
- 技術ブログ・Qiita記事
  - [Debian 系ディストリビューションで Minecraft サーバを立てるまで](https://zenn.dev/genbu/scraps/414e9277ca1b2e)
  - [DoS攻撃/DDoS攻撃からサーバーを守る方法（fail2banのススメ）](https://colo-ri.jp/develop/2016/02/fail2ban.html)
  - [【Velocity】プロキシサーバを踏んでPaperMCやFabricサーバに接続する](https://zenn.dev/kake26s/articles/811faf83271738)
  - [Nohit.cc](https://docs.nohit.cc/)
