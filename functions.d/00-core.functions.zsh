

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

NERD_FONTS=("JetBrainsMono" "FiraCode")   # Add or remove as you like

have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_deps(){
  echo "=== Checking Homebrew ==="
  if ! have_cmd brew; then
    echo "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  echo "=== Installing core packages (fzf, eza) ==="
  brew install fzf eza

  FONT_DIR="$HOME/Library/Fonts"
  mkdir -p "$FONT_DIR"
}

install_font() {
  local font="$1"
  local font_file_pattern="${font// /}NerdFont*.ttf"

  if ls "$FONT_DIR"/$font_file_pattern >/dev/null 2>&1; then
    echo "✅ $font Nerd Font already installed"
    return
  fi

  echo "⬇️  Installing $font Nerd Font..."
  tmpdir=$(mktemp -d)
  curl -fsSL -o "$tmpdir/$font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
  unzip -q "$tmpdir/$font.zip" -d "$tmpdir/$font"
  cp "$tmpdir/$font"/*.ttf "$FONT_DIR"/
  rm -rf "$tmpdir"
  echo "✅ Installed $font Nerd Font"
}

install_fonts(){
  echo "=== Checking Nerd Fonts ==="
  for f in "${NERD_FONTS[@]}"; do
    install_font "$f"
  done

  echo "=== Refreshing font cache ==="
  fc-cache -fv >/dev/null 2>&1 || true
}

dotrefresh() {
  dotupdate && install_deps && install_fonts ||true        # don’t leak a non-zero into the restart
  unset __timer            # avoid showing a bogus elapsed time on first prompt
  exec zsh -l              # replace the shell; no return
}


