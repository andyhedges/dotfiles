# Auto-update dotfiles occasionally (every 7 days)
if [ -d "$HOME/.dotfiles/.git" ]; then
  if find "$HOME/.dotfiles/.git" -mtime +7 | grep -q .; then
    echo "Updating dotfiles..."
    git -C "$HOME/.dotfiles" pull --quiet --ff-only &
  fi
fi

# Source aliases and functions
[ -f ~/.dotfiles/.aliases ] && source ~/.dotfiles/.aliases
[ -f ~/.dotfiles/.functions ] && source ~/.dotfiles/.functions

# Allow user-specific overrides: 
# For example, if your dotfiles are synced across machines, .zshrc.local can
# hold different PATH entries, environment variables, or API keys without
# committing them.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
