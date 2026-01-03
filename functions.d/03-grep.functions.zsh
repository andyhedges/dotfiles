grepn() {
  if [[ -t 1 ]]; then
    command grep -n --color=auto "$@"
  else
    command grep "$@"
  fi
}

grepc() {
  if [[ -t 1 ]]; then
    command grep -C3 -n --color=auto "$@"
  else
    command grep -C3 "$@"
  fi
}

grepf() {
  if [[ -t 1 ]]; then
    command grep -rIn --color=auto \
      --exclude-dir={.git,node_modules,dist,build} "$@"
  else
    command grep -rI \
      --exclude-dir={.git,node_modules,dist,build} "$@"
  fi
}
