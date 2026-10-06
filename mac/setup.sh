#!/usr/bin/env bash
#
# クリーンな macOS 環境で 1 回実行すれば dotfiles のセットアップが完了する。
# べき等: 何度実行しても安全。
#
#   ./setup.sh               フルセットアップ (Homebrew / パッケージ / runtimes / リンク)
#   ./setup.sh --links-only  シンボリックリンクと雛形ファイルの配置だけ行う
#
set -euo pipefail

LINKS_ONLY=0
[ "${1:-}" = "--links-only" ] && LINKS_ONLY=1

# setup.sh は mac/ に置いてあるので、リポジトリルートは 1 段上
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step()  { printf '\n\033[36m=== %s ===\033[0m\n' "$1"; }
info()  { printf '  %s\n' "$1"; }
green() { printf '  \033[32m%s\033[0m\n' "$1"; }
yellow(){ printf '  \033[33m%s\033[0m\n' "$1"; }
gray()  { printf '  \033[90m%s\033[0m\n' "$1"; }

# link <repo相対パス> <リンク先(絶対)>
link() {
  local src="$ROOT/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      gray "skip   $dst"
      return
    fi
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak"
    yellow "backup $dst -> $dst.bak"
  fi
  ln -s "$src" "$dst"
  green "link   $dst"
}

if [ "$LINKS_ONLY" -eq 0 ]; then

# ── 1. Homebrew ──────────────────────────────────────────────────────────────
step "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  info "already installed"
fi

# ── 2. Brewfile (パッケージ一括導入) ─────────────────────────────────────────
step "brew bundle"
# 1 エントリの失敗 (例: VSCode 未導入時の拡張インストール) で
# 以降の symlink ステップごと中断しないよう、失敗は警告に留める。
brew bundle --file="$ROOT/mac/Brewfile" || yellow "一部パッケージのインストールに失敗しました (上のログを確認)。処理は継続します。"

# ── 3. mise install (runtimes) ───────────────────────────────────────────────
# install する前に global 設定を配置・trust しておく必要がある。
step "mise (runtimes)"
if command -v mise >/dev/null 2>&1; then
  link "mise/config.toml" "$HOME/.config/mise/config.toml"
  mise trust "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
  mise install
else
  yellow "mise が見つかりません。brew bundle 完了後に再度このスクリプトを実行してください。"
fi

# ── 4. npm グローバルパッケージ ──────────────────────────────────────────────
step "npm globals"
if command -v npm >/dev/null 2>&1; then
  npm install -g @anthropic-ai/claude-code
else
  yellow "npm が見つかりません。mise install 完了後に再度このスクリプトを実行してください。"
fi

fi # LINKS_ONLY

# ── 5. シンボリックリンク ────────────────────────────────────────────────────
step "symlinks"

# zsh
link "mac/zsh/.zshrc"            "$HOME/.zshrc"
link "mac/zsh/.zprofile"         "$HOME/.zprofile"
link "mac/zsh/.zshenv"           "$HOME/.zshenv"

# git
link "mac/git/.gitconfig"        "$HOME/.gitconfig"
link "mac/git/ignore"            "$HOME/.config/git/ignore"
link "mac/git/personal.gitconfig" "$HOME/.config/git/personal.gitconfig"

# tmux
link "mac/tmux/.tmux.conf"       "$HOME/.tmux.conf"

# WezTerm
link "mac/wezterm/wezterm.lua"   "$HOME/.config/wezterm/wezterm.lua"

# starship
link "mac/starship/starship.toml" "$HOME/.config/starship.toml"

# lazygit
link "mac/lazygit/config.yml"    "$HOME/.config/lazygit/config.yml"

# micro
link "mac/micro/settings.json"   "$HOME/.config/micro/settings.json"

# Neovim
link "mac/nvim/init.lua"         "$HOME/.config/nvim/init.lua"
link "mac/nvim/lazy-lock.json"   "$HOME/.config/nvim/lazy-lock.json"

# mise グローバル設定 (フルセットアップ時はステップ 3 で配置済み)
link "mise/config.toml"          "$HOME/.config/mise/config.toml"

# Karabiner-Elements: karabiner.json は Karabiner 自身が書き換える (一時ファイル → rename) ため、
# ファイル単位のリンクは壊れる。ディレクトリごとリンクする。
link "mac/karabiner"             "$HOME/.config/karabiner"

# Claude Code (Windows と共有)
link "claude/CLAUDE.md"          "$HOME/.claude/CLAUDE.md"
link "claude/settings.json"      "$HOME/.claude/settings.json"
link "claude/ccgate.jsonnet"     "$HOME/.claude/ccgate.jsonnet"

# Claude Code skills / commands (Windows と共有)
# スキルは個別リンク: dotfiles 管理外のスキル (別リポジトリへの symlink 等) と共存できるようにする
for d in "$ROOT"/claude/skills/*/; do
  [ -d "$d" ] || continue
  link "claude/skills/$(basename "$d")" "$HOME/.claude/skills/$(basename "$d")"
done
for f in "$ROOT"/claude/commands/*.md; do
  [ -f "$f" ] || continue
  link "claude/commands/$(basename "$f")" "$HOME/.claude/commands/$(basename "$f")"
done

# Codex (Windows と共有)
link "codex/AGENTS.md"           "$HOME/.codex/AGENTS.md"
link "codex/ccgate.jsonnet"      "$HOME/.codex/ccgate.jsonnet"

# Codex config: Codex は書き換え時に symlink を実ファイルで置き換えるため、実ファイルには
# マシン固有の設定 (projects trust など) が溜まっている。実ファイルなら上書きしない。
# Grafana 認証が環境にあれば、ローカル実体に [otel] ブロックを追記する (repo には書かない)。
codex_config="$HOME/.codex/config.toml"
has_grafana_auth="${CODEX_GRAFANA_CLOUD_AUTHORIZATION:-${GRAFANA_CLOUD_OTLP_HEADERS:-}}"
if [ -f /etc/codex/config.toml ] && \
   grep -q '^# BEGIN dotfiles: codex Grafana Cloud OTLP (managed)$' /etc/codex/config.toml; then
  link "codex/config.toml" "$codex_config"
elif [ -f "$codex_config" ] && [ ! -L "$codex_config" ]; then
  gray "skip   $codex_config (ローカル実体)"
  [ -n "$has_grafana_auth" ] && "$ROOT/observability/set-codex-grafana.sh"
elif [ -n "$has_grafana_auth" ]; then
  link "codex/config.toml" "$codex_config"
  "$ROOT/observability/set-codex-grafana.sh"
else
  link "codex/config.toml" "$codex_config"
fi

# ── 6. マシン固有ファイル (リポジトリ外) ─────────────────────────────────────
step "local files"
if [ ! -f "$HOME/.gitconfig.local" ]; then
  cp "$ROOT/mac/git/gitconfig.local.example" "$HOME/.gitconfig.local"
  yellow "~/.gitconfig.local を作成しました。~/dev-self/ 以外で使う git の user.name / user.email を書いてください。"
else
  gray "skip   ~/.gitconfig.local (既存)"
fi

# ── 7. secrets ───────────────────────────────────────────────────────────────
step "secrets"
if [ ! -f "$HOME/.config/secrets.env" ]; then
  cp "$ROOT/mac/secrets.env.example" "$HOME/.config/secrets.env"
  yellow "~/.config/secrets.env を作成しました。OPENAI_API_KEY を実際の値に書き換えてください。"
else
  gray "skip   ~/.config/secrets.env (既存)"
fi

printf '\n\033[36mDone! ターミナルを再起動してください。\033[0m\n'
