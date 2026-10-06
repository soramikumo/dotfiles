#!/usr/bin/env bash
#
# macOS の UI 設定 (defaults) を適用する。値は個人 Mac の実際の設定から抜き出したもの。
# setup.sh からは自動実行しない (会社 Mac では MDM が一部を強制している可能性があるため)。
# 必要なときに手動で実行する: ./mac/macos-defaults.sh
#
set -euo pipefail

# ── 外観 / 入力 ──────────────────────────────────────────────────────────────
defaults write -g AppleInterfaceStyle -string "Dark"
defaults write -g AppleShowAllExtensions -bool true
defaults write -g com.apple.swipescrolldirection -bool false   # ナチュラルスクロール OFF
defaults write -g com.apple.trackpad.scaling -float 2.5        # トラックパッドの軌跡の速さ
defaults write -g com.apple.keyboard.fnState -bool false       # F1-F12 は特殊キーとして動作

# ── トラックパッド ───────────────────────────────────────────────────────────
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" Clicking -bool true                 # タップでクリック
  defaults write "$domain" TrackpadRightClick -bool true       # 2 本指で副ボタンクリック
done

# ── Dock ─────────────────────────────────────────────────────────────────────
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 45
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 62

# ── Finder ───────────────────────────────────────────────────────────────────
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # リスト表示
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder NewWindowTarget -string "PfAF"        # 新規ウィンドウで「最近の項目」
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

# 設定を反映
killall Dock Finder SystemUIServer >/dev/null 2>&1 || true
echo "Done. 一部の設定 (トラックパッド・キーボード) はログアウト後に反映されます。"
