# ── secrets (gitignore 対象。mac/secrets.env.example を参照) ──────────────────
[ -f "$HOME/.config/secrets.env" ] && source "$HOME/.config/secrets.env"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/mikumo-sora/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/mikumo-sora/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/mikumo-sora/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/mikumo-sora/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

if [ -f $(brew --prefix)/etc/profile.d/z.sh ]; then
  . $(brew --prefix)/etc/profile.d/z.sh
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# mise (runtimes: node / python / go)
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# WezTerm: カレントディレクトリを OSC 7 で通知
function _wezterm_notify_cwd() {
  printf '\e]7;file://%s%s\e\\' "$(hostname)" "${PWD}"
  printf '\e]2;%s\e\\' "${PWD##*/}"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _wezterm_notify_cwd
add-zsh-hook precmd _wezterm_notify_cwd
_wezterm_notify_cwd
