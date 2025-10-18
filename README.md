# dotfiles

Personal zsh configuration, aliases, and shell utilities.  
Designed to be fast, minimal, and reproducible across machines.

They are customised to my preferences but you are welcome to use or modify (see LICENSE for more info).

Please feel free to make suggestions via pull requests or 'issues'.

---

## 🧩 Contents

| File | Purpose |
|------|----------|
| `.zshrc` | Core shell setup (sources aliases/functions, configures history, prompt, etc.) |
| `.aliases` | Common commands and safe defaults (`ll`, `gs`, `untar`, etc.) |
| `.functions` | Utility functions (`extract`, `mkcd`, etc.) |
| `install.sh` | Bootstrap script to install or update the dotfiles automatically |

---

## ⚡️ Quick install

Run this once on any new machine:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/andyhedges/dotfiles/main/install.sh)"
