# Windows セットアップ

クリーンな Windows 環境で `setup.ps1` を 1 回実行すれば完了。

## 使い方

```powershell
# 管理者権限の PowerShell で実行
git clone <this-repo> $env:USERPROFILE\dotfiles
cd $env:USERPROFILE\dotfiles\win
.\setup.ps1
```

実行後はターミナルを再起動する。

## setup.ps1 がやること

| ステップ | 内容 |
|---|---|
| winget パッケージ | `packages/winget.json` に記載のアプリを一括インストール |
| Scoop パッケージ | `packages/Scoopfile.json` に記載のツールを一括インストール |
| mise install | Node.js / Python / Go をバージョン固定でインストール |
| npm globals | `@anthropic-ai/claude-code` をグローバルインストール |
| シンボリックリンク | 各設定ファイルを所定の場所に配置 |

## シンボリックリンク一覧

| dotfiles 内のパス | リンク先 |
|---|---|
| `win/wezterm/wezterm.lua` | `~/.wezterm.lua` |
| `win/bash/.bashrc` | `~/.bashrc` |
| `win/bash/.bash_profile` | `~/.bash_profile` |
| `win/git/.gitconfig` | `~/.gitconfig` |
| `win/lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| `win/micro/settings.json` | `%APPDATA%/micro/settings.json` |
| `win/wsl/.wslconfig` | `~/.wslconfig` |
| `win/powershell/profile.ps1` | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` |
| `mise/config.toml` | `%APPDATA%/mise/config.toml` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/ccgate.jsonnet` | `~/.claude/ccgate.jsonnet` |

## 動作確認 (Windows Sandbox)

Windows 11 Pro 標準搭載の使い捨て環境でテストできる。

```powershell
# Sandbox を有効化（初回のみ・要再起動）
Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM"
```

有効化後、スタートメニューから **Windows Sandbox** を起動して `setup.ps1` を実行する。
Sandbox を閉じると環境はリセットされる。

## パッケージの更新

```powershell
# インストール済みパッケージを一覧に反映
winget export -o win\packages\winget.json
scoop export > win\packages\Scoopfile.json  # 形式が異なるため手動調整が必要
```
