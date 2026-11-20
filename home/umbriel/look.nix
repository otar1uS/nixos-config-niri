# Looks and layout. (Merged into ~/.config/umbriel/config.toml.)
# Colours are NOT here: Noctalia writes them (general.nix, the include).
{
  appearance = {
    prefer_no_csd = true; # apps draw no title bars of their own
    border_width = 2;
    corner_radius = 10;
    blur = {
      enabled = true;
      optimized = true;
      passes = 2;
      radius = 3;
      noise = 0.02;
      brightness = 0.9;
      contrast = 0.9;
      saturation = 1.1;
    };
  };

  # Scrolling layout, like niri: windows are columns on an endless strip.
  # Other layouts per workspace: Super+Alt+Space cycles dwindle/master/stacking.
  layout = {
    mode = "scrolling";
    gap = 8; # as on Fedora
    extent_presets = [
      0.333
      0.5
      0.667
    ]; # Super+R cycles through these widths
    scrolling.default_extent_fraction = 0.5; # new windows start half the screen wide
  };
}
