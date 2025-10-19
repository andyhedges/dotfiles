

#-- Dotfiles update and refresh functions ------------------------------------

dotupdate() {
  local repo="$HOME/.dotfiles"
  if [[ ! -d "$repo/.git" ]]; then
    printf '%s\n' "No dotfiles repo at $repo" "Clone it with:" \
      "  git clone https://github.com/andyhedges/dotfiles.git \"$repo\""
    return 2
  fi
  printf '%s\n' "Updating dotfiles..."
  if git -C "$repo" pull --quiet --ff-only; then
    printf '%s\n' "Dotfiles up to date."
    return 0
  else
    printf '%s\n' "Update failed. Resolve manually: cd \"$repo\" && git status"
    return 1
  fi
}

dotrefresh() {
  dotupdate || true        # don’t leak a non-zero into the restart
  unset __timer            # avoid showing a bogus elapsed time on first prompt
  exec zsh -l              # replace the shell; no return
}
