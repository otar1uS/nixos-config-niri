#!/usr/bin/env bash
# ── GNOME: keyboard, touchpad, dark mode, screen lock ────────────────────
# Run from inside your GNOME session (gsettings changes the logged-in user).

source "$(dirname "$0")/../lib.sh"

say "GNOME settings"

if ! command -v gsettings >/dev/null || [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  missing "GNOME settings: run steps/50-gnome.sh again from inside GNOME"
  exit 0
fi

# Keyboard: English + Georgian, Alt+Shift switches (like niri's input.kdl).
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ge')]"
gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle']"
# Key repeat: starts after 300 ms, then 40 per second (= every 25 ms).
gsettings set org.gnome.desktop.peripherals.keyboard delay 'uint32 300'
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 'uint32 25'

# Touchpad: tap to click, natural scrolling, off while typing, a bit faster.
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.2

# Looks: dark mode, the terminal font for code.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'

# Screen sizes like 125% for the laptop screen (Settings -> Displays).
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'xwayland-native-scaling']"

# Screen off and locked after 10 minutes of not using the laptop.
gsettings set org.gnome.desktop.session idle-delay 'uint32 600'
gsettings set org.gnome.desktop.screensaver lock-enabled true
gsettings set org.gnome.desktop.screensaver lock-delay 'uint32 0'

# Electron apps (VS Code, Discord, Obsidian) as real Wayland apps: sharper text.
mkdir -p ~/.config/environment.d
echo 'ELECTRON_OZONE_PLATFORM_HINT=auto' >~/.config/environment.d/electron.conf
