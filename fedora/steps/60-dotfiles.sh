#!/usr/bin/env bash
# ── Your terminal setup: git, prompt, history, ghostty, bat, lazygit ──────
# The same settings as home.nix and home/*.nix, as plain config files.

source "$(dirname "$0")/../lib.sh"

say "Git"
git config --global user.name "Otari Pkhovelishvili"
git config --global user.email "opkhovelishvili@gmail.com"
git config --global init.defaultBranch main
git config --global push.autoSetupRemote true # first push of a new branch just works
git config --global pull.rebase true          # straight history on `git pull`
git config --global fetch.prune true          # forget branches deleted on GitHub
git config --global rerere.enabled true       # reuse how you fixed a conflict
git config --global merge.conflictStyle zdiff3
git config --global diff.algorithm histogram
# delta: colourful side-by-side diffs
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
git config --global delta.syntax-theme gruvbox-dark

say "Config files"
put_config bashrc.sh ~/.bashrc.d/otari.sh # Fedora's ~/.bashrc loads everything in ~/.bashrc.d
put_config starship.toml ~/.config/starship.toml
put_config ghostty ~/.config/ghostty/config
put_config atuin.toml ~/.config/atuin/config.toml
put_config bat ~/.config/bat/config
put_config lazygit.yml ~/.config/lazygit/config.yml
put_config tealdeer.toml ~/.config/tealdeer/config.toml

echo "  Open a new terminal to see the changes."
