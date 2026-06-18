#Requires -RunAsAdministrator
<#
.SYNOPSIS
  クリーンな Windows 環境で 1 回実行すれば dotfiles のセットアップが完了する。
  べき等: 何度実行しても安全。
#>

$ErrorActionPreference = "Stop"
# setup.ps1 は win/ に置いてあるので、リポジトリルートは 1 段上
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Step([string]$name) {
    Write-Host "`n=== $name ===" -ForegroundColor Cyan
}

function RefreshPath {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

function Link {
    param([string]$src, [string]$dst)
    $src = Join-Path $root $src
    $dst = [System.Environment]::ExpandEnvironmentVariables($dst)
    $parent = Split-Path $dst -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (Test-Path $dst) {
        $item = Get-Item $dst -Force
        if ($item.LinkType -eq "SymbolicLink") {
            if ($item.Target -eq $src) {
                Write-Host "  skip   $dst" -ForegroundColor DarkGray
                return
            }
            Remove-Item $dst -Force
        } else {
            Move-Item $dst "$dst.bak" -Force
            Write-Host "  backup $dst" -ForegroundColor Yellow
        }
    }
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Host "  link   $dst" -ForegroundColor Green
}

# ── 1. winget パッケージ ─────────────────────────────────────────────────────

Step "winget packages"
winget import `
    --import-file "$root\win\packages\winget.json" `
    --ignore-unavailable `
    --accept-package-agreements `
    --accept-source-agreements
RefreshPath

# ── 2. Scoop パッケージ ──────────────────────────────────────────────────────

Step "Scoop packages"
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-RestMethod https://get.scoop.sh | Invoke-Expression
    RefreshPath
}
$scoopCfg = Get-Content "$root\win\packages\Scoopfile.json" | ConvertFrom-Json
foreach ($b in $scoopCfg.buckets) {
    scoop bucket add $b.Name $b.Source 2>&1 | Out-Null
}
foreach ($a in $scoopCfg.apps) {
    scoop install "$($a.Source)/$($a.Name)"
}

# ── 3. mise install ──────────────────────────────────────────────────────────

Step "mise (runtimes)"
RefreshPath
if (Get-Command mise -ErrorAction SilentlyContinue) {
    Push-Location $root
    mise install
    Pop-Location
    RefreshPath
} else {
    Write-Warning "mise が見つかりません。winget install jdx.mise を実行後に再度このスクリプトを実行してください。"
}

# ── 4. npm グローバルパッケージ ──────────────────────────────────────────────

Step "npm globals"
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g @anthropic-ai/claude-code
} else {
    Write-Warning "npm が見つかりません。mise install 完了後に再度このスクリプトを実行してください。"
}

# ── 5. シンボリックリンク ────────────────────────────────────────────────────

Step "symlinks"

# WezTerm
Link "win\wezterm\wezterm.lua"    "%USERPROFILE%\.wezterm.lua"

# Git Bash
Link "win\bash\.bashrc"           "%USERPROFILE%\.bashrc"
Link "win\bash\.bash_profile"     "%USERPROFILE%\.bash_profile"

# Git
Link "win\git\.gitconfig"         "%USERPROFILE%\.gitconfig"

# lazygit
Link "win\lazygit\config.yml"     "%USERPROFILE%\.config\lazygit\config.yml"

# micro
Link "win\micro\settings.json"    "%APPDATA%\micro\settings.json"

# WSL
Link "win\wsl\.wslconfig"         "%USERPROFILE%\.wslconfig"

# PowerShell (pwsh)
$psProfile = [System.Environment]::ExpandEnvironmentVariables(
    "%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
)
Link "win\powershell\profile.ps1" $psProfile

# mise グローバル設定
Link "mise\config.toml"           "%APPDATA%\mise\config.toml"

# Claude Code
Link "claude\CLAUDE.md"           "%USERPROFILE%\.claude\CLAUDE.md"
Link "claude\settings.json"       "%USERPROFILE%\.claude\settings.json"
Link "claude\ccgate.jsonnet"      "%USERPROFILE%\.claude\ccgate.jsonnet"

# Codex
Link "codex\AGENTS.md"            "%USERPROFILE%\.codex\AGENTS.md"
Link "codex\config.toml"          "%USERPROFILE%\.codex\config.toml"
Link "codex\ccgate.jsonnet"       "%USERPROFILE%\.codex\ccgate.jsonnet"

Write-Host "`nDone! ターミナルを再起動してください。" -ForegroundColor Cyan
