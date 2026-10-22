_tmux_shell_quote() {
    emulate -L zsh
    print -r -- "${(qq)1}"
}

mrun() {
    # Run a command over SSH on multiple hosts in a tiled tmux window/session.
    if [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]]; then
        cat >&2 <<'EOF'
usage: mrun <host1> <host2> ... -- <command...>

Run a command over SSH on multiple hosts in a tiled tmux window/session.
EOF
        return 1
    fi
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
    local c host_q
    for c in "${cmd[@]}"; do
        remote_cmd+="$(_tmux_shell_quote "$c") "
    done

    local window_id session_name first_pane new_pane i

    if [[ -n "$TMUX" ]]; then
        # already in tmux: create a brand new window and grab its id
        window_id=$(tmux new-window -P -F '#{window_id}' -n "mrun")
        first_pane=$(tmux list-panes -t "$window_id" -F '#{pane_id}' | head -n1)

        # run first host in first pane
        host_q=$(_tmux_shell_quote "${hosts[1]}")
        tmux send-keys -t "$first_pane" "ssh -- $host_q ${remote_cmd}" C-m

        # split for the remaining hosts
        for ((i=2; i<=${#hosts[@]}; i++)); do
            new_pane=$(tmux split-window -t "$window_id" -v -P -F '#{pane_id}')
            host_q=$(_tmux_shell_quote "${hosts[i]}")
            tmux send-keys -t "$new_pane" "ssh -- $host_q ${remote_cmd}" C-m
            tmux select-layout -t "$window_id" tiled >/dev/null
        done

        tmux select-window -t "$window_id"
        tmux select-layout -t "$window_id" tiled >/dev/null
    else
        # not in tmux: create a detached session
        session_name="mrun-$$"
        window_id=$(tmux new-session -d -s "$session_name" -P -F '#{window_id}')
        first_pane=$(tmux list-panes -t "$window_id" -F '#{pane_id}' | head -n1)

        host_q=$(_tmux_shell_quote "${hosts[1]}")
        tmux send-keys -t "$first_pane" "ssh -- $host_q ${remote_cmd}" C-m

        for ((i=2; i<=${#hosts[@]}; i++)); do
            new_pane=$(tmux split-window -t "$window_id" -v -P -F '#{pane_id}')
            host_q=$(_tmux_shell_quote "${hosts[i]}")
            tmux send-keys -t "$new_pane" "ssh -- $host_q ${remote_cmd}" C-m
            tmux select-layout -t "$window_id" tiled >/dev/null
        done

        tmux select-layout -t "$window_id" tiled >/dev/null
        tmux attach-session -t "$session_name"
    fi
}

_mssh_cmd () {
    print -r -- "ssh -- ${(q)1}; echo; echo \"[ssh to ${(q)1} exited \$?] press enter to close\"; read _"
}

mssh () {
    if [[ $# -eq 0 || $1 == -h || $1 == --help ]]; then
        echo "usage: mssh <host1> <host2> ..." >&2
        return 1
    fi

    local session_name pane host

    if [[ -n $TMUX ]]; then
        pane=$(tmux new-window -P -F '#{pane_id}' -n mssh "$(_mssh_cmd $1)") || return
    else
        session_name="mssh-$$"
        pane=$(tmux new-session -d -s "$session_name" -n mssh -P -F '#{pane_id}' "$(_mssh_cmd $1)") || return
    fi
    tmux select-pane -t "$pane" -T "$1"

    for host in "${@:2}"; do
        local new_pane
        new_pane=$(tmux split-window -t "$pane" -P -F '#{pane_id}' "$(_mssh_cmd $host)") || break
        tmux select-pane -t "$new_pane" -T "$host"
        tmux select-layout -t "$pane" tiled > /dev/null
    done

    tmux set-window-option -t "$pane" pane-border-status top > /dev/null
    tmux set-window-option -t "$pane" pane-border-format ' #{pane_title} ' > /dev/null
    tmux set-window-option -t "$pane" synchronize-panes on > /dev/null
    tmux select-pane -t "$pane"

    if [[ -n $TMUX ]]; then
        tmux select-window -t "$pane"
    else
        tmux attach-session -t "$session_name"
    fi
}
