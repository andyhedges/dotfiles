kk() {
    if [[ $# -eq 0 || "$1" == -* ]]; then
        kubectl get all -A "$@"
        return
    fi
    names=()
    while [[ $# -gt 0 && "$1" != -* ]]; do
        names+=("$1")
        shift
    done
    extra=("$@")
    for ns in "${names[@]}"; do
        echo "===== $ns ====="
        kubectl get all -n "$ns" "${extra[@]}"
        echo
    done
}

# smart fuzzy switch (uses fzf if installed)
kctx() {
  if command -v fzf >/dev/null 2>&1; then
    local ctx
    ctx=$(kubectl config get-contexts -o name | fzf --prompt="Select context: ")
    [[ -n "$ctx" ]] && kubectl config use-context "$ctx"
  else
    echo "fzf not installed; falling back to numbered selection."
    local contexts=($(kubectl config get-contexts -o name))
    local i=1
    for c in "${contexts[@]}"; do printf "%2d) %s\n" "$i" "$c"; ((i++)); done
    read -r choice\?"Select context: "
    [[ "$choice" =~ ^[0-9]+$ ]] && kubectl config use-context "${contexts[choice]}"
  fi
}

# Restart all pods in a namespace
krestart() {
  local ns="${1:-default}"
  kubectl rollout restart deploy -n "$ns"
}
