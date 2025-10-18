# Auto-update dotfiles occasionally (every 7 days)
if [ -d "$HOME/.dotfiles/.git" ]; then
  if find "$HOME/.dotfiles/.git" -mtime +7 | grep -q .; then
    echo "Updating dotfiles..."
    git -C "$HOME/.dotfiles" pull --quiet --ff-only &
  fi
fi

setopt prompt_subst          # allow ${...} in PROMPT/RPROMPT to expand

# --- Initialize completion and prompt systems ---
autoload -Uz compinit promptinit colors vcs_info
compinit
promptinit
colors

# Configure vcs_info for git
zstyle ':vcs_info:git:*' formats '%F{yellow} %b%f'
zstyle ':vcs_info:*' enable git

# Ensure it's updated before every prompt
precmd() { vcs_info }

# Prompt and completion styling can follow:
# PROMPT (left side)
PROMPT='%F{240}%*%f %F{cyan}%n%f@%F{blue}%m%f:%F{green}%~%f
%(?.%F{240}➜%f.%F{red}✗%f) '
# RPROMPT (right side)
RPROMPT='%(?..%F{red}✗ %?%f )${vcs_info_msg_0_:+$vcs_info_msg_0_ }%F{240}%j%f'

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # colorize completion listings


# Source aliases and functions
[ -f ~/.dotfiles/.aliases ] && source ~/.dotfiles/.aliases
[ -f ~/.dotfiles/.functions ] && source ~/.dotfiles/.functions

# Allow user-specific overrides: 
# For example, if your dotfiles are synced across machines, .zshrc.local can
# hold different PATH entries, environment variables, or API keys without
# committing them.
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
