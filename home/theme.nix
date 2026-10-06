# ═══════════════════════════════════════════════════════════════════════════
#  home/theme.nix  —  how GTK apps look (Nautilus, Loupe, file dialogs...)
# ═══════════════════════════════════════════════════════════════════════════
#
#  GTK apps read their look from dconf, a settings database.
#  dconf.settings writes values into it. The path
#  "org/gnome/desktop/interface" is just the folder these keys live in.
#
#  Home Manager writes these keys every time you rebuild, so they can't
#  drift (an old KDE value, icon-theme = "breeze-dark", pointed at a theme
#  that no longer exists and gave Nautilus broken icons).
#  The colours come from Noctalia (Gruvbox), see home/noctalia/default.nix.

{ pkgs, ... }:

{
  home.packages = [
    # The icon theme: Gruvbox Plus, made for the Gruvbox colours.
    # (It carries its own copy of the "breeze-dark" icons as a fallback for
    # the few icons it doesn't draw itself. That's just pictures, not KDE.)
    pkgs.gruvbox-plus-icons
    # GNOME's standard icons, as a last fallback: GTK apps always look
    # there when a theme is missing an icon.
    pkgs.adwaita-icon-theme
  ];

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";                    # dark mode for GTK apps
    icon-theme = "Gruvbox-Plus-Dark";                # folder and app icons (installed above)
    cursor-theme = "Bibata-Modern-Classic";          # same cursor as niri
    cursor-size = 24;
    font-name = "Inter 11";                          # menus and labels
    document-font-name = "Inter 11";                 # text in documents (KDE had left "Inter  10")
    monospace-font-name = "JetBrainsMono Nerd Font 11";  # code/terminal text
    toolbar-style = "both-horiz";                    # icons with labels (KDE had left "text only")
  };
}
