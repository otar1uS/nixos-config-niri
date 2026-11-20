# ═══════════════════════════════════════════════════════════════════════════
#  modules/backup.nix  —  automatic, encrypted backups of your home folder
# ═══════════════════════════════════════════════════════════════════════════
#
#  STATUS: prepared, but OFF until you choose where backups go.
#
#  restic (a popular backup tool) saves your home folder once a day:
#    • encrypted: without your backup password the copy is unreadable
#    • de-duplicated: only changed parts are saved, so daily backups are small
#    • keeps 7 daily, 4 weekly and 6 monthly versions, so you can go back
#    • runs even if the laptop was off at the scheduled time (catches up)
#
#  To switch it on, two steps:
#   1. Create the backup password (once; keep a copy somewhere safe, e.g. a
#      password manager: without it, the backups can't be opened):
#        sudo sh -c 'umask 077; openssl rand -base64 32 > /root/restic-password'
#        sudo cat /root/restic-password
#   2. Set `repository` below and rebuild. Examples:
#        External drive:  "/run/media/otari/<drive name>/restic"
#        Google Drive:    "rclone:gdrive:backups/thinkpad"  (needs rclone setup)
#        Backblaze B2:    "b2:<bucket-name>:thinkpad"       (needs B2 keys)
#
#  Useful commands once it's on:
#    sudo systemctl start restic-backups-home    run a backup now
#    sudo restic-home snapshots                   list your backups
#    sudo restic-home restore latest --target /tmp/restore --include /home/otari/Documents

{ lib, ... }:

let
  # ── Where backups go. null = backups are off. ─────────────────────────
  repository = null;
in
{
  services.restic.backups.home = lib.mkIf (repository != null) {
    inherit repository;
    passwordFile = "/root/restic-password"; # NOT in git: secrets don't belong in a repo
    initialize = true; # create the backup storage on the first run

    paths = [ "/home/otari" ];

    # Things that are big, rebuildable or temporary: not worth backing up.
    exclude = [
      "/home/otari/.cache" # app caches
      "/home/otari/.local/share/Trash"
      "/home/otari/.local/state/nix" # Nix profiles: rebuilt from this config
      "/home/otari/.npm"
      "/home/otari/.bun/install/cache"
      "/home/otari/.local/share/pnpm/store"
      "/home/otari/.cargo/registry"
      "/home/otari/.rustup"
      "/home/otari/go/pkg/mod"
      "/home/otari/.config/Code/Cache*"
      "/home/otari/.config/Code/CachedData"
      "node_modules" # project dependencies: `npm install` brings them back
      ".direnv" # per-project Nix environments
      "target" # Rust build output
      "result" # Nix build links
      "/home/otari/code/*/Library" # Unity's rebuildable caches (often several GB)
      "/home/otari/code/*/Temp"
      "/home/otari/code/*/Logs"
    ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true; # missed because the laptop was off? Run at next boot
      RandomizedDelaySec = "1h";
    };

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];

    createWrapper = true; # gives the `restic-home` command (see above)
  };
}
