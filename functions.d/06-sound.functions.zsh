# ~/.zshrc or ~/.bashrc
sfx() {
  local arg="${1:-$?}"

  case "$arg" in
    good|ok|success|0)
      command afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 &!
      ;;
    bad|fail|error|[1-9]*)
      command afplay /System/Library/Sounds/Basso.aiff >/dev/null 2>&1 &!
      ;;
    notify|info|ping)
      command afplay /System/Library/Sounds/Submarine.aiff >/dev/null 2>&1 &!
      ;;
    *)
      # fallback: use last exit code numerically if $arg isn’t a word
      if (( arg == 0 )); then
        command afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 &!
      else
        command afplay /System/Library/Sounds/Basso.aiff >/dev/null 2>&1 &!
      fi
      ;;
  esac
}
