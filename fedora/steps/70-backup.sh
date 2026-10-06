#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  steps/70-backup.sh  —  automatic, encrypted daily backups of your home
# ═══════════════════════════════════════════════════════════════════════════
#
#  NOT run by install.sh: it needs to know where the backups go.
#    ./steps/70-backup.sh /run/media/otari/<drive name>/restic   external drive
#    ./steps/70-backup.sh rclone:gdrive:backups/thinkpad         Google Drive (set up rclone first)
#    ./steps/70-backup.sh b2:<bucket-name>:thinkpad              Backblaze B2 (needs B2 keys in /etc/restic/home.env)
#
#  restic saves your home folder once a day (from modules/backup.nix):
#    • encrypted: without the password the copy is unreadable
#    • only changed parts are saved, so daily backups are small
#    • keeps 7 daily, 4 weekly and 6 monthly versions
#    • a day missed because the laptop was off runs at the next start
#
#  Useful commands afterwards:
#    sudo systemctl start restic-home     back up now
#    restic-home snapshots                list your backups
#    restic-home restore latest --target /tmp/restore --include ~/code

source "$(dirname "$0")/../lib.sh"

repo="${1:?usage: $0 <where>   e.g. /run/media/$USER/MyDrive/restic  (see the top of this file)}"

say "Backups (restic) to $repo"
dnf_install restic

sudo install -d -m 700 /etc/restic

# The password. Keep a copy OUTSIDE this laptop (a password manager):
# without it the backups can't be opened.
if ! sudo test -f /etc/restic/password; then
  sudo sh -c 'umask 077; openssl rand -base64 32 > /etc/restic/password'
  warn "Your backup password. Save it in a password manager NOW:"
  sudo cat /etc/restic/password
fi

sudo tee /etc/restic/home.env >/dev/null <<EOF
RESTIC_REPOSITORY=$repo
RESTIC_PASSWORD_FILE=/etc/restic/password
BACKUP_PATH=$HOME
EOF
sudo chmod 600 /etc/restic/home.env

# Big, rebuildable or temporary things: not worth backing up.
sudo tee /etc/restic/excludes >/dev/null <<EOF
$HOME/.cache
$HOME/.local/share/Trash
$HOME/.local/share/containers
$HOME/.npm
$HOME/.bun/install/cache
$HOME/.cargo/registry
$HOME/.rustup
$HOME/go/pkg/mod
$HOME/.config/Code/Cache*
$HOME/.config/Code/CachedData
$HOME/.var/app/*/cache
node_modules
.direnv
target
EOF

sudo tee /etc/systemd/system/restic-home.service >/dev/null <<'EOF'
[Unit]
Description=Back up the home folder with restic
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
EnvironmentFile=/etc/restic/home.env
ExecStart=/usr/bin/restic backup ${BACKUP_PATH} --exclude-file=/etc/restic/excludes --exclude-caches
ExecStartPost=/usr/bin/restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6
Nice=19
IOSchedulingClass=idle
EOF

sudo tee /etc/systemd/system/restic-home.timer >/dev/null <<'EOF'
[Unit]
Description=Daily home folder backup

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
EOF

# `restic-home <anything>` = restic with the settings above, e.g. `restic-home snapshots`.
sudo tee /usr/local/bin/restic-home >/dev/null <<'EOF'
#!/bin/sh
exec sudo sh -c 'set -a; . /etc/restic/home.env; exec restic "$@"' restic-home "$@"
EOF
sudo chmod 755 /usr/local/bin/restic-home

# Create the backup storage the first time.
restic-home cat config >/dev/null 2>&1 || restic-home init

sudo systemctl daemon-reload
sudo systemctl enable --now restic-home.timer

say "Running the first backup now (can take a while)"
sudo systemctl start restic-home.service
restic-home snapshots
