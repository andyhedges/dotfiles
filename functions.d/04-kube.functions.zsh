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
        echo
        echo "%F{cyan}╭──────────────────────────────╮%f"
        printf "│ %s%-28s│\n" "%F{white}Namespace:%f " "$ns"
        echo "%F{cyan}╰──────────────────────────────╯%f"
        kubectl get all -n "$ns" "${extra[@]}" | column -t
    done
}


kctx() {
    local contexts ctx_count choice
    contexts=($(kubectl config get-contexts -o name))
    ctx_count=${#contexts[@]}

    if (( ctx_count == 0 )); then
        echo "No kube contexts found."
        return 1
    fi

    # If user passed an exact name → just switch
    if [[ -n "$1" ]]; then
        kubectl config use-context "$1"
        return
    fi

    echo "Available contexts:"
    local i=1
    for c in "${contexts[@]}"; do
        printf "%2d) %s\n" "$i" "$c"
        ((i++))
    done

    echo -n "Select context [1-$ctx_count]: "
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ && choice -ge 1 && choice -le $ctx_count ]]; then
        kubectl config use-context "${contexts[choice-1]}"
    else
        echo "Invalid choice."
        return 1
    fi
}
