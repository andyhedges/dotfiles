# --- Basic setup ----------------------------------------------------------
setopt prompt_subst          # allow ${...} in PROMPT/RPROMPT to expand

autoload -Uz compinit promptinit colors vcs_info add-zsh-hook
compinit
promptinit
colors

zmodload zsh/datetime || true   # ensure EPOCHREALTIME works


[[ -r "$HOME/.dotfiles/banner.zsh" ]] && source "$HOME/.dotfiles/banner.zsh"

# --- Homebrew ------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- Paths --------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:/Applications/IntelliJ IDEA CE.app/Contents/MacOS:$PATH"

# --- Auto-update dotfiles occasionally (every 7 days) ---------------------
if [[ -d "$HOME/.dotfiles/.git" ]] && command -v git >/dev/null 2>&1; then
  _dotfiles_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
  _dotfiles_update_stamp="$_dotfiles_state_dir/last-update"
  if [[ ! -f "$_dotfiles_update_stamp" ]] || find "$_dotfiles_update_stamp" -mtime +7 -print -quit | grep -q .; then
    mkdir -p "$_dotfiles_state_dir" 2>/dev/null && touch "$_dotfiles_update_stamp" 2>/dev/null
    git -C "$HOME/.dotfiles" pull --quiet --ff-only &>/dev/null &!
  fi
  unset _dotfiles_state_dir _dotfiles_update_stamp
fi

export LC_CTYPE="en_US.UTF-8"



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
      ELAPSEDSTR="%F{240}$(printf '%.2f' "$elapsed")s%f"
    fi
    unset __timer
  fi

  # compose once so nothing gets stuck or duplicated
  RPROMPT="%(?..%F{red}✗ %?%f )${vcs_info_msg_0_:+$vcs_info_msg_0_ }${JOBSTR:+ $JOBSTR}${ELAPSEDSTR:+ $ELAPSEDSTR}"
}
add-zsh-hook precmd _prompt_precmd

# --- Prompt (left side) ---------------------------------------------------
PROMPT='%F{240}%K{240}%F{white} %* %k%F{240} %F{blue}%K{blue}%F{white} %n@%m %k%F{blue}%F{green} %K{green}%F{black} %~ %k%F{green} %(?.%F{green}%f.%F{red}%f) '

# --- Options -----------------------------------------------------------------
setopt autocd extendedglob correct no_beep hist_ignore_dups share_history
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# --- Completion and colors ------------------------------------------------
zstyle ':completion:*' menu select
[[ -n ${LS_COLORS-} ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} || true

# --- Tool integrations ----------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi

# --- Aliases and functions - standardized loaders --------------------------
# Directory layout
ZDOT_DIR="$HOME/.dotfiles"
ZALIAS_DIR="$ZDOT_DIR/aliases.d"
ZFUNC_DIR="$ZDOT_DIR/functions.d"

# Patterns we accept
_alias_pat='^[0-9][0-9]-[a-z0-9._-]+\.aliases\.zsh$'
_funcs_pat='^[0-9][0-9]-[a-z0-9._-]+\.functions\.zsh$'
_autoload_pat='^[0-9][0-9]-([a-zA-Z0-9._-]+)\.func\.zsh$'   # captures funcname

# Helper: load all alias bundles in lexical order
_load_aliases_dir() {
  emulate -L zsh
  setopt local_options null_glob no_unset
  local f base bad=0
  for f in "$ZALIAS_DIR"/**/*.zsh(N.); do
    base="${f:t}"
    if [[ "$base" =~ $_alias_pat ]]; then
      source "$f"
    else
      print -u2 "alias file skipped for nonstandard name: $base"
      bad=1
    fi
  done
  return $bad
}

# Helper: source function bundles and register autoloaded single-function files
_load_functions_dir() {
  emulate -L zsh
  setopt local_options null_glob no_unset
  local f base m funcname bad=0
  local -a autoload_names autoload_files

  # 1) source multi-function bundles
  for f in "$ZFUNC_DIR"/**/*.zsh(N.); do
    base="${f:t}"
    if [[ "$base" =~ $_funcs_pat ]]; then
      source "$f"
    elif [[ "$base" =~ $_autoload_pat ]]; then
      # record for autoload pass
      funcname="${match[1]}"  # captured from the regex
      autoload_names+="$funcname"
      autoload_files+="$f"
    else
      print -u2 "function file skipped for nonstandard name: $base"
      bad=1
    fi
  done

  # 2) autoload single-function files
  if (( ${#autoload_names} )); then
    # add directories of autoloaded files to fpath once
    local -a autoload_dirs=(${autoload_files:h})
    autoload_dirs=(${autoload_dirs:u})  # unique
    fpath=(${autoload_dirs} $fpath)
    autoload -Uz ${autoload_names}
  fi

  return $bad
}

# Run loaders
[[ -d "$ZALIAS_DIR" ]] && _load_aliases_dir
[[ -d "$ZFUNC_DIR"  ]] && _load_functions_dir


# --- Optional per-host overrides -----------------------------------------
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local" || true
