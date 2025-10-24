# Minecraftサーバー構築記録
身内向けMinecraftサーバーをDebian環境で構築した際の記録です。

## 概要
- 目的: 友人とプレイするための安定したマルチプレイ環境の構築
- 構成: リバースプロキシ + ファイアウォール + カスタムドメイン

## 使用技術
- **OS / セキュリティ**: Debian, UFW, iptables, Fail2Ban  
- **ネットワーク / プロキシ**: HAProxy, Velocity (Minecraft Proxy)  
- **DNS / ドメイン運用**: Cloudflare DNS  
- **アプリケーション環境**: Java (JDK), Minecraft Server (Fabric)  

