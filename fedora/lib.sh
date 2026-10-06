# ═══════════════════════════════════════════════════════════════════════════
#  fedora/lib.sh  —  small helpers shared by every step (sourced, not run)
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

FEDORA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES="$FEDORA_DIR/files"

# Everything that couldn't be installed is written here, and install.sh
# prints the list at the end, so one missing package never stops the rest.
MISSING="${XDG_RUNTIME_DIR:-/tmp}/fedora-setup-missing.txt"

say() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;31m  ! %s\033[0m\n' "$*" >&2; }
missing() { warn "$*"; echo "$*" >>"$MISSING"; }

if [ "$(id -u)" = 0 ]; then
  echo "Run this as yourself, not with sudo. It asks for your password when needed." >&2
  exit 1
fi

# Install with dnf. Names Fedora doesn't have are skipped, then reported.
dnf_install() {
  sudo dnf install -y --skip-unavailable "$@"
  local p
  for p in "$@"; do
    rpm -q --whatprovides "$p" &>/dev/null || missing "dnf package not found: $p"
  done
}

# Install apps from Flathub (the app store Fedora's Software app also uses).
flatpak_install() {
  local app
  for app in "$@"; do
    flatpak install -y --noninteractive flathub "$app" || missing "flatpak not installed: $app"
  done
}

# Copy a system file into place (root-owned).
put_system() { # put_system <file in files/system> <destination> [mode]
  sudo install -D -m "${3:-644}" "$FILES/system/$1" "$2"
}

# Copy one of your config files into place. An existing, different file is
# kept as <name>.bak instead of being overwritten.
put_config() { # put_config <file in files/home> <destination>
  local src="$FILES/home/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
    mv "$dest" "$dest.bak"
    echo "  kept your old $dest as $dest.bak"
  fi
  cp "$src" "$dest"
}
