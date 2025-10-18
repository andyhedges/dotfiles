# Auto-update dotfiles occasionally (every 7 days)
if [ -d "$HOME/.dotfiles/.git" ]; then
  if find "$HOME/.dotfiles/.git" -mtime +7 -print -quit | grep -q .; then
    echo "Updating dotfiles..."
    git -C "$HOME/.dotfiles" pull --quiet --ff-only &
  fi
fi

setopt prompt_subst          # allow ${...} in PROMPT/RPROMPT to expand

# --- Initialize completion and prompt systems ---
autoload -Uz compinit promptinit colors vcs_info add-zsh-hook
compinit
promptinit
colors

# Time source for EPOCHREALTIME
zmodload zsh/datetime || true

# Configure vcs_info for git
zstyle ':vcs_info:git:*' formats '%F{yellow} %b%f'
zstyle ':vcs_info:*' enable git

# --- Hooks ---------------------------------------------------------------
# define the functions once
_timer_preexec() { __timer=$EPOCHREALTIME }

_prompt_precmd() {
  vcs_info

  # jobs fragment: nothing | "job:1" | "jobs:N"
  local JOBSTR=""
  if (( $#jobstates == 1 )); then
    JOBSTR="%F{240}job:1%f"
  elif (( $#jobstates > 1 )); then
    JOBSTR="%F{240}jobs:$#jobstates%f"
  fi

  # elapsed fragment: only if last command took >2s
  local ELAPSEDSTR=""
  if [[ -n $__timer ]]; then
    local elapsed=$(( EPOCHREALTIME - __timer ))
    if (( elapsed > 2 )); then
      ELAPSEDSTR="%F{240}$(printf '%.1fs' "$elapsed")%f"
    fi
  fi

  RPROMPT="%(?..%F{red}✗ %?%f )${vcs_info_msg_0_:+$vcs_info_msg_0_ }${JOBSTR:+ $JOBSTR}${ELAPSEDSTR:+ $ELAPSEDSTR}"
}

# add hooks ONLY if not already present
typeset -ag preexec_functions precmd_functions
[[ -z ${preexec_functions[(r)_timer_preexec]} ]] && add-zsh-hook preexec _timer_preexec || true
[[ -z ${precmd_functions[(r)_prompt_precmd]}  ]] && add-zsh-hook precmd  _prompt_precmd  || true
# ------------------------------------------------------------------------
# PROMPT (left side)
PROMPT='%F{240}%*%f %F{cyan}%n%f@%F{blue}%m%f:%F{green}%~%f
%(?.%F{240}➜%f.%F{red}✗%f) '

# completion styling
zstyle ':completion:*' menu select
[[ -n ${LS_COLORS-} ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Source aliases and functions
[[ -r "$HOME/.dotfiles/.aliases"   ]] && source "$HOME/.dotfiles/.aliases"
[[ -r "$HOME/.dotfiles/.functions" ]] && source "$HOME/.dotfiles/.functions"

# Allow user-specific overrides
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
