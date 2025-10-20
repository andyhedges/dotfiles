#!/usr/bin/env bash
set -e

NERD_FONTS=("JetBrainsMono" "FiraCode")   # Add or remove as you like

REPO="https://github.com/andyhedges/dotfiles.git"
TARGET="$HOME/.dotfiles"

if [ ! -d "$TARGET/.git" ]; then
  echo "Cloning dotfiles..."
  git clone --depth=1 "$REPO" "$TARGET"
else
  echo "Updating dotfiles..."
  git -C "$TARGET" pull --ff-only
fi

# Symlink or source files as needed
if ! grep -q 'source ~/.dotfiles/.zshrc' "$HOME/.zshrc" 2>/dev/null; then
  echo 'source ~/.dotfiles/.zshrc' >> "$HOME/.zshrc"
  echo "linked ~/.dotfiles/.zshrc into ~/.zshrc"
fi


have_cmd() { command -v "$1" >/dev/null 2>&1; }

echo "=== Checking Homebrew ==="
if ! have_cmd brew; then
  echo "Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "=== Installing core packages (fzf, eza, jq) ==="
brew install fzf eza jq

FONT_DIR="$HOME/Library/Fonts"
mkdir -p "$FONT_DIR"

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

echo "=== Checking Nerd Fonts ==="
for f in "${NERD_FONTS[@]}"; do
  install_font "$f"
done

echo "=== Refreshing font cache ==="
fc-cache -fv >/dev/null 2>&1 || true

echo "🎉 Done."


echo "✅ Dotfiles installed or updated."