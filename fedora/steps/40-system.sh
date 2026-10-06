#!/usr/bin/env bash
# ── System settings: time, Georgian formats, docker, webcam, kernel ───────

source "$(dirname "$0")/../lib.sh"

say "Time zone and formats (English language, Georgian dates/numbers)"
sudo timedatectl set-timezone Asia/Tbilisi
sudo localectl set-locale LANG=en_US.UTF-8 \
  LC_ADDRESS=ka_GE.UTF-8 LC_IDENTIFICATION=ka_GE.UTF-8 LC_MEASUREMENT=ka_GE.UTF-8 \
  LC_MONETARY=ka_GE.UTF-8 LC_NAME=ka_GE.UTF-8 LC_NUMERIC=ka_GE.UTF-8 \
  LC_PAPER=ka_GE.UTF-8 LC_TELEPHONE=ka_GE.UTF-8 LC_TIME=ka_GE.UTF-8

say "Kernel settings (swap, file watchers)"
put_system 90-otari.conf /etc/sysctl.d/90-otari.conf
sudo sysctl --system >/dev/null

say "Webcam: hide the duplicate and infrared cameras"
put_system 10-webcam-v4l2-only.conf /etc/wireplumber/wireplumber.conf.d/10-webcam-v4l2-only.conf
systemctl --user restart wireplumber 2>/dev/null || true

say "Docker"
if rpm -q docker-ce &>/dev/null; then
  sudo systemctl enable --now docker
  # Members of "docker" can effectively act as root (like on NixOS).
  # Remove this line if you'd rather type `sudo docker`.
  sudo usermod -aG docker "$USER"
fi

say "Firmware updates (BIOS, Thunderbolt...) from Lenovo"
fwupdmgr refresh --force >/dev/null 2>&1 || true
fwupdmgr get-updates || true # only lists them; install with: fwupdmgr update
