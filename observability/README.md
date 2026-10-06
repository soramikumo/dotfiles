# observability — Claude Code / Codex を Grafana Cloud で可視化

Claude Code と Codex の利用状況を OpenTelemetry (OTLP/HTTP protobuf) で Grafana Cloud に直接送る。
Docker や常駐 Collector は不要。

```text
Claude Code ── OTLP/HTTP ─▶ Grafana Cloud gateway ─┬─ Mimir  (metrics)
                                                  └─ Loki   (logs)
Codex ──────── OTLP/HTTP ─▶ Grafana Cloud gateway ─┬─ Loki   (logs)
                                                  └─ Tempo  (traces)
```

## 秘密情報

Grafana Cloud の Access Policy token は git に入れない。macOS では
`~/.config/secrets.env`（リポジトリ外）に次を置き、`.zprofile` / `.zshrc` から読み込む。

```sh
export GRAFANA_CLOUD_OTLP_HEADERS="Authorization=Basic <base64(instanceID:token)>"
```

`claude/settings.json` と `codex/config.toml` は追跡対象で、セットアップ時にホームへ symlink される。
秘密値をこれらの追跡ファイルへ直接書かないこと。

## Grafana Cloud の接続情報

Grafana Cloud の **Connections → OpenTelemetry (OTLP)** から以下を取得する。

- Endpoint（例: `https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp`）
- `Authorization: Basic ...` の値

Access Policy には metrics / logs / traces の write scope を付ける。

## Claude Code

現在は **無効**（`claude/settings.json` に `env` を置いていない）。再開する場合は以下を
`claude/settings.json` の `env` に追加し、認証ヘッダ `OTEL_EXPORTER_OTLP_HEADERS` は
`~/.config/secrets.env` から継承させる（追跡ファイルに秘密値を書かない）。

必要な設定:

| 変数 | 値 | 役割 |
|---|---|---|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` | telemetry を有効化 |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` | Grafana Cloud 対応 protocol |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `.../otlp` | gateway base URL |
| `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` | `cumulative` | Mimir が受理する temporality |
| `OTEL_LOGS_EXPORTER` | `otlp` | Loki へ structured logs を送信 |

Windows でローカル設定を生成する場合は既存の helper を使う。

```powershell
pwsh -NoProfile -File observability/set-grafana-cloud.ps1 `
  -Endpoint "https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp" `
  -AuthB64 "<Basic の後ろの base64>"
```

## Codex

Codex は標準の `OTEL_EXPORTER_*` 環境変数だけでは送信を開始せず、`[otel]` 設定が必要。
また現在の Codex は config 内の `${ENV_VAR}` を header value として展開しないため、秘密値を
追跡ファイルへ書かずにローカル config を生成する。

macOS / Linux:

```sh
./observability/set-codex-grafana.sh
```

Windows:

```powershell
pwsh -NoProfile -File observability/set-codex-grafana.ps1
```

helper は `GRAFANA_CLOUD_OTLP_HEADERS` を再利用して次を設定する。

- logs: `<endpoint>/v1/logs`
- metrics: 無効（Codex 0.142.5 は Delta 固定、Grafana Cloud Mimir は Cumulative 必須）
- traces: `<endpoint>/v1/traces`
- prompt 本文: `log_user_prompt = false` で送信しない
- config permissions: macOS / Linux では `0600`

`~/.codex/config.toml` が dotfiles への symlink の場合、helper は内容を保ったままローカル実体へ
変換してから認証情報を追加する。`mac/setup.sh` / `win/setup.ps1` はこの managed block を検出し、
認証情報が環境に無い再実行でも上書きしない。

Unix では root 権限が使えるなら system config の方がきれいに分離できる。これなら
`~/.codex/config.toml` を引き続き symlink 管理できる。

```sh
./observability/set-codex-grafana.sh --system
```

Codex の telemetry 設定は user/system layer でのみ有効で、project `.codex/config.toml` からは
設定できない。CLI / IDE / Codex app は同じ config layer を共有する。

## 再起動と確認

設定後は Claude Code / Codex を完全終了して再起動する。Codex exporter は非同期 batch 送信し、
終了時にも flush する。

Grafana Cloud で確認する:

- **Explore → Prometheus**: `claude_code_` および `codex_` を補完検索
- **Explore → Loki**: `{service_name=~"codex.*|Codex.*"}`
- **Explore → Tempo**: `{ resource.service.name =~ "codex.*" }`
- **Dashboards → Import**: 下記 JSON を import

## ダッシュボード

| パス | データソース | 内容 |
|---|---|---|
| `grafana/dashboards/claude-code-cloud.json` | Prometheus + Loki | Claude Code の利用状況と、Codex の総token / API相当参考コスト（円）/ sessions / events / logs |
| `grafana/dashboards/codex-cloud.json` | Loki + Tempo | Codex の event volume / errors / structured logs（Loki 行）と、turn duration 分位 / span rate / ターン単位のトークン内訳 / MCP 起動コスト / slow spans / conversation.id 横断（Tempo 行） |

### Codex の trace 構造（TraceQL を書くときの前提）

実測（codex-cli 0.145.0）で確認した挙動。

- **span は Rust の `#[instrument]` 由来の関数名**。`session_task.turn` / `list_tools_for_server` /
  `handle_responses` / `persist_rollout_items` など。`codex.*` という名前の span は無い。
- **1 ターン = 1 トレースにならない**。「Reply with OK」1 回で 323 spans / root span 20 個 /
  traceId 21 個に割れる。トレース単位で追うより `conversation.id` で横断する方が実用的。
- **トークン使用量は span 属性**。`session_task.turn` に
  `codex.turn.token_usage.{input,cached_input,cache_write_input,non_cached_input,output,reasoning_output,total}_tokens`。
  `handle_responses` には OTel GenAI 準拠の `gen_ai.usage.*` も付く。
- **`conversation.id` は span 属性ではなく span *event* 属性**。TraceQL では
  `span.conversation.id` ではなく **`event.conversation.id`** を使う。
  スコープは `/api/v2/search/tags` で確認できる（`span` / `resource` / `event` / `intrinsic`）。
- **`codex.*` のセマンティックなイベント名は `event.name` 属性**に入る。span event 自体の名前は
  `event otel/src/events/session_telemetry.rs:687` のような file:line なので、名前では引けない。
- **秘匿性**: trace に載るのは `codex_otel.trace_safe` 側だけ。prompt 本文・`user.email` は
  trace に出ない（`prompt_length` などの数値のみ）。API キーは bool の presence フラグのみ。
- **TraceQL metrics は時間範囲上限 25h**。`quantile_over_time` / `rate()` を使うパネルは
  now-7d などに広げると HTTP 400 になる。分位の値は 2 の冪の指数バケットで粗く量子化される。

## トラブルシュート

- **HTTP 401/403**: token、instance ID、Access Policy の write scopes を確認する。
- **Claude metrics が来ない**: `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative` を確認する。
- **Codex metrics**: 現行CodexはtemporalityをDeltaにハードコードしているため、本構成では送らない。利用状況はLokiのstructured logsから集計する。
- **Codex が来ない**: `codex --strict-config exec --skip-git-repo-check "Reply with OK"` で config parse と送信を確認し、プロセスを完全再起動する。
- **認証ヘッダ**: `Basic%20...` ではなく実際の空白を使う。helper は自動補正する。
- **漏洩時**: Grafana Cloud の Access Policies で token を直ちに revoke する。

Codex の公式仕様: [Advanced Configuration — Observability and telemetry](https://developers.openai.com/codex/config-advanced#observability-and-telemetry)
