# ~/.claude/settings.json に Claude Code のテレメトリ設定(env)を追記する。
# settings.json が dotfiles へのシンボリックリンクになっていない環境向けのブートストラップ。
# 既存の設定は壊さず env だけを上書き追加する（再実行しても安全）。
$ErrorActionPreference = 'Stop'

$p = Join-Path $HOME '.claude/settings.json'
$j = Get-Content $p -Raw | ConvertFrom-Json

$j | Add-Member -NotePropertyName env -NotePropertyValue ([pscustomobject]@{
  CLAUDE_CODE_ENABLE_TELEMETRY = '1'
  OTEL_METRICS_EXPORTER        = 'otlp'
  OTEL_EXPORTER_OTLP_PROTOCOL  = 'grpc'
  OTEL_EXPORTER_OTLP_ENDPOINT  = 'http://localhost:4317'
  OTEL_METRIC_EXPORT_INTERVAL  = '10000'
}) -Force

$j | ConvertTo-Json -Depth 10 | Set-Content $p -Encoding utf8
Write-Host "OK: env block written to $p"
