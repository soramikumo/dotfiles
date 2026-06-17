eval "$(/opt/homebrew/bin/brew shellenv)"

# secrets (gitignore 対象。mac/secrets.env.example を参照)
[ -f "$HOME/.config/secrets.env" ] && source "$HOME/.config/secrets.env"
