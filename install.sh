#!/usr/bin/env bash
set -e

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

echo "✅ Dotfiles installed or updated."