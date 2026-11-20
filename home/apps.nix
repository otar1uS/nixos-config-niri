# ═══════════════════════════════════════════════════════════════════════════
#  home/apps.nix  —  desktop apps, and which app opens what
# ═══════════════════════════════════════════════════════════════════════════
#
#  Everything that was a Flatpak on Fedora (Discord, VSCodium, qBittorrent,
#  GPU Screen Recorder, LocalSend) is a normal Nix package here: updates come
#  with `upgrade`, and they see your fonts, theme and file system normally.
#  (LocalSend and GPU Screen Recorder are in modules/desktop.nix: they need
#  a firewall port / a screen-capture helper.)

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── browsing and chat ──
    brave # your default browser (Firefox is in configuration.nix)
    discord
    telegram-desktop

    # ── work ──
    vscodium
    obsidian
    libreoffice-fresh # newest LibreOffice
    unityhub # your Unity 6 projects in ~/code (Star-Blaster, Snow-Surfr...)

    # ── media ──
    celluloid # video player
    loupe # image viewer
    ncspot # Spotify in the terminal
    pavucontrol # detailed sound settings
    qbittorrent
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      let
        browser = "brave-browser.desktop";
        video = "io.github.celluloid_player.Celluloid.desktop";
        image = "org.gnome.Loupe.desktop";
      in
      {
        "text/html" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;
        # Claude Code's login links. It writes the .desktop file itself, but
        # can't edit this (Nix-managed) list, so the entry lives here.
        "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
        "application/pdf" = browser;
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "video/mp4" = video;
        "video/x-matroska" = video;
        "video/webm" = video;
        "image/png" = image;
        "image/jpeg" = image;
        "image/webp" = image;
        "image/gif" = image;
      };
  };
}
