# ── secrets (gitignore 対象。mac/secrets.env.example を参照) ──────────────────
[ -f "$HOME/.config/secrets.env" ] && source "$HOME/.config/secrets.env"

# ── runtimes: node / python / go は mise に一本化 ─────────────────────────────
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# SDKMAN (Java など mise 管理外のランタイム用)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ── shell UX ─────────────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# WezTerm: カレントディレクトリを OSC 7 で通知
function _wezterm_notify_cwd() {
  printf '\e]7;file://%s%s\e\\' "$(hostname)" "${PWD}"
  printf '\e]2;%s\e\\' "${PWD##*/}"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _wezterm_notify_cwd
add-zsh-hook precmd _wezterm_notify_cwd
_wezterm_notify_cwd
