grepn() {
  # Grep with line numbers and color when outputting to a TTY.
  if [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]]; then
    cat >&2 <<'EOF'
usage: grepn <pattern> [path...]

Grep with line numbers and color when outputting to a TTY.
EOF
    return 1
  fi
  if [[ -t 1 ]]; then
    command grep -n --color=auto "$@"
  else
    command grep "$@"
  fi
}

grepc() {
  # Grep with 3 lines of context, line numbers, and color when TTY.
  if [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]]; then
    cat >&2 <<'EOF'
usage: grepc <pattern> [path...]

Grep with 3 lines of context, line numbers, and color when TTY.
EOF
    return 1
  fi
  if [[ -t 1 ]]; then
    command grep -C3 -n --color=auto "$@"
  else
    command grep -C3 "$@"
  fi
}

grepf() {
  # Recursive grep (skip common build dirs) with line numbers and color when TTY.
  if [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]]; then
    cat >&2 <<'EOF'
usage: grepf <pattern> [path...]

Recursive grep (skip common build dirs) with line numbers and color when TTY.
EOF
    return 1
  fi
  if [[ -t 1 ]]; then
    command grep -rIn --color=auto \
      --exclude-dir={.git,node_modules,dist,build} "$@"
  else
    command grep -rI \
      --exclude-dir={.git,node_modules,dist,build} "$@"
  fi
}
