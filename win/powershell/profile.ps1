# エンコーディング設定 (文字化け防止)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding            = [System.Text.Encoding]::UTF8

# zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# fzf key bindings
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
        $result = (Get-Content (Get-PSReadLineOption).HistorySavePath | fzf --tac --no-sort)
        if ($result) {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
        }
    }
}

# よく使うエイリアス
Set-Alias -Name g  -Value git
Set-Alias -Name lg -Value lazygit
