sshkh () {
	local host
	if [[ ! -r "$HOME/.ssh/known_hosts" ]]; then
		echo "sshkh: no readable known_hosts file" >&2
		return 1
	fi
	if ! command -v fzf >/dev/null 2>&1; then
		echo "sshkh: fzf is not installed" >&2
		return 1
	fi

	host=$(cut -f 1 -d " " "$HOME/.ssh/known_hosts" | sort -u | fzf --prompt='ssh > ') || return
	[[ -n "$host" ]] && ssh -- "$host"
}
