# -- File lising aliases ----------------------------------------------------

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons'
elif command -v lsd >/dev/null 2>&1; then
  alias ls='lsd --group-dirs first'
elif command -v exa >/dev/null 2>&1; then
  alias ls='exa --group-directories-first --icons'
fi
alias ll='ls -lh'
alias la='ls -lha'
alias ..='cd ..'
alias ...='cd ../..'