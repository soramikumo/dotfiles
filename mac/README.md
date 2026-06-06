# macOS セットアップ

クリーンな macOS 環境で `setup.sh` を 1 回実行すれば完了。べき等なので何度実行しても安全。

## 使い方

```bash
git clone <this-repo> ~/dev-self/private-repo/dotfiles
cd ~/dev-self/private-repo/dotfiles/mac
./setup.sh
```

実行後はターミナルを再起動する。

## setup.sh がやること

| ステップ | 内容 |
|---|---|
| Homebrew | 未インストールなら導入 |
| brew bundle | `Brewfile` のパッケージ (formula / cask / VSCode 拡張) を一括インストール |
| mise install | Node.js / Python / Go をバージョン固定でインストール |
| npm globals | `@anthropic-ai/claude-code` をグローバルインストール |
| シンボリックリンク | 各設定ファイルを所定の場所に配置 (既存ファイルは `.bak` に退避) |
| secrets | `~/.config/secrets.env` を雛形から生成 |

## シンボリックリンク一覧

| dotfiles 内のパス | リンク先 |
|---|---|
| `mac/zsh/.zshrc` | `~/.zshrc` |
| `mac/zsh/.zprofile` | `~/.zprofile` |
| `mac/zsh/.zshenv` | `~/.zshenv` |
| `mac/git/.gitconfig` | `~/.gitconfig` |
| `mac/git/ignore` | `~/.config/git/ignore` |
| `mac/tmux/.tmux.conf` | `~/.tmux.conf` |
| `mac/wezterm/wezterm.lua` | `~/.config/wezterm/wezterm.lua` |
| `mac/starship/starship.toml` | `~/.config/starship.toml` |
| `mac/lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| `mac/micro/settings.json` | `~/.config/micro/settings.json` |
| `mac/nvim/init.lua` | `~/.config/nvim/init.lua` |
| `mac/nvim/lazy-lock.json` | `~/.config/nvim/lazy-lock.json` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/ccgate.jsonnet` | `~/.claude/ccgate.jsonnet` |

## secrets (環境変数)

機密値はリポジトリに含めず `~/.config/secrets.env` に置く (`.gitignore` 対象)。
雛形は [`mac/secrets.env.example`](secrets.env.example)。`.zprofile` / `.zshrc` がこれを `source` する。

- `OPENAI_API_KEY` — ccgate (Claude Code の `PermissionRequest` フック) が使用

## パッケージの更新

```bash
# インストール済みパッケージを Brewfile に反映
brew bundle dump --file=mac/Brewfile --force
```

## 注意

`mac/zsh/.zshrc` には conda / nvm / SDKMAN の初期化ブロックが含まれる (存在チェック付きなので
未導入環境でも無害)。Node/Python のバージョンは本来 `mise` で固定するため、必要に応じて
nvm / conda 由来の初期化を整理すること。
