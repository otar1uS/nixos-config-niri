# ═══════════════════════════════════════════════════════════════════════════
#  home/kanshi.nix  —  your screens: which are on, their size and speed
# ═══════════════════════════════════════════════════════════════════════════
#
#  kanshi is a small background program. It watches which screens are
#  connected, and when that changes it picks the first "profile" below
#  that fits EXACTLY (same number of screens) and applies it.
#
#  kanshi is the ONLY thing that sets up screens. Umbriel's config has no
#  [output] sections on purpose, so the two can never fight. (Umbriel speaks
#  the standard wlr-output-management protocol that kanshi uses.)
#
#  Two files:
#   • This file (from Nix, read-only): the profiles, i.e. WHICH screens are
#     on. Laptop alone = laptop on. Laptop + monitor = laptop off.
#   • ~/.config/kanshi/display.conf (yours, writable): each screen's size
#     (scale) and refresh rate. The Display panel in the bar (Super+Shift+D)
#     rewrites it when you tap a button. It's created below with good
#     defaults the first time, and a rebuild never overwrites it.

{ config, lib, pkgs, ... }:

let
  # Where the writable file lives.
  displayFile = "${config.xdg.configHome}/kanshi/display.conf";

  # Your screens, by the names kanshi knows them by. A monitor is named
  # "maker model serial" (see `wlr-randr` or `umbriel outputs`), so it is recognised on
  # any port. The laptop screen is simply "eDP-1".
  laptop = "eDP-1";
  dell = "Dell Inc. DELL S3425DW 3XFTR44";

  # The first version of display.conf. After that, the Display panel owns it.
  defaultDisplayConf = pkgs.writeText "display.conf" ''
    # Screen settings, written by the Display panel in the bar (Super+Shift+D).
    # One line per screen: output "<name>" [mode WIDTHxHEIGHT@HZ] [scale N]
    # Delete this file and rebuild to get the defaults back.
    output "${laptop}" scale 1.25
    output "${dell}" mode 3440x1440@120.000Hz scale 1.333333
  '';
in
{
  services.kanshi = {
    enable = true; # starts with the Umbriel session (graphical-session.target)

    settings = [
      # Read the per-screen settings first, so the profiles below use them.
      { include = displayFile; }

      # Profile 1: only the laptop screen is connected -> keep it on.
      {
        profile.name = "laptop-only";
        profile.outputs = [
          { criteria = laptop; status = "enable"; }
        ];
      }

      # Profile 2: laptop + your Dell -> laptop screen off, Dell on.
      {
        profile.name = "docked";
        profile.outputs = [
          { criteria = laptop; status = "disable"; }
          { criteria = dell; status = "enable"; }
        ];
      }

      # Profile 3: laptop + any OTHER monitor (a TV, a projector, at work...)
      # -> laptop screen off too. "*" = any monitor. Size changes for an
      # unknown monitor work, but are forgotten when you unplug it.
      {
        profile.name = "docked-other";
        profile.outputs = [
          { criteria = laptop; status = "disable"; }
          { criteria = "*"; status = "enable"; }
        ];
      }
    ];
  };

  # Create display.conf the first time only. kanshi refuses to start if a
  # file it includes is missing, so this must exist before kanshi runs.
  # `run` is Home Manager's helper that also prints the command in verbose
  # mode; "writeBoundary" means "after Home Manager has written its files".
  home.activation.kanshiDisplayDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${displayFile}" ]; then
      run mkdir -p "$(dirname "${displayFile}")"
      run install -m 644 ${defaultDisplayConf} "${displayFile}"
    fi
  '';
}
