# dotfiles

開発環境のセットアップ用 dotfiles。macOS / Windows の両環境に対応しています。

## 構成

| ディレクトリ | 内容 |
|---|---|
| `claude/` | Claude Code の設定 (`CLAUDE.md` / `settings.json` / `ccgate.jsonnet`) ※ macOS / Windows 共有 |
| `mise/` | [mise](https://mise.jdx.dev/) のグローバル設定 (Node.js / Python / Go などのバージョン管理) ※ macOS / Windows 共有 |
| `mac/` | macOS 環境のセットアップ一式 (詳細は [`mac/README.md`](mac/README.md)) |
| `win/` | Windows 環境のセットアップ一式 (詳細は [`win/README.md`](win/README.md)) |

## macOS セットアップ

クリーンな macOS 環境で `mac/setup.sh` を実行すると、Homebrew (`mac/Brewfile`) によるパッケージ導入、mise でのランタイム固定、各設定ファイルのシンボリックリンク作成までを一括で行います。手順の詳細は [`mac/README.md`](mac/README.md) を参照してください。

## Windows セットアップ

クリーンな Windows 環境で `win/setup.ps1` を実行すると、winget / Scoop によるパッケージ導入、mise でのランタイム固定、各設定ファイルのシンボリックリンク作成までを一括で行います。手順の詳細は [`win/README.md`](win/README.md) を参照してください。

## 注意

- `win/git/.gitconfig` の `[user]` セクションは雛形です。利用時は自分の名前とメールアドレスに書き換えてください。
- 機密値 (API キーなど) はリポジトリに含めず `~/.config/secrets.env` に置きます。雛形は [`mac/secrets.env.example`](mac/secrets.env.example) を参照してください。
