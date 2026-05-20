export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --bind 'ctrl-/:toggle-preview'
  --color=bg+:#1e1e2e,bg:#000000,spinner:#cba6f7,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#cba6f7
  --color=marker:#cba6f7,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# use fd if available, otherwise find
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# load fzf key bindings (Ctrl+T, Ctrl+R, Alt+C)
if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
elif [[ -f "$HOME/scoop/apps/fzf/current/shell/key-bindings.bash" ]]; then
  source "$HOME/scoop/apps/fzf/current/shell/key-bindings.bash"
fi
