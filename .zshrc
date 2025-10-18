precmd() {
  vcs_info
  if (( $#jobstates == 1 )); then
    JOBSTR="%F{240}job:1%f"
  elif (( $#jobstates > 1 )); then
    JOBSTR="%F{240}jobs:$#jobstates%f"
  else
    JOBSTR=""
  fi
}

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

# Prompt and completion styling can follow:
# PROMPT (left side)
PROMPT='%F{240}%*%f %F{cyan}%n%f@%F{blue}%m%f:%F{green}%~%f
%(?.%F{240}➜%f.%F{red}✗%f) '
# RPROMPT (right side)
RPROMPT='%(?..%F{red}✗ %?%f )${vcs_info_msg_0_:+$vcs_info_msg_0_ }${JOBSTR}'

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
