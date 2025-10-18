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

# Record start time before each command
preexec() { __timer=$EPOCHREALTIME }

# Build dynamic right prompt before each prompt
precmd() {
  vcs_info

  # jobs fragment: nothing | "job:1" | "jobs:N"
  if (( $#jobstates == 1 )); then
    JOBSTR="%F{240}job:1%f"
  elif (( $#jobstates > 1 )); then
    JOBSTR="%F{240}jobs:$#jobstates%f"
  else
    JOBSTR=""
  fi

  # elapsed fragment: only if last command took >2s
  ELAPSEDSTR=""
  if [[ -n $__timer ]]; then
    local elapsed=$(( EPOCHREALTIME - __timer ))
    if (( elapsed > 2 )); then
      # format to 1 decimal place, e.g. 3.8s
      local pretty; pretty=$(printf '%.1fs' "$elapsed")
      ELAPSEDSTR="%F{240}${pretty}%f"
    fi
  fi

  # rebuild RPROMPT cleanly each time
  RPROMPT="%(?..%F{red}✗ %?%f )${vcs_info_msg_0_:+$vcs_info_msg_0_ }${JOBSTR:+ $JOBSTR}${ELAPSEDSTR:+ $ELAPSEDSTR}"
}

# PROMPT (left side)
PROMPT='%F{240}%*%f %F{cyan}%n%f@%F{blue}%m%f:%F{green}%~%f
%(?.%F{240}➜%f.%F{red}✗%f) '

# completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # colorize completion listings

# Source aliases and functions
[ -f ~/.dotfiles/.aliases ] && source ~/.dotfiles/.aliases
[ -f ~/.dotfiles/.functions ] && source ~/.dotfiles/.functions

# Allow user-specific overrides
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
