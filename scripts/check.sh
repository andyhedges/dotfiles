#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

bash -n install.sh

zsh_files=(
  .zshrc
  banner.zsh
  aliases.d/*.zsh
  functions.d/*.zsh
)

for file in "${zsh_files[@]}"; do
  zsh -n "$file"
done

echo "syntax checks passed"
