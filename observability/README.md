# observability — Claude Code を Grafana で可視化

Claude Code の利用状況（トークン・コスト・セッション・変更行数など）を、
**完全ローカル・無料**で可視化するスタック。データは一切外部に出ない。

```
Claude Code ──OTLP/gRPC:4317──▶ OTel Collector ──:8889──▶ Prometheus ──▶ Grafana(:3000)
 settings.jsonでON               (受信→Prom形式に変換)      (保存)        (可視化)
```

記事の Grafana Cloud 連携と違い、Grafana / Prometheus / Collector をすべて
自分の PC の Docker 上で動かす。ライセンスはすべて OSS なので追加課金ゼロ。

## 前提

- Docker Desktop が起動していること
- Claude Code のテレメトリは `claude/settings.json` の `env` で有効化済み
  （`~/.claude/settings.json` にシンボリックリンクされている前提）

## 起動

```powershell
cd $env:USERPROFILE\dotfiles\observability
docker compose up -d
```

初回はイメージ取得で数分かかる。立ち上がったら：

| URL | 用途 |
|---|---|
| http://localhost:3000 | Grafana（ログイン不要・匿名 Admin）。ダッシュボード「Claude Code Usage」が自動表示 |
| http://localhost:9090 | Prometheus UI（メトリクスの生確認・PromQL お試し） |
| http://localhost:8889/metrics | Collector が公開している生メトリクス |

その後、**Claude Code を新しく起動**すれば（`OTEL_METRIC_EXPORT_INTERVAL=10000` なので）
約10秒間隔でメトリクスが流れ始める。Grafana のダッシュボードは10秒ごとに自動更新。

## 停止 / 後始末

```powershell
docker compose down            # コンテナ停止（メトリクスは volume に残る）
docker compose down -v         # volume ごと削除（データも消す）
```

## エクスポートされる主なメトリクス

Collector で `add_metric_suffixes: false` にしているので、Prometheus 上の名前は予測可能：

| Prometheus 名 | 内容 | 単位 |
|---|---|---|
| `claude_code_cost_usage` | セッションのコスト | USD |
| `claude_code_token_usage` | トークン使用量 | tokens |
| `claude_code_session_count` | セッション数 | count |
| `claude_code_lines_of_code_count` | 変更行数 | count |
| `claude_code_commit_count` | コミット数 | count |
| `claude_code_pull_request_count` | PR 数 | count |
| `claude_code_active_time_total` | アクティブ時間 | 秒 |
| `claude_code_code_edit_tool_decision` | 編集ツールの許可判断 | count |

## トラブルシュート

**Grafana にデータが出ない**
1. `docker compose logs otel-collector` に Claude Code からの受信ログが出ているか確認
2. http://localhost:9090/targets で `otel-collector` が UP か確認
3. Claude Code を起動し直したか（env は新規セッションから反映）
4. http://localhost:9090 で `claude_code_token_usage` を検索してデータが入っているか確認

**メトリクス名やラベルが想定と違うとき**
- Grafana 左メニュー → Explore → Prometheus を選び、`claude_code_` と打つと
  実際に存在するメトリクス名が補完される。ラベル（`type` / `model` など）もここで確認できる。
  ダッシュボードの PromQL はこの名前に合わせて調整する。

## メモ

- `OTEL_METRIC_EXPORT_INTERVAL=10000`（10秒）は動作確認用に短くしてある。
  常用するなら `claude/settings.json` で `60000`（デフォルト）に戻すと負荷が減る。
- ログ(Loki)・トレース(Tempo)は未導入。次のステップで Collector の pipeline と
  compose にサービスを足せば拡張できる。
