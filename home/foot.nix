# ═══════════════════════════════════════════════════════════════════════════
#  home/foot.nix  —  the terminal (foot, as on Fedora)
# ═══════════════════════════════════════════════════════════════════════════
#
#  Colours come from Noctalia: it writes ~/.config/foot/themes/noctalia from
#  your wallpaper and foot includes it. Everything else is below.

{ lib, ... }:

{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        include = "~/.config/foot/themes/noctalia";
        font = "JetBrains Mono:size=11,Symbols Nerd Font Mono:size=11";
        pad = "12x10";
      };
      colors-dark.alpha = 0.85; # slightly see-through
      scrollback.lines = 10000;
      cursor = {
        style = "beam";
        blink = "yes";
      };
      mouse.hide-when-typing = "yes";
      # Shift+Enter sends ESC+Enter, so Claude Code and other TUIs get a new line.
      text-bindings."\\x1b\\x0d" = "Shift+Return";
    };
  };

  # Before Noctalia's first theme run the include would point at nothing.
  # Create an empty placeholder once; Noctalia overwrites it.
  home.activation.footNoctaliaTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    theme="$HOME/.config/foot/themes/noctalia"
    if [ ! -e "$theme" ]; then
      run mkdir -p "$(dirname "$theme")"
      run touch "$theme"
    fi
  '';
}
