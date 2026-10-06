# macOS セットアップ

クリーンな macOS 環境で `setup.sh` を 1 回実行すれば完了。べき等なので何度実行しても安全。

## 使い方

```bash
git clone https://github.com/soramikumo/dotfiles.git ~/dev-self/dotfiles
cd ~/dev-self/dotfiles/mac
./setup.sh                 # フルセットアップ
./setup.sh --links-only    # リンクと雛形の配置だけやり直す
```

実行後はターミナルを再起動する。

> `~/dev-self/` 配下に置くこと。git の個人 identity は `includeIf "gitdir:~/dev-self/"` で切り替えている。

## setup.sh がやること

| ステップ | 内容 |
|---|---|
| Homebrew | 未インストールなら導入 |
| brew bundle | `Brewfile` のパッケージ (formula / cask / VSCode 拡張) を一括インストール |
| mise install | Node.js / Python / Go をバージョン固定でインストール |
| npm globals | `@anthropic-ai/claude-code` をグローバルインストール |
| シンボリックリンク | 各設定ファイルを所定の場所に配置 (既存ファイルは `.bak` に退避) |
| local files | `~/.gitconfig.local` を雛形から生成 |
| secrets | `~/.config/secrets.env` を雛形から生成 |

`--links-only` のときは Homebrew / brew bundle / mise / npm をスキップする。

## シンボリックリンク一覧

| dotfiles 内のパス | リンク先 |
|---|---|
| `mac/zsh/.zshrc` | `~/.zshrc` |
| `mac/zsh/.zprofile` | `~/.zprofile` |
| `mac/zsh/.zshenv` | `~/.zshenv` |
| `mac/git/.gitconfig` | `~/.gitconfig` |
| `mac/git/ignore` | `~/.config/git/ignore` |
| `mac/git/personal.gitconfig` | `~/.config/git/personal.gitconfig` |
| `mac/tmux/.tmux.conf` | `~/.tmux.conf` |
| `mac/wezterm/wezterm.lua` | `~/.config/wezterm/wezterm.lua` |
| `mac/starship/starship.toml` | `~/.config/starship.toml` |
| `mac/lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| `mac/micro/settings.json` | `~/.config/micro/settings.json` |
| `mac/nvim/init.lua` | `~/.config/nvim/init.lua` |
| `mac/nvim/lazy-lock.json` | `~/.config/nvim/lazy-lock.json` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `mac/karabiner/` (ディレクトリごと) | `~/.config/karabiner` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/ccgate.jsonnet` | `~/.claude/ccgate.jsonnet` |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `codex/config.toml` | `~/.codex/config.toml` (※) |
| `codex/ccgate.jsonnet` | `~/.codex/ccgate.jsonnet` |

※ Codex は config を書き換えるときに symlink を実ファイルで置き換える。実ファイルになっていたら
setup.sh は上書きしない (マシン固有の projects trust を残すため)。

## setup.sh 以外の手作業

- **macOS defaults**: `./macos-defaults.sh` (Dock / Finder / トラックパッド等)。会社 Mac は MDM と衝突しうるので自動実行しない
- **Raycast**: 旧 Mac で Settings → Advanced → Export した `.rayconfig` (暗号化) を Import する。repo には入れない
- **Karabiner-Elements**: 初回起動時に入力監視などの権限を許可する
- **Orca**: Homebrew に cask がない (`orca` は別物) ので手動インストール

## git の identity

| 対象 | 設定ファイル |
|---|---|
| `~/dev-self/` 配下 | `mac/git/personal.gitconfig` (個人アカウント) |
| それ以外 | `~/.gitconfig.local` (リポジトリ外。会社 Mac では会社アカウント) |

`user.useConfigOnly = true` なので、どちらにも当たらないリポジトリでは commit が拒否される。
会社 Mac で gh に個人・会社の両アカウントを登録する場合は `gh auth login` を 2 回行い、`gh auth switch` で切り替える。

## 会社 Mac に持ち込むときの注意

- `~/.config/secrets.env` に個人の API キーを入れない
- `claude/settings.json` / `claude/CLAUDE.md` は個人用。必要に応じて会社用に見直す
- 会社の情報 (パス・ホスト名・メールアドレス等) をこのリポジトリにコミットしない (public リポジトリ)。
  Claude Code の `settings.json` は symlink なので、会社 Mac での設定変更は repo の差分として現れる点に注意

## secrets (環境変数)

機密値はリポジトリに含めず `~/.config/secrets.env` に置く (`.gitignore` 対象)。
雛形は [`mac/secrets.env.example`](secrets.env.example)。`.zprofile` / `.zshrc` がこれを `source` する。

- `OPENAI_API_KEY` — ccgate (Claude Code / Codex の `PermissionRequest` フック) が使用

## パッケージの更新

```bash
# インストール済みパッケージを Brewfile に反映
brew bundle dump --file=mac/Brewfile --force
```

## 注意

- 対象は **Apple Silicon (arm64) のみ**。Homebrew は `/opt/homebrew` 前提。
- Node / Python / Go のバージョン管理は **mise に一本化**している (`mise/config.toml`)。
  nvm / conda 由来の初期化は `.zshrc` から除去済み。Java など mise 管理外のランタイムは
  SDKMAN を併用する。
