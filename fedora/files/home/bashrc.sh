# Your shell setup (from home.nix). Fedora's ~/.bashrc loads this file.

export EDITOR=nvim VISUAL=nvim
alias vi=nvim vim=nvim
alias ll='eza -la'
# Get the newest versions of everything (Fedora's version of `upgrade`).
alias upgrade='sudo dnf upgrade --refresh && flatpak update -y'

# Rust (rustup) and bun install into your home folder.
export PATH="$HOME/.cargo/bin:$HOME/.bun/bin:$PATH"

command -v zoxide >/dev/null && eval "$(zoxide init bash)"   # the `z` command
command -v direnv >/dev/null && eval "$(direnv hook bash)"   # per-project environments
# fzf: Ctrl+T file search (Ctrl+R is atuin's, below)
[ -f /usr/share/fzf/shell/key-bindings.bash ] && . /usr/share/fzf/shell/key-bindings.bash
command -v starship >/dev/null && eval "$(starship init bash)" # the prompt

# atuin: searchable history on Ctrl+R. Last, because it takes Ctrl+R over
# from fzf. The Up arrow keeps working the normal way.
if command -v atuin >/dev/null && [ -f ~/.local/share/bash-preexec.sh ]; then
  . ~/.local/share/bash-preexec.sh
  eval "$(atuin init bash --disable-up-arrow)"
fi
