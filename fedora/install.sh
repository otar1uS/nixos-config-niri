#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  fedora/install.sh  —  set up a fresh Fedora Workstation like the old NixOS
# ═══════════════════════════════════════════════════════════════════════════
#
#  Runs every step in fedora/steps/ in order. Safe to run again: each step
#  skips what's already done. Any step can also be run on its own, e.g.
#    ./steps/30-thinkpad.sh
#
#  Run it as yourself (NOT with sudo), from inside your GNOME session:
#    ./install.sh

source "$(dirname "$0")/lib.sh"

: >"$MISSING"
sudo -v # ask for the password once, up front

for step in "$FEDORA_DIR"/steps/[0-6]*.sh; do
  bash "$step"
done

say "Done"
if [ -s "$MISSING" ]; then
  warn "These weren't installed (install them by hand, see README.md):"
  sed 's/^/    /' "$MISSING" >&2
fi
cat <<'EOF'

Next:
  1. Reboot once (turns on fan control and the docker group).
  2. gh auth login          (GitHub; git push then works without a password)
  3. Plug in the Dell, Super+P -> "External only"   (see README: Screens)
  4. Backups: ./steps/70-backup.sh <where>          (see README: Backups)
EOF
