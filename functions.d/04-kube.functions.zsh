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
