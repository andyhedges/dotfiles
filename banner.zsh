# ~/.dotfiles/banner.zsh
autoload -Uz colors && colors

local branch last_pull
branch=$(git -C ~/.dotfiles rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git")
last_pull=$(git -C ~/.dotfiles log -1 --format='%cr' 2>/dev/null || echo "unknown")

# Total box width (visible chars, not counting colour codes)
local width=29

# Function to compute visible length (strip colour escapes)
strip_colors() {
  print -r -- "$1" | sed -E 's/%[FKfk]\{[^}]*\}//g; s/%[FKfk]//g'
}

# Function to print one line with colour and padding
banner_line() {
  local label="$1"
  local value="$2"
  local line="│ ${label}: ${value}"
  local visible=$(strip_colors "$line")
  local pad=$(( width - ${#visible} + 1 ))
  # Use print -P for colour expansion, and printf to pad the right side
  printf "%s%*s│\n" "$(print -P "$line")" "$pad" ""
}

print -P "╭─────────────────────────────╮"
print -P "│ Dotfiles loaded             │"
banner_line "Branch" "$branch"
banner_line "Updated" "$last_pull"
print -P "╰─────────────────────────────╯"
