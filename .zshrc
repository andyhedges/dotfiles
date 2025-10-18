# --- Auto-update dotfiles occasionally (every 7 days) ---------------------
if [ -d "$HOME/.dotfiles/.git" ]; then
  if find "$HOME/.dotfiles/.git" -mtime +7 -print -quit | grep -q .; then
    echo "Updating dotfiles..."
    git -C "$HOME/.dotfiles" pull --quiet --ff-only &
  fi
fi

# --- Basic setup ----------------------------------------------------------
setopt prompt_subst          # allow ${...} in PROMPT/RPROMPT to expand

autoload -Uz compinit promptinit colors vcs_info add-zsh-hook
compinit
promptinit
colors

zmodload zsh/datetime || true   # ensure EPOCHREALTIME works

# --- vcs_info (git branch display) ---------------------------------------
zstyle ':vcs_info:git:*' formats '%F{yellow} %b%f'
zstyle ':vcs_info:*' enable git

# --- Hooks ---------------------------------------------------------------
# Record start time before each command
_timer_preexec() {
  typeset -gF __timer=$EPOCHREALTIME
}
add-zsh-hook preexec _timer_preexec

# Build RPROMPT just before drawing the prompt
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
  if (( ${+__timer} )); then
    local -F elapsed=$(( EPOCHREALTIME - __timer ))
    if (( elapsed > 2 )); then
      ELAPSEDSTR="%F{240}${elapsed%.}s%f.2"
    fi
    unset __timer
  fi

  # compose once so nothing gets stuck or duplicated
  RPROMPT="%(?..%F{red}✗ %?%f )${vcs_info_msg_0_:+$vcs_info_msg_0_ }${JOBSTR:+ $JOBSTR}${ELAPSEDSTR:+ $ELAPSEDSTR}"
}
add-zsh-hook precmd _prompt_precmd

# --- Prompt (left side) ---------------------------------------------------
PROMPT='%F{240}%*%f %F{cyan}%n%f@%F{blue}%m%f:%F{green}%~%f
%(?.%F{240}➜%f.%F{red}✗%f) '

# --- Completion and colors ------------------------------------------------
zstyle ':completion:*' menu select
[[ -n ${LS_COLORS-} ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} || true

# --- Aliases and functions -----------------------------------------------
[[ -r "$HOME/.dotfiles/.aliases"   ]] && source "$HOME/.dotfiles/.aliases"
[[ -r "$HOME/.dotfiles/.functions" ]] && source "$HOME/.dotfiles/.functions"

# --- Optional per-host overrides -----------------------------------------
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local" || true
