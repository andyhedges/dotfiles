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

margs() {
    # Usage:
    #   cat hosts.txt | margs ssh
    #   margs ssh < hosts.txt
    #   margs ping -c 1 < hosts.txt
    #
    # Behaviour:
    #   - reads one item per line from stdin
    #   - if you're already in tmux:
    #       creates panes in this window and runs "$@" <item> in each
    #   - if you're NOT in tmux:
    #       creates (or replaces) a detached tmux session called "margs",
    #       builds all the panes there, and exits
    #       you then do: tmux attach -t margs

    if [[ $# -lt 1 ]]; then
        print "margs: need a command prefix, e.g. 'margs ssh' or 'margs ping -c 1'" >&2
        return 1
    fi
    local base_cmd=("$@")

    # read stdin into array "items"
    local items=()
    while IFS=$'\n' read -r line; do
        [[ -z "$line" ]] && continue
        items+=("$line")
    done

    if [[ ${#items[@]} -eq 0 ]]; then
        print "margs: no input lines" >&2
        return 1
    fi

    if [[ -n "$TMUX" ]]; then
        # Case 1: we're already inside tmux.
        # Use the current window/pane and tile it.
        local first=1
        local it
        for it in "${items[@]}"; do
            if (( first )); then
                tmux send-keys -t "$TMUX_PANE" "$(printf '%q ' "${base_cmd[@]}" "$it")" C-m
                first=0
            else
                tmux split-window -v
                tmux send-keys "$(printf '%q ' "${base_cmd[@]}" "$it")" C-m
                tmux select-layout tiled >/dev/null 2>&1
            fi
        done
        tmux select-layout tiled >/dev/null 2>&1
        return 0
    fi

    # Case 2: NOT already in tmux.
    # We'll build or rebuild a detached session "margs", window 0.
    # Then you can `tmux attach -t margs` after this function returns,
    # from a real tty, so no "not a terminal".

    local session="margs"

    # kill stale session with that name if it exists
    tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session"

    # start new detached session running an idle shell
    tmux new-session -d -s "$session" zsh

    # now populate panes in that session
    # start by targeting session:0.0 (window 0, pane 0)
    local target_window="${session}:0"
    local first=1
    local it
    for it in "${items[@]}"; do
        if (( first )); then
            tmux send-keys -t "${target_window}.0" "$(printf '%q ' "${base_cmd[@]}" "$it")" C-m
            first=0
        else
            tmux split-window -t "$target_window" -v
            tmux send-keys -t "$target_window" "$(printf '%q ' "${base_cmd[@]}" "$it")" C-m
            tmux select-layout -t "$target_window" tiled >/dev/null 2>&1
        fi
    done
    tmux select-layout -t "$target_window" tiled >/dev/null 2>&1

    print "tmux session '$session' is ready. Run: tmux attach -t $session"
}
