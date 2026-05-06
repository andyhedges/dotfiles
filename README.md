# dotfiles

Personal zsh configuration, aliases, and shell utilities.

The setup is designed to stay small, quick to load, and reproducible across machines. It is customized to my preferences, but you are welcome to use or modify it under the terms of the license.

## Contents

| Path | Purpose |
| --- | --- |
| `.zshrc` | Core zsh setup, prompt, history, completion, auto-update, and loaders. |
| `aliases.d/*.aliases.zsh` | Alias bundles loaded in lexical order. |
| `functions.d/*.functions.zsh` | Function bundles loaded in lexical order. |
| `banner.zsh` | Optional login banner with dotfiles branch/update information. |
| `install.sh` | Bootstrap script that clones or updates the repo and sources it from `~/.zshrc`. |
| `scripts/check.sh` | Local syntax check for the bash and zsh files. |

## Quick Install

Run this once on a new machine:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/andyhedges/dotfiles/main/install.sh)"
```

The installer clones the repo to `~/.dotfiles`, updates it with `git pull --ff-only` on later runs, and adds a small source block to `~/.zshrc` if one is not already present.

Then reload your shell:

```bash
exec zsh
```

## Local Checks

```bash
bash scripts/check.sh
```

The check script runs `bash -n` for `install.sh` and `zsh -n` for the zsh config, aliases, functions, and banner.
