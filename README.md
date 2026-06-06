# dotfiles

開発環境のセットアップ用 dotfiles。macOS / Windows の両環境に対応しています。

## 構成

| ディレクトリ | 内容 |
|---|---|
| `claude/` | Claude Code の設定 (`CLAUDE.md` / `settings.json` / `ccgate.jsonnet`) |
| `mise/` | [mise](https://mise.jdx.dev/) のグローバル設定 (Node.js / Python / Go などのバージョン管理) |
| `win/` | Windows 環境のセットアップ一式 (詳細は [`win/README.md`](win/README.md)) |

## Windows セットアップ

クリーンな Windows 環境で `win/setup.ps1` を実行すると、winget / Scoop によるパッケージ導入、mise でのランタイム固定、各設定ファイルのシンボリックリンク作成までを一括で行います。手順の詳細は [`win/README.md`](win/README.md) を参照してください。

## 注意

`win/git/.gitconfig` の `[user]` セクションは雛形です。利用時は自分の名前とメールアドレスに書き換えてください。
