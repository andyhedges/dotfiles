sshkh () {
	host=$(cat ~/.ssh/known_hosts | cut -f 1 -d " " | sort | uniq | fzf --prompt='ssh ❯ ') && ssh $host
}