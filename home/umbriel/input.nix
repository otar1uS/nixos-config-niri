# Keyboard, touchpad, mouse. (Merged into ~/.config/umbriel/config.toml.)
# Device names for per-device settings: `libinput list-devices`.
{
  input = {
    keyboard = {
      # English + Georgian. Press BOTH Alt keys together to switch (as on
      # Fedora). The bar shows "us"/"ge". Other switch keys: `xkbcli list`,
      # e.g. "grp:alt_shift_toggle" for Alt+Shift.
      layout = "us,ge";
      options = "grp:alts_toggle";
      numlock_toggle = true;
    };

    touchpad = {
      tap = true;
      natural_scroll = true;
      disable_while_typing = true;
    };

    # Focus follows the mouse, but only scrolls the strip a little to reach
    # a window (niri's max-scroll-amount="33%").
    focus = {
      follows_mouse = "sloppy";
      follows_mouse_max_scroll = 0.33;
    };

    cursor = {
      theme = "Adwaita";
      size = 24;
      hide_when_typing = true;
    };
  };
}
