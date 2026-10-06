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

# agmsg Codex monitor shim — must come after mise activation so it wins on PATH
export PATH="$HOME/.agents/bin:$PATH"

# ── Orca ─────────────────────────────────────────────────────────────────────
# `orca .` / `orca <dir>` → そのディレクトリを Orca に登録して開き、
# 対応する worktree にターミナルタブを作って前面化する。
# それ以外の引数は本物の CLI にそのまま渡す。
# 必要: jq
orca() {
  # $commands は PATH のコマンドだけを引くので、この関数自身を拾わない。
  # Settings → "Enable Orca CLI" 済みならそちらが、未実行ならアプリ内蔵のものが使われる。
  local bin=${commands[orca]:-/Applications/Orca.app/Contents/Resources/bin/orca}

  if [[ $# -eq 1 && ( $1 == . || $1 == .. || $1 == */* || $1 == ~* ) && -d $1 ]]; then
    local dir=${1:A} wt
    "$bin" open >/dev/null || return

    # cwd → worktree 解決。サブディレクトリを渡しても囲っている worktree が返る
    wt=$(cd -- "$dir" && "$bin" worktree current --json 2>/dev/null | jq -r '.result.worktree.id // empty')

    if [[ -z $wt ]]; then
      "$bin" repo add --path "$dir" >/dev/null || return
      wt=$(cd -- "$dir" && "$bin" worktree current --json 2>/dev/null | jq -r '.result.worktree.id // empty')
    fi

    if [[ -z $wt ]]; then
      print -u2 "orca: $dir に対応する worktree を解決できなかった"
      return 1
    fi

    # path: ではなく id: を使う。サブディレクトリを渡された場合 path: は解決できない
    "$bin" terminal create --worktree "id:$wt" --focus
    return
  fi

  "$bin" "$@"
}
