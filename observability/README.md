# observability — Claude Code を Grafana Cloud で可視化（直接送信・Docker不要）

Claude Code の利用状況（コスト・トークン・セッション・変更行数など）を OpenTelemetry で
**Grafana Cloud に直接送信**して可視化する。ローカルに常駐プロセス（Docker / Collector）は不要。

```
Claude Code ──OTLP http/protobuf──▶ Grafana Cloud (OTLP gateway) ──▶ Mimir(メトリクス) ──▶ Grafana で可視化
 ~/.claude/settings.json の env で設定
```

## 仕組みと「接続文字列（トークン）」の置き場所

- 送信設定（エンドポイント・認証ヘッダ）は **`~/.claude/settings.json` の `env`** に書く。
- この `settings.json` は **dotfiles リポジトリの外（実体コピー）** なので、**トークンは git に入らない**。
- リポジトリには「設定を生成するスクリプト」(`set-grafana-cloud.ps1`) と
  「ダッシュボード定義」(`grafana/dashboards/claude-code-cloud.json`) だけを置く。

> `~/.claude/settings.json` は dotfiles への symlink ではなく**コピー**。dotfiles を更新しても
> 自動反映されないので、設定変更時はこのスクリプトを実行し直す。

## セットアップ

### 1. Grafana Cloud の OTLP 接続情報を取得

Grafana Cloud → **Connections → OpenTelemetry (OTLP)** で以下を控える：

- **Endpoint**（例: `https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp`）
- `Authorization: Basic <base64>` の **base64 部分**（= `<instanceID>:<アクセスポリシートークン>` を base64 化したもの）

### 2. settings.json に設定を流し込む

```powershell
pwsh -NoProfile -File set-grafana-cloud.ps1 `
  -Endpoint "https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp" `
  -AuthB64  "<Basic の後ろの base64>"
```

`-InstanceId` と `-Token` を個別に渡す／引数なしで対話入力も可（詳細はスクリプト冒頭のコメント参照）。
このスクリプトが `~/.claude/settings.json` の `env` に以下を書き込む：

| 変数 | 値 | 役割 |
|---|---|---|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` | テレメトリ有効化 |
| `OTEL_METRICS_EXPORTER` | `otlp` | OTLP で送信 |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` | **Cloud は gRPC 不可** |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | (上記 Endpoint) | 送信先 |
| `OTEL_EXPORTER_OTLP_HEADERS` | `Authorization=Basic <b64>` | Basic 認証 |
| `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` | `cumulative` | **これが無いと HTTP 400**（後述） |
| `OTEL_METRIC_EXPORT_INTERVAL` | `60000` | 送信間隔(ms) |

### 3. Claude Code を再起動

`env` は**新しいセッション起動時**に読まれる。起動して少し使うと、約60秒間隔でメトリクスが流れ始める。

### 4. ダッシュボードをインポート

Grafana Cloud → **Dashboards → New → Import** で `grafana/dashboards/claude-code-cloud.json`
を読み込む。データソースは Prometheus 系（`grafanacloud-xxx-prom`）を選ぶ。

## ハマりどころ（重要）

- **temporality（真因）**: Claude Code は一部メトリクスを **delta** で送るが、Grafana Cloud(Mimir) は
  **cumulative しか受け付けず HTTP 400 で弾く**。しかも Claude 側はエラーを**沈黙して捨てる**ため
  「設定したのにデータが来ない」になりがち。→ `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative`
  で解決（スクリプトが自動設定）。
- **メトリクス名**: Mimir はサフィックスを付ける（`claude_code_token_usage_tokens_total`,
  `claude_code_cost_usage_USD_total` など）。ダッシュボードJSONはこのクラウド名に合わせてある。
- **認証ヘッダの空白**: `Basic%20...` の `%20` は URL エンコードされた空白。SDK が decode しないと壊れる。
  スクリプトは**本物の半角スペース**で書き込む。

## 確認方法

Grafana Cloud → **Explore**（Prometheus データソース）で `claude_code_` と打つと、
入っているメトリクス名が補完される。ラベル（`type` / `model` など）もここで確認できる。

## 含まれるファイル

| パス | 役割 |
|---|---|
| `set-grafana-cloud.ps1` | `~/.claude/settings.json` に送信設定を書き込む（トークン非埋め込み・再実行安全） |
| `grafana/dashboards/claude-code-cloud.json` | クラウド用ダッシュボード定義（インポート用） |

## メモ

- トークンを共有・露出したら、Grafana Cloud の **Access Policies で revoke** する。
- ログ(Loki) / トレース(Tempo) は未導入。`OTEL_LOGS_EXPORTER=otlp` を足せば同じゲートウェイ経由で
  Loki にログも送れるが、単独利用ではノイズが多いので本構成では入れていない。
