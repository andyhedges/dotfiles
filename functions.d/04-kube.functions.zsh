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

# kk_table: tabular view using JSON + jq
kk_table() {
  command -v jq >/dev/null || { echo "jq required"; return 1; }

  # If no ns given (or flags first), scan all namespaces
  if [[ $# -eq 0 || "$1" == -* ]]; then
    kubectl get all -A -o json "$@" | jq -r '
      def row:
        . as $i | $i.kind as $k |
        # READY column per kind
        (if   $k=="Pod"        then (($i.status.containerStatuses // []) as $cs
                                     | "\(([$cs[]|select(.ready==true)]|length))/\(($cs|length))")
         elif $k=="Deployment" or $k=="StatefulSet" or $k=="ReplicaSet"
                               then "\(($i.status.readyReplicas // 0))/\(($i.status.replicas // 0))"
         elif $k=="DaemonSet"  then "\(($i.status.numberReady // 0))/\(($i.status.desiredNumberScheduled // 0))"
         elif $k=="Job"        then "\(($i.status.succeeded // 0))/\(($i.spec.completions // ($i.spec.parallelism // 0)))"
         else "" end) as $ready
        |
        # STATUS column
        (if   $k=="Pod"   then ($i.status.phase // "")
         elif $k=="Service" then ($i.spec.type // "")
         else (($i.status.conditions // [])
               | map(select(.status=="True") | .type)
               | join(",")) end) as $status
        |
        [$k,
         ($i.metadata.namespace // "default"),
         $i.metadata.name,
         $ready,
         $status,
         ($i.metadata.creationTimestamp // "")]
      ;

      ["KIND","NAMESPACE","NAME","READY","STATUS","CREATED"],
      (.items[] | row)
      | @tsv
    ' | column -t -s $'\t'
    return
  fi

  # Specific namespaces listed first, then optional extra kubectl flags
  local -a names extra
  while [[ $# -gt 0 && "$1" != -* ]]; do names+=("$1"); shift; done
  extra=("$@")

  printf "KIND\tNAMESPACE\tNAME\tREADY\tSTATUS\tCREATED\n" | column -t -s $'\t'
  for ns in "${names[@]}"; do
    kubectl get all -n "$ns" -o json "${extra[@]}" | jq -r '
      def row:
        . as $i | $i.kind as $k |
        (if   $k=="Pod"        then (($i.status.containerStatuses // []) as $cs
                                     | "\(([$cs[]|select(.ready==true)]|length))/\(($cs|length))")
         elif $k=="Deployment" or $k=="StatefulSet" or $k=="ReplicaSet"
                               then "\(($i.status.readyReplicas // 0))/\(($i.status.replicas // 0))"
         elif $k=="DaemonSet"  then "\(($i.status.numberReady // 0))/\(($i.status.desiredNumberScheduled // 0))"
         elif $k=="Job"        then "\(($i.status.succeeded // 0))/\(($i.spec.completions // ($i.spec.parallelism // 0)))"
         else "" end) as $ready
        |
        (if   $k=="Pod"   then ($i.status.phase // "")
         elif $k=="Service" then ($i.spec.type // "")
         else (($i.status.conditions // [])
               | map(select(.status=="True") | .type)
               | join(",")) end) as $status
        |
        [$k, ($i.metadata.namespace // "default"), $i.metadata.name, $ready, $status, ($i.metadata.creationTimestamp // "")]
      ;
      (.items[] | row) | @tsv
    ' 
  done | column -t -s $'\t'
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
