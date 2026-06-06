#!/usr/bin/env bash
#
# クリーンな macOS 環境で 1 回実行すれば dotfiles のセットアップが完了する。
# べき等: 何度実行しても安全。
#
set -euo pipefail

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
step "mise (runtimes)"
if command -v mise >/dev/null 2>&1; then
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

# ── 5. シンボリックリンク ────────────────────────────────────────────────────
step "symlinks"

# zsh
link "mac/zsh/.zshrc"            "$HOME/.zshrc"
link "mac/zsh/.zprofile"         "$HOME/.zprofile"
link "mac/zsh/.zshenv"           "$HOME/.zshenv"

# git
link "mac/git/.gitconfig"        "$HOME/.gitconfig"
link "mac/git/ignore"            "$HOME/.config/git/ignore"

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

# mise グローバル設定 (Windows と共有)
link "mise/config.toml"          "$HOME/.config/mise/config.toml"

# Claude Code (Windows と共有)
link "claude/CLAUDE.md"          "$HOME/.claude/CLAUDE.md"
link "claude/settings.json"      "$HOME/.claude/settings.json"
link "claude/ccgate.jsonnet"     "$HOME/.claude/ccgate.jsonnet"

# ── 6. secrets ───────────────────────────────────────────────────────────────
step "secrets"
if [ ! -f "$HOME/.config/secrets.env" ]; then
  cp "$ROOT/mac/secrets.env.example" "$HOME/.config/secrets.env"
  yellow "~/.config/secrets.env を作成しました。OPENAI_API_KEY を実際の値に書き換えてください。"
else
  gray "skip   ~/.config/secrets.env (既存)"
fi

printf '\n\033[36mDone! ターミナルを再起動してください。\033[0m\n'
