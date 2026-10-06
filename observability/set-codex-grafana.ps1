# Codex の OTLP ログ・トレースを Grafana Cloud へ直接送る。
# ~/.codex/config.toml が dotfiles への symlink なら、ローカル実体ファイルへ変換して
# 認証情報がリポジトリへ書き込まれないようにする。
param(
  [string] $Endpoint = $(if ($env:CODEX_GRAFANA_CLOUD_OTLP_ENDPOINT) { $env:CODEX_GRAFANA_CLOUD_OTLP_ENDPOINT } else { 'https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp' }),
  [string] $AuthHeader = $env:CODEX_GRAFANA_CLOUD_AUTHORIZATION,
  [string] $AuthB64,
  [string] $InstanceId,
  [string] $Token
)
$ErrorActionPreference = 'Stop'

if (-not $AuthHeader -and $env:GRAFANA_CLOUD_OTLP_HEADERS -match '(?i)^Authorization=(.+)$') {
  $AuthHeader = $Matches[1]
}
if (-not $AuthHeader -and $AuthB64) {
  $AuthHeader = "Basic $($AuthB64 -replace '(?i)^Basic(?:%20| )', '')"
}
if (-not $AuthHeader -and $InstanceId -and $Token) {
  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${InstanceId}:${Token}"))
  $AuthHeader = "Basic $encoded"
}

$AuthHeader = $AuthHeader -replace '(?i)^Authorization=', '' -replace '(?i)^Basic%20', 'Basic '
$Endpoint = $Endpoint.TrimEnd('/')

if ($Endpoint -notmatch '^https://\S+/otlp$') {
  throw "Endpoint must be an HTTPS Grafana OTLP base URL ending in /otlp: $Endpoint"
}
if ($AuthHeader -notmatch '^Basic [A-Za-z0-9+/=]+$') {
  throw 'Authorization must have the form "Basic BASE64".'
}

$target = Join-Path $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }) 'config.toml'
$parent = Split-Path $target -Parent
New-Item -ItemType Directory -Path $parent -Force | Out-Null

$begin = '# BEGIN dotfiles: codex Grafana Cloud OTLP (managed)'
$end = '# END dotfiles: codex Grafana Cloud OTLP (managed)'
$base = if (Test-Path $target) { Get-Content $target -Raw } else { '' }
$pattern = "(?ms)^$([regex]::Escape($begin))\r?\n.*?^$([regex]::Escape($end))\r?\n?"
$base = [regex]::Replace($base, $pattern, '').TrimEnd()

$escapedEndpoint = $Endpoint.Replace('\', '\\').Replace('"', '\"')
$escapedAuth = $AuthHeader.Replace('\', '\\').Replace('"', '\"')
$block = @"

$begin
[otel]
environment = "local"
log_user_prompt = false
exporter = { otlp-http = { endpoint = "$escapedEndpoint/v1/logs", protocol = "binary", headers = { Authorization = "$escapedAuth" } } }
metrics_exporter = "none"
trace_exporter = { otlp-http = { endpoint = "$escapedEndpoint/v1/traces", protocol = "binary", headers = { Authorization = "$escapedAuth" } } }
$end
"@

$item = Get-Item $target -Force -ErrorAction SilentlyContinue
if ($item -and $item.LinkType -eq 'SymbolicLink') {
  Remove-Item $target -Force
}
[IO.File]::WriteAllText($target, "$base$block", [Text.UTF8Encoding]::new($false))

Write-Host "OK: Codex Grafana Cloud OTLP configured in $target"
Write-Host "  logs    $Endpoint/v1/logs"
Write-Host '  metrics disabled (Codex emits Delta; Grafana Cloud Mimir requires Cumulative)'
Write-Host "  traces  $Endpoint/v1/traces"
Write-Host '  prompts redacted'
