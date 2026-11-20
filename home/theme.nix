# ═══════════════════════════════════════════════════════════════════════════
#  home/theme.nix  —  how GTK apps look (Nautilus, Loupe, file dialogs...)
# ═══════════════════════════════════════════════════════════════════════════
#
#  The same as your Fedora: Adwaita icons and cursor, Adwaita Sans, dark.
#  The COLOURS come from Noctalia, which recolours GTK apps from your
#  wallpaper (theme.templates in home/noctalia/default.nix).

{ pkgs, ... }:

{
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    icon-theme = "Adwaita";
    cursor-theme = "Adwaita";
    cursor-size = 24;
    font-name = "Adwaita Sans 11";
    document-font-name = "Adwaita Sans 11";
    monospace-font-name = "JetBrains Mono 11";
  };

  # The same cursor for X11 apps and anything that reads XCURSOR_*.
  home.pointerCursor = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    x11.enable = true;
  };
}
