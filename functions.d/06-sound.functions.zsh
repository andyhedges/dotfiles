sfx() {
  case "$1" in
    good|ok|success)
      afplay /System/Library/Sounds/Glass.aiff ;;
    bad|fail|error)
      afplay /System/Library/Sounds/Basso.aiff ;;
    notify)
      afplay /System/Library/Sounds/Ping.aiff ;;
    *)
      echo "Usage: sfx {good|bad|notify}" ;;
  esac
}