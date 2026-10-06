#!/usr/bin/env bash
# ── ThinkPad: battery charging modes, fan modes, lid LED ──────────────────
#   battery-charge-mode [desk | daily | travel]
#   thinkpad [fan auto|charger|max] [led off|on|charging]
# Same commands as on NixOS (modules/battery.nix, modules/thinkpad.nix).

source "$(dirname "$0")/../lib.sh"

say "ThinkPad: battery modes, fan, LED"

put_system battery-charge-mode /usr/local/bin/battery-charge-mode 755
put_system thinkpad /usr/local/bin/thinkpad 755

for unit in battery-charge@.service battery-charge-restore.service \
  thinkpad-set@.service thinkpad-apply.service; do
  put_system "$unit" "/etc/systemd/system/$unit"
done

put_system 50-thinkpad-modes.rules /etc/polkit-1/rules.d/50-thinkpad-modes.rules
put_system 90-thinkpad-ac.rules /etc/udev/rules.d/90-thinkpad-ac.rules
put_system thinkpad_acpi.conf /etc/modprobe.d/thinkpad_acpi.conf

sudo systemctl daemon-reload
sudo udevadm control --reload
sudo systemctl enable battery-charge-restore.service thinkpad-apply.service

# Start in Desk mode the first time (35-40%: plugged in all day).
if ! sudo test -f /var/lib/thinkpad/battery; then
  sudo systemctl start battery-charge@desk.service
fi
battery-charge-mode

# GNOME has its own on/off charge limit ("Preserve Battery Health" in
# Settings -> Power). Leave it OFF, or it and battery-charge-mode will keep
# overwriting each other's numbers.
