sfx() {
  local arg="${1:-$?}" sound
  case "$arg" in
    good|ok|success|0)     sound=Glass ;;
    bad|fail|error|[1-9]*) sound=Funk ;;
    notify|info|ping)      sound=Ping ;;
    *)                     (( arg == 0 )) && sound=Glass || sound=Basso ;;
  esac

  if command -v setsid >/dev/null 2>&1; then
    setsid -f afplay "/System/Library/Sounds/${sound}.aiff" >/dev/null 2>&1
  else
    # zsh quiet background
    command afplay "/System/Library/Sounds/${sound}.aiff" </dev/null >/dev/null 2>&1 &!
  fi
}
