# ═══════════════════════════════════════════════════════════════════════════
#  modules/niri.nix  —  the SYSTEM side of your niri desktop
# ═══════════════════════════════════════════════════════════════════════════
#
#  This is a NixOS module: the same kind of file as configuration.nix.
#  It only holds things that belong to the whole MACHINE (need root):
#    - the login screen (Noctalia Greeter), which starts niri after your password
#    - install fonts for every app
#    - turn on background services the bar needs (battery, power modes)
#
#  Everything personal (shortcuts, colours, terminal) lives in ../home/.
#  niri is the only desktop on this machine.
#
#  Hooked up by the line  ./modules/niri.nix  in the `imports` list
#  at the top of configuration.nix.

# `lib` is Nix's toolbox of helper functions (here: lib.getExe', which
# builds the full path to a program inside a package).
{ lib, pkgs, ... }:

{
  # Turn niri on.
  # This installs niri, registers it as a desktop session, and sets up
  # "portals" (helpers that open file pickers and allow screen sharing)
  # plus a password keyring that apps like VS Code use to store logins.
  programs.niri.enable = true;

  # ── The login screen ──────────────────────────────────────────────────
  # greetd is a tiny login manager. The login box
  # it shows is Noctalia Greeter: written in C++, with its own built-in
  # mini display server, so it starts fast and needs nothing else. It looks
  # like your desktop: Noctalia copies your wallpaper, Gruvbox colours, font
  # and monitor layout to it ("sync", switched on in home/noctalia).
  # (It comes from unstable, see modules/unstable.nix: sync without a
  # password needs version 1.5 or newer; stable only has 1.3.)
  services.greetd = {
    enable = true;
    # `--user otari`: skip the user list, go straight to your password.
    # `--session Niri`: start niri after login (the only desktop here).
    settings.default_session.command =
      "${lib.getExe' pkgs.noctalia-greeter "noctalia-greeter-session"} -- --user otari --session Niri";
  };

  # The greeter's own settings (it reads /var/lib/noctalia-greeter/greeter.toml).
  # "tmpfiles" are files and folders systemd creates at every boot; "L+"
  # means: put a link there, pointing to the file generated from Nix.
  systemd.tmpfiles.settings."10-noctalia-greeter" = {
    "/var/lib/noctalia-greeter".d = {
      user = "greeter"; # greetd's own system user runs the login screen
      group = "greeter";
      mode = "0750";
    };
    "/var/lib/noctalia-greeter/greeter.toml"."L+".argument = toString (
      (pkgs.formats.toml { }).generate "greeter.toml" {
        # The same mouse cursor as on your desktop.
        cursor = {
          theme = "Bibata-Modern-Classic";
          size = 24;
          path = "${pkgs.bibata-cursors}/share/icons";
        };
        # English only at the login box, so your password always types the same.
        keyboard.layout = "us";
      }
    );
  };

  # Shows your profile picture on the login screen (if you set one in Noctalia).
  services.accounts-daemon.enable = true;

  # Let Noctalia copy its look to the login screen without asking for a
  # password. It may run only that one helper program, only for you, only
  # while you're sitting at this laptop. (Same rule as Noctalia Greeter's
  # own NixOS module in unstable.)
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.noctalia.greeter.sync-appearance" &&
          action.lookup("program") == "${lib.getExe' pkgs.noctalia-greeter "noctalia-greeter-apply-appearance"}" &&
          action.lookup("user") == "root" &&
          subject.user == "otari" && subject.local && subject.active) {
        return polkit.Result.YES;
      }
    });
  '';

  # dconf = a small settings database that GTK apps (like Nautilus) read.
  # home/theme.nix uses it to switch those apps to dark mode.
  programs.dconf.enable = true;

  # Battery information for the bar (percentage, time left, charging).
  services.upower.enable = true;

  # Power modes: Power Saver / Balanced / Performance.
  # The bar has a button to switch between them.
  services.power-profiles-daemon.enable = true;

  # Helpers for Nautilus: trash bin, USB sticks, phones, network folders.
  services.gvfs.enable = true;

  # Lets programs talk to monitors through the video cable (DDC/CI), so
  # Noctalia can change your Dell's own brightness. It loads the `i2c-dev`
  # driver and creates an "i2c" group that is allowed to use it.
  hardware.i2c.enable = true;

  # Your extra groups. This ADDS to your existing groups, it doesn't replace them.
  #   video = change the laptop screen's brightness without sudo
  #   i2c   = change the Dell's brightness through the cable (see above)
  # (New groups take effect after you log out and back in.)
  users.users.otari.extraGroups = [ "video" "i2c" ];

  # Fonts, installed system-wide so every program can find them.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono  # coding font WITH icons (bar + terminal use the icons)
    inter                      # clean, modern font for menus and normal text
    noto-fonts-color-emoji     # colour emoji
  ];

  # Small tools the desktop needs. Each one is explained on its line.
  environment.systemPackages = with pkgs; [
    xwayland-satellite  # runs old X11-only apps (Steam, some Electron apps) inside niri
    noctalia-greeter    # the login screen; also installs its sync helper + permission file
    nautilus            # GUI file manager. ALSO powers the "Open file..." dialogs in niri
    brightnessctl       # the brightness keys call this
    wl-clipboard        # copy/paste from the terminal: wl-copy, wl-paste
    playerctl           # play/pause/next keys for Spotify, Firefox, mpv...
    ddcutil             # Noctalia uses it to change the Dell's brightness (DDC/CI)
    # (cliphist used to be here: Noctalia v5 keeps clipboard history itself.)
  ];
}
