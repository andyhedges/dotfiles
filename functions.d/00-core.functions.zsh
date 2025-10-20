#-- Dotfiles update and refresh functions ------------------------------------

log() { echo -e "\033[0;32m==>\033[0m $*"; }

NERD_FONTS=(
  "JetBrainsMono"
  "FiraCode"
  "CascadiaCode"
  # "Iosevka"
  # "Hack"
  # "SourceCodePro"
  # "UbuntuMono"
  # "Meslo"
  # "Mononoki"
  # "VictorMono"
  # "RobotoMono"
  # "Terminus"
  # "AnonymousPro"
  # "Inconsolata"
  # "DejaVuSansMono"
  # "NotoSansMono"
  # "IBM Plex Mono"
  # "GoMono"
  # "SpaceMono"
  # "Hermit"
  # "3270"
  # "Agave"
  # "CodeNewRoman"
  # "DaddyTimeMono"
  # "BigBlueTerminal"
  # "Gohu"
  # "ProFont"
  # "RecursiveMono"
  # "ShureTechMono"
  # "Tinos"
  # "Ubuntu"
  # "OverpassMono"
)


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

have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_deps(){
  echo "=== Checking Homebrew ==="
  if ! have_cmd brew; then
    echo "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  brew_install_if_missing eza
  brew_install_if_missing fzf
  brew_install_if_missing jq

  FONT_DIR="$HOME/Library/Fonts"
  mkdir -p "$FONT_DIR"
}

brew_install_if_missing() {
  local pkg="$1"
  if ! have_cmd $pkg; then
    brew install --quiet $pkg
  elif brew list --formula | grep -q "^$pkg\$"; then
    log "$pkg is already installed via Homebrew."
  else
    log "$pkg is already installed."
  fi
}

font_installed() {
  emulate -L zsh              # local zsh semantics and options
  setopt extended_glob        # enables glob qualifiers like (N)

  local name="$1"
  local nospace="${name// /}"
  local files=()

  # Search user and system font dirs; (N) => expand to nothing if no match
  files+=("$HOME/Library/Fonts"/*${name}*Nerd*Font*.(ttf|otf)(N))
  files+=("$HOME/Library/Fonts"/*${nospace}*Nerd*Font*.(ttf|otf)(N))
  files+=("/Library/Fonts"/*${name}*Nerd*Font*.(ttf|otf)(N))
  files+=("/Library/Fonts"/*${nospace}*Nerd*Font*.(ttf|otf)(N))

  (( ${#files} > 0 ))
}

install_font() {
  local font="$1"
  if font_installed "$font"; then
    log "$font Nerd Font already installed"
    return 1
  fi

  log "Installing $font Nerd Font..."
  local tmpdir
  tmpdir=$(mktemp -d)
  curl -fsSL -o "$tmpdir/$font.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
  unzip -qq "$tmpdir/$font.zip" -d "$tmpdir/$font"
  cp "$tmpdir/$font"/*.ttf "$FONT_DIR"/
  rm -rf "$tmpdir"
  log "Installed $font Nerd Font"
  return 0
}

install_fonts(){
  echo "=== Checking Nerd Fonts ==="
  local cache_invalid=0
  for f in "${NERD_FONTS[@]}"; do
    if install_font "$f"; then
      cache_invalid=1
    fi
  done

  if [ "$changed" -eq 1 ] && command -v fc-cache >/dev/null 2>&1; then
    echo "=== Refreshing font cache ==="
    fc-cache -fv >/dev/null 2>&1 || true
  fi
}

dotrefresh() {
  dotupdate && install_deps && install_fonts ||true        # don’t leak a non-zero into the restart
  unset __timer            # avoid showing a bogus elapsed time on first prompt
  exec zsh -l              # replace the shell; no return
}


