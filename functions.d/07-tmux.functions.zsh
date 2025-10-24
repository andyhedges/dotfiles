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
    # We single-quote each arg and escape any existing single quotes
    local remote_cmd=""
    for c in "${cmd[@]}"; do
        local escaped=${c//\'/\'"\'"\'}
        remote_cmd+="'$escaped' "
    done

    # Helper to send a command to a tmux pane
    tmux_send() {
        local pane="$1"
        shift
        tmux send-keys -t "$pane" "$@" C-m
    }

    # Are we already inside tmux?
    if [[ -n "$TMUX" ]]; then
        # We're in a tmux client already.
        # Use the current window, kill all panes but the current one first
        # so we start clean.
        local cur_win
        cur_win=$(tmux display-message -p '#{window_id}')

        # kill all panes in this window except the active one
        local active_pane
        active_pane=$(tmux display-message -p '#{pane_id}')
        for p in $(tmux list-panes -F '#{pane_id}'); do
            if [[ $p != "$active_pane" ]]; then
                tmux kill-pane -t "$p"
            fi
        done

        # run first host in active pane, then create new panes for others
        tmux_send "$active_pane" "ssh ${hosts[1]} ${remote_cmd}"

        local i
        for ((i=2; i<=${#hosts[@]}; i++)); do
            tmux split-window -t "$cur_win" -v
            tmux_send "$cur_win".+ "ssh ${hosts[i]} ${remote_cmd}"
            tmux select-layout -t "$cur_win" tiled >/dev/null
        done

        tmux select-layout -t "$cur_win" tiled >/dev/null
        return 0
    fi

    # Not in tmux: create a brand new session
    local session="mrun-$$"

    # create session with first host
    tmux new-session -d -s "$session" \
        "ssh ${hosts[1]} ${remote_cmd}"

    # add panes for rest of hosts
    local i
    for ((i=2; i<=${#hosts[@]}; i++)); do
        tmux split-window -t "$session":0 -v
        tmux send-keys -t "$session":0.+ "ssh ${hosts[i]} ${remote_cmd}" C-m
        tmux select-layout -t "$session":0 tiled >/dev/null
    done

    tmux select-layout -t "$session":0 tiled >/dev/null
    tmux attach-session -t "$session"
}
