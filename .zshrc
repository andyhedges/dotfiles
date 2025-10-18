# --- Initialize completion and prompt systems ---
autoload -Uz compinit promptinit
compinit
promptinit

# Prompt and completion styling can follow:
PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # colorize completion listings


# Source aliases and functions
[ -f ~/.dotfiles/.aliases ] && source ~/.dotfiles/.aliases
[ -f ~/.dotfiles/.functions ] && source ~/.dotfiles/.functions

# Allow user-specific overrides: 
# For example, if your dotfiles are synced across machines, .zshrc.local can
# hold different PATH entries, environment variables, or API keys without
# committing them.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
