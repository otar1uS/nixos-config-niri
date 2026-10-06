#!/usr/bin/env bash
# ── Your programs: the same list as configuration.nix + home.nix ──────────

source "$(dirname "$0")/../lib.sh"

say "Packages (dnf)"
packages=(
  # the basics
  git wget curl unzip zip tree file htop btop ripgrep fd-find fzf jq yq bat eza zoxide tmux
  neovim direnv wl-clipboard
  # git
  gh lazygit git-delta
  # terminal
  ghostty starship atuin tealdeer lftp
  # editor
  code
  # JavaScript / TypeScript
  nodejs nodejs-npm pnpm typescript
  # Python
  python3 uv ruff
  # other languages
  golang rustup gcc make
  # containers
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin lazydocker
  # Kubernetes
  kubernetes-client helm kubectx
  # infrastructure as code
  opentofu ansible
  # databases (valkey = Fedora's Redis)
  postgresql pgcli sqlite valkey
  # HTTP, secrets
  xh sops age
  # desktop apps
  snapshot v4l-utils ncspot
  # fonts, Georgian date/number formats, backups
  jetbrains-mono-fonts-all glibc-langpack-ka restic
)
dnf_install "${packages[@]}"

say "Codecs and AMD hardware video decoding (RPM Fusion)"
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing || missing "codec swap: ffmpeg"
sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld --allowerasing || missing "codec swap: mesa-va-drivers-freeworld"

say "Apps (Flathub)"
flatpak_install com.discordapp.Discord org.telegram.desktop md.obsidian.Obsidian hu.irl.cameractrls

say "Tools that aren't packaged for Fedora"
mkdir -p ~/.local/bin

if ! command -v kind >/dev/null; then
  curl -fsSLo ~/.local/bin/kind https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-linux-amd64 &&
    chmod +x ~/.local/bin/kind || missing "kind (https://kind.sigs.k8s.io)"
fi

if ! command -v k9s >/dev/null; then
  sudo dnf install -y https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.rpm ||
    missing "k9s (https://k9scli.io)"
fi

if ! command -v tofu >/dev/null; then
  installer=$(mktemp)
  curl -fsSLo "$installer" https://get.opentofu.org/install-opentofu.sh &&
    sh "$installer" --install-method rpm || missing "opentofu (https://opentofu.org/docs/intro/install)"
  rm -f "$installer"
fi

if ! command -v bun >/dev/null; then
  curl -fsSL https://bun.sh/install | bash || missing "bun (https://bun.sh)"
fi

if [ ! -x ~/.cargo/bin/rustc ] && command -v rustup-init >/dev/null; then
  rustup-init -y --no-modify-path # PATH is set in ~/.bashrc.d/otari.sh
fi

if ! command -v claude >/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash || missing "claude code (https://claude.com/claude-code)"
fi

# atuin needs this small helper to see each command in bash.
if [ ! -f ~/.local/share/bash-preexec.sh ]; then
  curl -fsSLo ~/.local/share/bash-preexec.sh \
    https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh ||
    missing "bash-preexec (atuin's Ctrl+R needs it)"
fi

# The terminal font with icons (JetBrains Mono, "Nerd Font" version).
if ! fc-list | grep -q "JetBrainsMono Nerd Font"; then
  mkdir -p ~/.local/share/fonts/JetBrainsMonoNerd
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz |
    tar -xJ -C ~/.local/share/fonts/JetBrainsMonoNerd && fc-cache -f ||
    missing "JetBrainsMono Nerd Font (https://www.nerdfonts.com)"
fi
