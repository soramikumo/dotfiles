#!/usr/bin/env bash
# Codex の OTLP ログ・トレースを Grafana Cloud へ直接送る。
#
# 既定では ~/.codex/config.toml をローカル実体ファイルにして設定する。
# dotfiles への symlink なら、内容をコピーしてから symlink を外すため、認証情報は
# リポジトリへ書き込まれない。--system は /etc/codex/config.toml を使う（sudo 必須）。
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: set-codex-grafana.sh [--endpoint URL] [--auth-header VALUE] [--system]

Auth is resolved in this order:
  1. --auth-header (for example: "Basic BASE64")
  2. CODEX_GRAFANA_CLOUD_AUTHORIZATION
  3. GRAFANA_CLOUD_OTLP_HEADERS (extracts Authorization=...)

--system writes /etc/codex/config.toml and keeps ~/.codex/config.toml symlinkable.
EOF
}

endpoint="${CODEX_GRAFANA_CLOUD_OTLP_ENDPOINT:-https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp}"
auth_header="${CODEX_GRAFANA_CLOUD_AUTHORIZATION:-}"
target="${CODEX_HOME:-$HOME/.codex}/config.toml"
system=false

while (($#)); do
  case "$1" in
    --endpoint)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      endpoint="$2"
      shift 2
      ;;
    --auth-header)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      auth_header="$2"
      shift 2
      ;;
    --system)
      target="/etc/codex/config.toml"
      system=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$auth_header" && -n "${GRAFANA_CLOUD_OTLP_HEADERS:-}" ]]; then
  case "$GRAFANA_CLOUD_OTLP_HEADERS" in
    Authorization=*) auth_header="${GRAFANA_CLOUD_OTLP_HEADERS#Authorization=}" ;;
    authorization=*) auth_header="${GRAFANA_CLOUD_OTLP_HEADERS#authorization=}" ;;
  esac
fi

auth_header="${auth_header#Authorization=}" 
auth_header="${auth_header#authorization=}" 
auth_header="${auth_header/Basic%20/Basic }"
endpoint="${endpoint%/}"

if [[ ! "$endpoint" =~ ^https://[^[:space:]]+/otlp$ ]]; then
  printf 'Endpoint must be an HTTPS Grafana OTLP base URL ending in /otlp: %s\n' "$endpoint" >&2
  exit 1
fi
if [[ ! "$auth_header" =~ ^Basic[[:space:]][A-Za-z0-9+/=]+$ ]]; then
  printf 'Authorization must have the form "Basic BASE64".\n' >&2
  exit 1
fi

# These values are constrained above, but escape them before embedding in TOML anyway.
toml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

escaped_endpoint="$(toml_escape "$endpoint")"
escaped_auth="$(toml_escape "$auth_header")"
begin='# BEGIN dotfiles: codex Grafana Cloud OTLP (managed)'
end='# END dotfiles: codex Grafana Cloud OTLP (managed)'
tmp="$(mktemp)"
trap 'rm -f "$tmp" "${tmp}.base" "${tmp}.block"' EXIT

if [[ -e "$target" || -L "$target" ]]; then
  sed "/^${begin}$/,/^${end}$/d" "$target" >"${tmp}.base"
else
  : >"${tmp}.base"
fi

cat >"${tmp}.block" <<EOF

$begin
[otel]
environment = "local"
log_user_prompt = false
exporter = { otlp-http = { endpoint = "${escaped_endpoint}/v1/logs", protocol = "binary", headers = { Authorization = "${escaped_auth}" } } }
metrics_exporter = "none"
trace_exporter = { otlp-http = { endpoint = "${escaped_endpoint}/v1/traces", protocol = "binary", headers = { Authorization = "${escaped_auth}" } } }
$end
EOF

cat "${tmp}.base" "${tmp}.block" >"$tmp"

if $system; then
  sudo install -d -m 0755 "$(dirname "$target")"
  sudo install -o "$(id -un)" -g "$(id -gn)" -m 0600 "$tmp" "$target"

  # A previously materialized user config would override the system [otel] table.
  # Restore the tracked user config symlink when it is one of ours.
  user_target="${CODEX_HOME:-$HOME/.codex}/config.toml"
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  repo_config="$repo_root/codex/config.toml"
  if [[ -f "$user_target" && ! -L "$user_target" ]] &&
     grep -q '^# BEGIN dotfiles: codex Grafana Cloud OTLP (managed)$' "$user_target"; then
    rm "$user_target"
    ln -s "$repo_config" "$user_target"
    printf '  restored user config symlink: %s -> %s\n' "$user_target" "$repo_config"
  fi
else
  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" ]]; then
    rm "$target"
  fi
  install -m 0600 "$tmp" "$target"
fi

printf 'OK: Codex Grafana Cloud OTLP configured in %s\n' "$target"
printf '  logs    %s/v1/logs\n' "$endpoint"
printf '  metrics disabled (Codex emits Delta; Grafana Cloud Mimir requires Cumulative)\n'
printf '  traces  %s/v1/traces\n' "$endpoint"
printf '  prompts redacted\n'
