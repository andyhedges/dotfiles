# ~/.zshrc or ~/.bashrc
sfx() {
  local arg="$1"
  local code

  case "$arg" in
    good|ok|success)
      code=0
      ;;
    bad|fail|error)
      code=1
      ;;
    ''|*[!0-9]*)   # if no arg or not numeric, use last exit code
      code=${?}
      ;;
    *)              # numeric arg
      code=$arg
      ;;
  esac

  if (( code == 0 )); then
    afplay /System/Library/Sounds/Glass.aiff &>/dev/null 2>&1 &!
  elif (( code < 128 )); then
    afplay /System/Library/Sounds/Basso.aiff &>/dev/null 2>&1 &!
  else
    afplay /System/Library/Sounds/Submarine.aiff &>/dev/null 2>&1 &!
  fi
}
