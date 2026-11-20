# ═══════════════════════════════════════════════════════════════════════════
#  home/yazi.nix  —  file manager INSIDE the terminal
# ═══════════════════════════════════════════════════════════════════════════
#
#  Fast, previews images/PDFs/videos right in foot. h/j/k/l move, Enter
#  opens, q quits, ~ shows help. Super+Y, or type `y` in a terminal: when
#  you quit, the terminal stays in the folder you were browsing.
#  Nautilus (Super+E) is the mouse-friendly one.

{ ... }:

{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };
}
