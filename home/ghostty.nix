# ═══════════════════════════════════════════════════════════════════════════
#  home/ghostty.nix  —  the terminal
# ═══════════════════════════════════════════════════════════════════════════
#
#  Ghostty is a fast, GPU-accelerated terminal written in Zig.
#  It shows images (Yazi previews!), has tabs and splits built in,
#  and ships hundreds of colour themes.
#
#  Home Manager writes ~/.config/ghostty/config from the settings below.
#  Each setting here = one line in that file.

{ ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      # Colours. Check the exact name with:
      #   ghostty +list-themes | grep -i gruvbox
      # (Older Ghostty versions spell it "GruvboxDark", without the space.)
      theme = "Gruvbox Dark";

      # The Nerd Font installed in modules/niri.nix.
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;

      # 0.95 = 5% see-through background.
      background-opacity = 0.95;

      # Breathing room between the text and the window edge, in pixels.
      window-padding-x = 12;
      window-padding-y = 12;

      # A thin line cursor instead of a block.
      cursor-style = "bar";

      # Don't ask "are you sure?" every time you close a terminal.
      confirm-close-surface = false;
    };
  };
}
