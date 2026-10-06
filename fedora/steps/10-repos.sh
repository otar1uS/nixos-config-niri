#!/usr/bin/env bash
# ── Extra places to get software from ─────────────────────────────────────
#   RPM Fusion   full video codecs (ffmpeg), AMD hardware video decoding
#   Microsoft    VS Code
#   Docker       the real Docker (Fedora ships Podman by default)
#   COPR         community builds: ghostty, starship, lazygit, lazydocker
#   Flathub      Discord, Telegram, Obsidian, Camera Settings

source "$(dirname "$0")/../lib.sh"

say "Repositories"

fedora=$(rpm -E %fedora)
sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$fedora.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$fedora.noarch.rpm"

if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
fi

if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
  sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
fi

for copr in scottames/ghostty atim/starship atim/lazygit atim/lazydocker; do
  sudo dnf copr enable -y "$copr" || missing "COPR not enabled: $copr"
done

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
