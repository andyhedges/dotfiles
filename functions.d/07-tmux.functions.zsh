mrun() {
    if [[ $# -lt 2 ]]; then
        echo "usage: mrun <host1> <host2> ... -- <command...>" >&2
        return 1
    fi

    # split args into hosts and command (everything after -- is the command)
    local hosts=()
    local cmd=()
    local sep_found=0

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

    # Build the remote command string safely
    # Wrap each arg in single quotes and escape internal quotes
    local remote_cmd=""
    local c escaped
    for c in "${cmd[@]}"; do
        escaped=${c//\'/\'"\'"\'}
        remote_cmd+="'$escaped' "
    done

    # We are going to either:
    #   - create a new tmux window in the current session, or
    #   - create a new detached session
    #
    # We always capture the window_id and pane_ids so we can target exactly.
    local window_id session_name first_pane new_pane i

    if [[ -n "$TMUX" ]]; then
        # already in tmux
        # create a brand new window and get its window_id
        window_id=$(tmux new-window -P -F '#{window_id}' -n "mrun")
        # first (only) pane in that new window
        first_pane=$(tmux list-panes -t "$window_id" -F '#{pane_id}' | head -n1)

        # run first host in first pane
        tmux send-keys -t "$first_pane" "ssh ${hosts[1]} ${remote_cmd}" C-m

        # create more panes for remaining hosts
        for ((i=2; i<=${#hosts[@]}; i++)); do
            # split the active pane in this window, get the new pane id
            new_pane=$(tmux split-window -t "$window_id" -v -P -F '#{pane_id}')
            tmux send-keys -t "$new_pane" "ssh ${hosts[i]} ${remote_cmd}" C-m
            tmux select-layout -t "$window_id" tiled >/dev/null
        done

        # make sure we are now looking at that new window
        tmux select-window -t "$window_id"
        tmux select-layout -t "$window_id" tiled >/dev/null
    else
        # not in tmux
        # create a brand new detached session and grab its window_id
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
