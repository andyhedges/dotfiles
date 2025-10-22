sfx() {
  local arg="${1:-$?}"
  local sound

  case "$arg" in
    good|ok|success|0) sound="Glass" ;;
    bad|fail|error|[1-9]*) sound="Basso" ;;
    notify|info|ping|1[2-9][0-9]*) sound="Submarine" ;;
    *) (( arg == 0 )) && sound="Glass" || sound="Basso" ;;
  esac

  # Detach completely so no broken-pipe messages
  nohup afplay "/System/Library/Sounds/${sound}.aiff" >/dev/null 2>&1 &
  disown 2>/dev/null || true
}
