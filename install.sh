#!/usr/bin/env bash
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/andyhedges/dotfiles.git}"
TARGET="${DOTFILES_TARGET:-$HOME/.dotfiles}"
ZSHRC="$HOME/.zshrc"
BEGIN_MARKER="# >>> dotfiles >>>"
END_MARKER="# <<< dotfiles <<<"

if [ "$TARGET" = "$HOME/.dotfiles" ]; then
  SOURCE_LINE='source "$HOME/.dotfiles/.zshrc"'
else
  printf -v SOURCE_PATH '%q' "$TARGET/.zshrc"
  SOURCE_LINE="source $SOURCE_PATH"
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install these dotfiles." >&2
  exit 1
fi

if [ -e "$TARGET" ] && [ ! -d "$TARGET/.git" ]; then
  echo "$TARGET already exists but is not a git repository." >&2
  exit 1
fi

if [ ! -d "$TARGET/.git" ]; then
  echo "Cloning dotfiles..."
  git clone --depth=1 "$REPO" "$TARGET"
else
  echo "Updating dotfiles..."
  git -C "$TARGET" pull --ff-only
fi

touch "$ZSHRC"

if grep -Fqx "$BEGIN_MARKER" "$ZSHRC"; then
  echo "dotfiles source block already present in ~/.zshrc"
elif grep -Fq 'source ~/.dotfiles/.zshrc' "$ZSHRC" ||
     grep -Fq 'source "$HOME/.dotfiles/.zshrc"' "$ZSHRC" ||
     grep -Fqx "$SOURCE_LINE" "$ZSHRC"; then
  echo "dotfiles source line already present in ~/.zshrc"
else
  {
    printf '\n%s\n' "$BEGIN_MARKER"
    printf '%s\n' "$SOURCE_LINE"
    printf '%s\n' "$END_MARKER"
  } >> "$ZSHRC"
  echo "linked ~/.dotfiles/.zshrc into ~/.zshrc"
fi

echo "✅ Dotfiles installed or updated."
