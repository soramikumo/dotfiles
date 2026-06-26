# Claude Code のテレメトリ送信先を Grafana Cloud(OTLP) に直接向ける。
# トークンはこのスクリプトには含めず、実行時に渡す/対話入力する。
# 書き込み先は ~/.claude/settings.json のみ（dotfilesリポジトリの外＝gitに入らない）。
#
# 使い方A（Grafana Cloud がくれる base64 をそのまま渡す。一番確実）:
#   pwsh -NoProfile -File set-grafana-cloud.ps1 `
#     -Endpoint "https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp" `
#     -AuthB64  "<Authorization: Basic の後ろの長いbase64>"
#
# 使い方B（インスタンスIDとトークンから組み立てる。引数なしなら対話入力）:
#   pwsh -NoProfile -File set-grafana-cloud.ps1 -Endpoint "..." -InstanceId <instanceID> -Token "glc_..."

param(
  [string] $Endpoint,
  [string] $AuthB64,      # base64("<instanceID>:<token>") … "Basic " の後ろの文字列
  [string] $InstanceId,   # 代替: ID + Token から base64 を生成
  [string] $Token
)
$ErrorActionPreference = 'Stop'

if (-not $Endpoint) { $Endpoint = Read-Host 'OTLP Endpoint URL (.../otlp)' }

if (-not $AuthB64) {
  if (-not $InstanceId) { $InstanceId = Read-Host 'Instance ID (numeric)' }
  if (-not $Token)      { $Token      = Read-Host 'Access Policy Token (glc_...)' }
  $AuthB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(('{0}:{1}' -f $InstanceId, $Token)))
}

$Endpoint = $Endpoint.TrimEnd('/')
# 先頭に "Basic " や "Basic%20" が紛れていても除去（=純粋な base64 にする）
$AuthB64 = $AuthB64 -replace '^Basic%20', '' -replace '^Basic ', ''

$p = Join-Path $HOME '.claude/settings.json'
$j = Get-Content $p -Raw | ConvertFrom-Json

$j | Add-Member -NotePropertyName env -NotePropertyValue ([pscustomobject]@{
  CLAUDE_CODE_ENABLE_TELEMETRY = '1'
  OTEL_METRICS_EXPORTER        = 'otlp'
  OTEL_EXPORTER_OTLP_PROTOCOL  = 'http/protobuf'                 # クラウドは gRPC 不可
  OTEL_EXPORTER_OTLP_ENDPOINT  = $Endpoint
  OTEL_EXPORTER_OTLP_HEADERS   = "Authorization=Basic $AuthB64"  # 本物の半角スペース（%20地雷回避）
  OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = 'cumulative'  # delta→cumulative 強制（無いと Mimir が HTTP 400）
  OTEL_METRIC_EXPORT_INTERVAL  = '60000'
}) -Force

$j | ConvertTo-Json -Depth 10 | Set-Content $p -Encoding utf8

$len = (Get-Item $p).Length
Write-Host "OK: wrote Grafana Cloud config to $p ($len bytes)"
Write-Host "  endpoint = $Endpoint"
Write-Host "  protocol = http/protobuf"
Write-Host "  auth     = Basic <$($AuthB64.Length)-char base64>"
