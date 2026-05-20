export USER=$(id -un)

# zoxide (smart cd)
eval "$(zoxide init bash)"

# fzf key bindings and completion
source ~/dotfiles/win/bash/fzf.bash

# open Visual Studio solution in current directory as admin
devenv() {
  local win_path=$(cygpath -w "$PWD")
  powershell.exe -Command "Start-Process 'C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe' -ArgumentList '\"$win_path\"' -Verb RunAs"
}
