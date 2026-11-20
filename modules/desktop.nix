# ═══════════════════════════════════════════════════════════════════════════
#  modules/desktop.nix  —  the SYSTEM side of the desktop
# ═══════════════════════════════════════════════════════════════════════════
#
#  Umbriel   the compositor: draws windows, scrolling layout like niri.
#  Noctalia  the shell: bar, launcher, notifications, lock screen, OSDs,
#            clipboard, wallpaper, polkit password box.
#  Noctalia Greeter  the login screen (on greetd), synced with Noctalia's look.
#
#  All three are built by the same team (noctalia-dev) and come from
#  nixos-unstable. Your personal settings for them are in home/umbriel and
#  home/noctalia.

{ pkgs, ... }:

{
  # ── Compositor ─────────────────────────────────────────────────────────
  # Installs Umbriel, registers the "Umbriel" login session, its systemd
  # session units, and xdg-desktop-portal-umbriel (screen sharing and
  # screenshots for Discord, Brave, OBS...).
  programs.umbriel.enable = true;

  # ── Shell ──────────────────────────────────────────────────────────────
  # Installs Noctalia plus the sound theme it uses. recommendedServices turns
  # on what its panels talk to: NetworkManager, Bluetooth, UPower (battery)
  # and power-profiles-daemon (Saver / Balanced / Performance).
  # Umbriel starts it (home/umbriel/general.nix).
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # ── Login screen ───────────────────────────────────────────────────────
  services.displayManager.noctalia-greeter = {
    enable = true;
    # Noctalia copies your wallpaper, colours and font to the login screen
    # when they change (shell.greeter_sync in home/noctalia). This lets it do
    # that without a password: only that one appearance helper, only for you,
    # only while you sit at the laptop.
    passwordlessSyncUsers = [ "otari" ];
    settings = {
      session.default = "umbriel"; # the session file umbriel.desktop
      user.default = "otari"; # straight to your password
      keyboard.layout = "us"; # your password always types the same
    };
    cursorTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  # The greeter finds sessions in /run/current-system/sw/share/wayland-sessions,
  # which NixOS doesn't link by default. Without this the login screen
  # would not list Umbriel.
  environment.pathsToLink = [ "/share/wayland-sessions" ];

  # Unlocks the password keyring (Brave, VS Codium, GitHub logins, SSH keys)
  # with your login password. Seahorse ("Passwords and Keys") shows what's in it.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  programs.seahorse.enable = true;

  # ── Portals ────────────────────────────────────────────────────────────
  # Umbriel's portal handles screen sharing; the GTK portal adds the
  # "Open file..." dialogs (Umbriel's portal config picks it automatically).
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Chromium/Electron apps (Brave, VS Codium, Discord, Obsidian) as real
  # Wayland apps: sharp text on scaled screens.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ── Desktop services ───────────────────────────────────────────────────
  programs.dconf.enable = true; # settings store for GTK apps (dark mode etc.)
  services.gvfs.enable = true; # Nautilus: trash, phones, network folders
  services.udisks2.enable = true; # USB sticks and drives mount with a click

  # Monitor brightness over the video cable (DDC/CI), so Noctalia's
  # brightness keys and slider also work on the Dell.
  hardware.i2c.enable = true;
  users.users.otari.extraGroups = [
    "video" # laptop backlight without sudo
    "i2c" # Dell brightness through the cable
  ];

  # Screen recording for Noctalia's recorder (bar button, Super+Alt+R) and
  # the GPU Screen Recorder app. The module adds the small privileged helper
  # it needs to capture the screen.
  programs.gpu-screen-recorder.enable = true;

  # LocalSend: AirDrop-style sharing with phones on the same Wi-Fi.
  # openFirewall opens its port (53317).
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    nautilus # file manager; also the file icons in "Open file..." dialogs
    brightnessctl # backlight from the terminal
    ddcutil # Dell brightness (Noctalia uses it)
    playerctl # play/pause for Spotify, Brave, mpv...
    wl-clipboard # wl-copy / wl-paste
    wlr-randr # list screens and their modes (the Display panel uses it)
    xdg-utils # xdg-open
    gpu-screen-recorder-gtk # the GPU Screen Recorder app (was a Flatpak on Fedora)
  ];

  # ── Fonts ──────────────────────────────────────────────────────────────
  fonts = {
    packages = with pkgs; [
      adwaita-fonts # Adwaita Sans / Mono: the GTK default, as on Fedora
      jetbrains-mono # terminal and Noctalia's font
      nerd-fonts.symbols-only # icons for the terminal, starship and yazi
      inter
      noto-fonts # includes Noto Sans Georgian
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf # metric-compatible Arial/Times for documents
      carlito # metric-compatible Calibri (LibreOffice)
      caladea # metric-compatible Cambria (LibreOffice)
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Adwaita Sans" ];
      monospace = [ "JetBrains Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
