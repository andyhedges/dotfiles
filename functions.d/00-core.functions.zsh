#-- Dotfiles update and refresh functions ------------------------------------

log() { printf '\033[0;32m==>\033[0m %s\n' "$*"; }

NERD_FONTS=(
  "JetBrainsMono"
)

dotupdate() {
  local repo="$HOME/.dotfiles"
  if [[ ! -d "$repo/.git" ]]; then
    printf '%s\n' "No dotfiles repo at $repo" "Clone it with:" \
      "  git clone https://github.com/andyhedges/dotfiles.git \"$repo\""
    return 2
  fi
  printf '%s\n' "Updating dotfiles..."

  if command git -C "$repo" pull --quiet --ff-only; then
    printf '%s\n' "Dotfiles up to date."
    return 0
  else
    printf '%s\n' "Update failed. Resolve manually: cd \"$repo\" && git status"
    return 1
  fi
}

dotrefresh() {
  dotupdate || true
  install_deps || return
  install_fonts || return
  exec zsh -l 2>/dev/null
}


have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_deps(){
  if [[ "$OSTYPE" != darwin* ]]; then
    echo "install_deps currently supports macOS with Homebrew."
    return 2
  fi

  echo "=== Checking Homebrew ==="
  if ! have_cmd brew; then
    echo "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  if ! have_cmd brew; then
    echo "Homebrew is not available on PATH after installation." >&2
    return 1
  fi

  brew_install_if_missing eza
  brew_install_if_missing fzf
  brew_install_if_missing jq
  brew_install_if_missing tmux
  brew_install_if_missing kubectl

  FONT_DIR="${FONT_DIR:-$HOME/Library/Fonts}"
  mkdir -p "$FONT_DIR"
}

brew_install_if_missing() {
  local pkg="$1"
  if ! have_cmd "$pkg"; then
    brew install --quiet "$pkg"
  elif brew list --formula "$pkg" >/dev/null 2>&1; then
    log "$pkg is already installed via Homebrew."
  else
    log "$pkg is already installed."
  fi
}

# zsh-only, robust
font_installed() {
  emulate -L zsh
  setopt extended_glob

  local name="$1"
  # Map download name -> installed family prefix
  local alt
  case "$name" in
    CascadiaCode)  alt=CaskaydiaCove ;;
    SourceCodePro) alt=SauceCodePro  ;;
    Meslo)         alt=MesloLGS      ;;
    Terminus)      alt=Terminess     ;;
    TerminusTTF)   alt=TerminessTTF  ;;
    *)             alt="$name"       ;;
  esac

  local nospace="${name// /}"
  local altns="${alt// /}"

  # Build one alternation that covers all variants
  local pat="(${name}|${nospace}|${alt}|${altns})*NerdFont*.(ttf|otf)(N)"

  # Search user and system font dirs; (N) => no-match becomes empty, not an error
  local -a hits=(
    $HOME/Library/Fonts/$~pat
    /Library/Fonts/$~pat
  )

  (( ${#hits} > 0 ))
}


install_font() {
  local font="$1"
  local font_dir="${FONT_DIR:-$HOME/Library/Fonts}"

  if font_installed "$font"; then
    log "$font Nerd Font already installed"
    return 1
  fi

  mkdir -p "$font_dir" || return 2
  log "Installing $font Nerd Font..."
  local tmpdir
  tmpdir=$(mktemp -d) || return 2
  if ! curl -fsSL -o "$tmpdir/$font.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"; then
    rm -rf "$tmpdir"
    return 2
  fi
  if ! unzip -qq "$tmpdir/$font.zip" -d "$tmpdir/$font"; then
    rm -rf "$tmpdir"
    return 2
  fi

  local -a font_files=( "$tmpdir/$font"/*.(ttf|otf)(N) )
  if (( ${#font_files} == 0 )); then
    rm -rf "$tmpdir"
    printf '%s\n' "No font files found in $font.zip"
    return 2
  fi

  if ! cp "${font_files[@]}" "$font_dir"/; then
    rm -rf "$tmpdir"
    return 2
  fi
  rm -rf "$tmpdir"
  log "Installed $font Nerd Font"
  return 0
}

install_fonts(){
  if [[ "$OSTYPE" != darwin* ]]; then
    echo "install_fonts currently supports macOS font directories."
    return 2
  fi

  echo "=== Checking Nerd Fonts ==="
  local cache_invalid=0
  local failed=0
  for f in "${NERD_FONTS[@]}"; do
    install_font "$f"
    case $? in
      0) cache_invalid=1 ;;
      1) ;;
      *) failed=1 ;;
    esac
  done

  if (( cache_invalid == 1 )) && command -v fc-cache >/dev/null 2>&1; then
    echo "=== Refreshing font cache ==="
    fc-cache -fv >/dev/null 2>&1 || true
  fi

  (( failed == 0 ))
}
