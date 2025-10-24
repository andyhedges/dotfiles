mrun() {
    if [[ $# -lt 2 ]]; then
        echo "usage: mrun <host1> <host2> ... -- <command...>" >&2
        return 1
    fi

    local hosts=()
    local cmd=()
    local sep_found=0
    local arg

    # split args into hosts (before --) and cmd (after --)
    for arg in "$@"; do
        if [[ $sep_found -eq 0 ]]; then
            if [[ $arg == "--" ]]; then
                sep_found=1
            else
                hosts+=("$arg")
            fi
        else
            cmd+=("$arg")
        fi
    done

    if [[ $sep_found -eq 0 ]]; then
        echo "mrun: missing -- separator before command" >&2
        return 1
    fi
    if [[ ${#hosts[@]} -eq 0 ]]; then
        echo "mrun: no hosts given" >&2
        return 1
    fi
    if [[ ${#cmd[@]} -eq 0 ]]; then
        echo "mrun: no command given" >&2
        return 1
    fi

    # quote the remote command safely
    local remote_cmd=""
    local c escaped
    for c in "${cmd[@]}"; do
        escaped=${c//\'/\'"\'"\'}
        remote_cmd+="'$escaped' "
    done

    local window_id session_name first_pane new_pane i

    if [[ -n "$TMUX" ]]; then
        # already in tmux: create a brand new window and grab its id
        window_id=$(tmux new-window -P -F '#{window_id}' -n "mrun")
        first_pane=$(tmux list-panes -t "$window_id" -F '#{pane_id}' | head -n1)

        # run first host in first pane
        tmux send-keys -t "$first_pane" "ssh ${hosts[1]} ${remote_cmd}" C-m

        # split for the remaining hosts
        for ((i=2; i<=${#hosts[@]}; i++)); do
            new_pane=$(tmux split-window -t "$window_id" -v -P -F '#{pane_id}')
            tmux send-keys -t "$new_pane" "ssh ${hosts[i]} ${remote_cmd}" C-m
            tmux select-layout -t "$window_id" tiled >/dev/null
        done

        tmux select-window -t "$window_id"
        tmux select-layout -t "$window_id" tiled >/dev/null
    else
        # not in tmux: create a detached session
        session_name="mrun-$$"
        window_id=$(tmux new-session -d -s "$session_name" -P -F '#{window_id}')
        first_pane=$(tmux list-panes -t "$window_id" -F '#{pane_id}' | head -n1)

        tmux send-keys -t "$first_pane" "ssh ${hosts[1]} ${remote_cmd}" C-m

        for ((i=2; i<=${#hosts[@]}; i++)); do
            new_pane=$(tmux split-window -t "$window_id" -v -P -F '#{pane_id}')
            tmux send-keys -t "$new_pane" "ssh ${hosts[i]} ${remote_cmd}" C-m
            tmux select-layout -t "$window_id" tiled >/dev/null
        done

        tmux select-layout -t "$window_id" tiled >/dev/null
        tmux attach-session -t "$session_name"
    fi
}

mssh() {
    if [[ $# -lt 1 ]]; then
        echo "usage: mssh <host1> <host2> <host3> ..." >&2
        return 1
    fi

    local hosts=("$@")
    local window_id session_name i

    if [[ -n "$TMUX" ]]; then
        # You are already in tmux
        # Create a brand new window that runs ssh to the first host
        window_id=$(tmux new-window -P -F '#{window_id}' -n "mssh" "ssh ${hosts[1]}")

        # For each remaining host, split and start ssh in that pane
        for ((i=2; i<=${#hosts[@]}; i++)); do
            tmux split-window  -t "$window_id" -v -P -F '#{pane_id}' "ssh ${hosts[i]}" >/dev/null
            tmux select-layout -t "$window_id" tiled >/dev/null
        done

        tmux select-window -t "$window_id"
        tmux select-layout -t "$window_id" tiled >/dev/null

        # Note: panes start unsynchronised. Use prefix Shift+S to broadcast.
    else
        # You are not in tmux
        # Create a new detached session where the first pane is already ssh'd in
        session_name="mssh-$$"
        window_id=$(tmux new-session -d -s "$session_name" -P -F '#{window_id}' "ssh ${hosts[1]}")

        # Add panes for the rest
        for ((i=2; i<=${#hosts[@]}; i++)); do
            tmux split-window  -t "$window_id" -v -P -F '#{pane_id}' "ssh ${hosts[i]}" >/dev/null
            tmux select-layout -t "$window_id" tiled >/dev/null
        done

        tmux select-layout -t "$window_id" tiled >/dev/null
        tmux attach-session -t "$session_name"
    fi
}
