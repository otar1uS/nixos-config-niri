# ═══════════════════════════════════════════════════════════════════════════
#  modules/unstable.nix  —  the desktop comes from the UNSTABLE channel
# ═══════════════════════════════════════════════════════════════════════════
#
#  The rule of this config:
#    • The DESKTOP (listed below) comes from nixos-unstable: newest versions.
#    • Everything else comes from stable (nixos-26.05): the system's base
#      (kernel, systemd, sound, network, greetd) and your apps
#      (Firefox, Ghostty, Nautilus, Discord...).
#    • Exception: a few apps that change very fast (VS Code), listed below.
#
#  Why not everything unstable? Your apps and the system base work fine on
#  stable and break less often. The desktop is where new versions bring
#  the features and fixes you notice. greetd (the small login manager under
#  the login screen) stays on stable on purpose: if it broke, you couldn't
#  log in at all. The login screen itself (Noctalia Greeter) is unstable,
#  to match Noctalia; if it ever fails, Ctrl+Alt+F2 still gives a text login.
#
#  How it works: an "overlay" swaps a package for another version
#  everywhere. After this, `pkgs.niri` means the unstable niri in EVERY
#  file (system and home), so niri's config check uses the same niri that
#  runs. Only small end-programs are swapped here, never basic libraries
#  that hundreds of other packages are built on: swapping those would make
#  Nix rebuild half the system on your laptop.
#
#  To move something else to unstable, add its name to the list below.

{ pkgs-unstable, ... }:

{
  nixpkgs.overlays = [
    # final/prev = the package set after/before this change ("prev.niri"
    # would be the stable one). `inherit (pkgs-unstable) a b;` is short for
    # `a = pkgs-unstable.a; b = pkgs-unstable.b;`.
    (final: prev: {
      inherit (pkgs-unstable)
        niri # the window manager itself
        xwayland-satellite # runs old X11 apps inside niri
        xdg-desktop-portal-gnome # screen sharing + "Open file" dialogs for niri
        noctalia # the bar, launcher, notifications, lock screen
        kanshi # turns screens on/off, sets their size
        noctalia-greeter # the login screen (stable's 1.3 is too old to sync with Noctalia 5.2)
        ;
    })

    # Apps that change fast and fall far behind on stable. (VS Code on
    # stable was 20 versions behind, and new extensions need new VS Code.)
    (final: prev: {
      inherit (pkgs-unstable)
        vscode
        ;
    })
  ];

  # The graphics driver (Mesa: the part that makes your AMD GPU draw) stays
  # on STABLE on purpose. Every program that draws with the GPU loads this
  # one driver, and the rule is: the driver must be the OLDEST version in
  # use. An older driver works inside newer programs (the desktop above),
  # but a newer driver breaks older programs: with the unstable driver,
  # Ghostty failed with "Failed to create EGL display".
  # (Tested: unstable niri + stable driver = hardware-accelerated, fine.)
  # So do NOT add `hardware.graphics.package = pkgs-unstable.mesa;` here.
}
