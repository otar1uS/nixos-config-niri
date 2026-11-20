# Session basics. (Merged into ~/.config/umbriel/config.toml by default.nix.)
{
  general = {
    autostart = [ "noctalia" ]; # the shell; started once per login
    mod_key = "Super"; # "Mod" in binds.nix
  };

  # Noctalia writes your wallpaper colours for Umbriel (borders, title and
  # tab bars, overview tint) to this file and updates it on every change.
  # Optional: Umbriel doesn't complain before the first time it exists.
  include.optional.files = [ "~/.config/umbriel/noctalia.toml" ];

  # Push the mouse into the top-left corner: overview (like on niri).
  hot_corners.top_left = {
    enabled = true;
    delay_ms = 500;
    action = "overview-open";
  };
}
