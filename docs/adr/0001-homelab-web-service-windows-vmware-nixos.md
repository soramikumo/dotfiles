# ADR-0001: 自宅 Windows マシン上の VM で Web サービスを外部公開する

- **ステータス**: Accepted（デプロイフローのみ Proposed）
- **日付**: 2026-06-21
- **決定者**: soramikumo

## コンテキスト

ローカルの Windows マシンを「自宅鯖 / EC2 代わり」として、個人開発の Web サービスを
外部公開したい。SLA は不要（個人利用、ダウンタイムは許容、ただしデータ消失は不可）。
ネットワークは Cloudflare Tunnel を使う前提。Windows は今後も日常的に使う（ゲーム・作業）。
構成は git で全部入り管理したい（dotfiles スタイル）。発起人は自宅公開鯖の経験は浅い。

これらの前提のもとで、仮想化方式・OS・公開方法・運用までの設計判断を一括で記録する。

## 決定サマリ

| # | 論点 | 決定 | ステータス |
|---|------|------|-----------|
| 1 | 仮想化方式 | VMware Workstation Pro（個人無料）ホスト型。デュアルブートは却下 | Accepted |
| 2 | ゲスト OS / 構成管理 | NixOS（flake）。サービスはコンテナに載せ OS 層を薄く保つ | Accepted |
| 3 | データの状態 | ステートレス。復旧は git から再デプロイ | Accepted |
| 4 | 公開範囲 | 完全公開。アプリ側で認証/レート制限 + Cloudflare エッジ | Accepted |
| 5 | リソース割当 | ホスト 32GB → VM に RAM 4〜8GB / 2〜4 vCPU / ディスク 40〜60GB(thin) | Accepted |
| 6 | 可用性 | 自動復帰（ヘッドレス常駐）。Task Scheduler 自動起動 + systemd | Accepted |
| 7 | シークレット | sops-nix で暗号化して git 入り + cloudflared リモート管理トンネル | Accepted |
| 8 | ドメイン | Cloudflare Registrar で取得（DNS とトンネルを一箇所に） | Accepted |
| 9 | ネットワーク | Cloudflare Tunnel（named）。VMware NAT。インバウンドポート開放ゼロ | Accepted |
| 10 | LAN 隔離 | nftables egress フィルタで RFC1918 宛を drop し一方通行 DMZ 化 | Accepted |
| 11 | デプロイフロー | ベース NixOS + アプリは docker compose（将来 全Nix / CI-CD 可） | Proposed |

## 各決定の詳細

### 1. 仮想化方式 — VMware Workstation Pro ホスト型（デュアルブート却下）

Windows を日常的に使い続けるため、同時に1つの OS しか動かせないデュアルブートは不可
（Windows 起動中サーバーが落ちる）。Windows を消すベアメタル Linux も不可。
両 OS 同時稼働できるホスト型仮想化のみが要件を満たす。

VMware Workstation Pro は 2024 年以降、個人利用は無料。Player と違い**スナップショット**が
使えるため、NixOS の世代ロールバックに加えて **VM 丸ごとの巻き戻し**という二重の保険になる。

### 2. ゲスト OS / 構成管理 — NixOS（flake）+ コンテナ

宣言的かつ**アトミックなロールバック**が効く。ヘッドレス VM の設定をミスってもブート時に
前世代へ戻せる＝実質の保険。設定を dotfiles に置けば OS まで含めて git 全部入りにできる。
学習曲線は実サービスを Docker/Podman に逃がすことで OS 層を薄く保ち、緩和する
（OS 側でやるのは cloudflared / docker 有効化 / SSH / nftables 程度）。
Ansible は1台の宣言的鯖にはロールバックなし・ドリフトするため不採用。

VM ツールは `virtualisation.vmware.guest.enable`（open-vm-tools）を有効化する。

### 3. データの状態 — ステートレス

永続データを原則持たない。VM が飛んでも git から再デプロイで復旧でき、バックアップ負荷は軽い。
守るのは「git リポジトリ + 暗号化シークレット」のみ。将来 DB が要るなら外部マネージド
（Supabase/Neon 等）に逃がす。

> ⚠️ **要再訪**: ログ・アップロード・キャッシュ等の状態が後から発生したら、本 ADR の
> バックアップ方針を見直すこと。TLS は Cloudflare エッジで終端するので箱に証明書は不要。

### 4. 公開範囲 — 完全公開

世間一般に公開する。攻撃面は**アプリ本体**（Tunnel は外向きなのでポート開放ゼロ、
オリジン IP も隠れる）。アプリ側で**認証・入力検証・レート制限**を持つ前提。
Cloudflare エッジの WAF / レート制限 / Bot 対策を併用する。

> ⚠️ **Cloudflare Tunnel 規約 (§2.8)**: 無料 CDN 経由で**大きな動画/画像を配信し続けるのは NG**。
> 通常の Web/API なら問題なし。動画配信系に方針転換する場合はこの計画ごと再考する。

### 5. リソース割当 — VM に RAM 4〜8GB / 2〜4 vCPU / ディスク 40〜60GB(thin)

ホスト 32GB なので、VM に 4〜8GB 割いてもゲーム用に十分残る。ステートレス Web + cloudflared
なら 4GB でも快適。ディスクは thin provision。

### 6. 可用性 — 自動復帰（ヘッドレス常駐）

Windows の再起動（Windows Update・ゲーム）に巻き込まれても自動で戻す:

- Task Scheduler で `vmrun start <vmx> nogui` を起動時実行 → 未ログインでも VM がヘッドレス常駐
- VM 内の cloudflared / docker は systemd で自動起動（NixOS で宣言的に）
- Windows Update は「アクティブ時間」で再起動を抑制
- ホスト再起動は数十秒の瞬断で済み、no-SLA なら許容範囲
- （任意）Uptime Kuma で外形監視。軽いので後付け推奨

### 7. シークレット — sops-nix + リモート管理トンネル

NixOS 設定を公開 dotfiles リポジトリに置くため、cloudflared トークンやアプリ秘密の
**平文 commit は厳禁**。sops-nix で age 暗号化して commit し、起動時に復号。
cloudflared は**リモート管理トンネル**にして、箱に置く秘密を接続トークンだけに絞る。

### 8. ドメイン — Cloudflare Registrar で取得

named tunnel の安定 URL にはゾーンが必要。trycloudflare の使い捨て URL は本番不可。
Cloudflare Registrar は原価近くで、DNS とトンネルが一箇所にまとまる。

### 9. ネットワーク — Cloudflare Tunnel（named）+ VMware NAT

VM 側から外向きに張る named tunnel。ポート開放・固定 IP・DDNS 不要で、CGNAT 配下でも可。
VMware は NAT モードで十分（Tunnel が外向きなので Bridged 不要）。tunnel 設定は git 管理。

> ℹ️ **residential ISP 注記**: 家庭用 ISP の規約がサーバー運用を禁じる場合があるが、
> Cloudflare Tunnel は外向き・インバウンドポート開放なしのため低リスクでほぼ検知されない。

### 10. LAN 隔離 — nftables egress フィルタ（一方通行 DMZ）

完全公開アプリが侵害されると、NAT 配下の VM は自宅 LAN（Windows ホスト・他機器）へ
外向き到達できてしまう＝足がかりになる。これを塞ぐため nftables の egress フィルタで
**RFC1918（10/8・172.16/12・192.168/16）宛を drop**、インターネット + Cloudflare 宛のみ許可。
Tunnel は外向き専用なので機能的にノーコストで、VM が一方通行 DMZ になる。

### 11. デプロイフロー（Proposed）— ベース NixOS + アプリ compose

OS 層は NixOS で宣言的・安定に保ち、アプリは docker compose で `git pull && docker compose up -d`
として反復速度を確保する。発起人が未決のため**初期デフォルトの推奨**として記録。
将来、再現性を高めたければ `oci-containers` で全 NixOS 宣言へ、自動化したければ
GitHub Actions → 箱へ SSH/pull の CI-CD へ移行できる。

## 結果（Consequences）

**良い点**
- ポート開放ゼロ・オリジン IP 秘匿で、自宅公開のネットワークリスクが小さい
- NixOS 世代 + VM スナップショットの二重ロールバックで、壊しても戻せる
- ステートレス + git 全部入りで、VM 全損でも再デプロイで復旧できる
- egress フィルタで、アプリ侵害が自宅 LAN へ波及しない

**トレードオフ / 留意点**
- サーバーの稼働は Windows ホストの安定性に依存する（更新・クラッシュに巻き込まれ得る）
- NixOS / sops-nix の初期学習コストがある
- 状態が発生したらバックアップ方針の再訪が必要（#3）
- 動画/大容量メディア配信に転換する場合は Cloudflare 規約で再考が必要（#4）

## 未決・フォローアップ

- [ ] #11 デプロイフローを実運用で確定（Proposed → Accepted）
- [ ] ドメイン取得（Cloudflare Registrar）
- [ ] 状態が発生した場合のバックアップ方針（#3 の再訪トリガー）
