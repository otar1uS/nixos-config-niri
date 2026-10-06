# ═══════════════════════════════════════════════════════════════════════════
#  home/yazi.nix  —  file manager INSIDE the terminal
# ═══════════════════════════════════════════════════════════════════════════
#
#  Yazi is a very fast terminal file manager written in Rust.
#  It previews images, PDFs, videos and code right in Ghostty.
#  Use it with the keyboard: h/j/k/l to move, Enter to open, q to quit,
#  ~ for help. Open it with Super+Y, or type `yazi` in a terminal.
#
#  Nautilus (installed in modules/niri.nix) is the GUI file manager
#  for when you want to use the mouse. Super+E opens it.

{ ... }:

{
  programs.yazi = {
    enable = true;

    # Adds a small shell helper, so that when you QUIT Yazi, your terminal
    # stays in the folder you were browsing (normally it would jump back).
    enableBashIntegration = true;
  };
}
