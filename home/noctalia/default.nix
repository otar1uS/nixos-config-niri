# ═══════════════════════════════════════════════════════════════════════════
#  home/noctalia/default.nix  —  the desktop shell (bar, launcher, panels...)
# ═══════════════════════════════════════════════════════════════════════════
#
#  Noctalia v5 (C++, no Qt) gives you in one program: the top bar, app
#  launcher, notifications, lock screen, wallpaper, volume/brightness
#  pop-ups, clipboard history, control center, Alt+Tab switcher, and the
#  password pop-up for admin actions.
#
#  It is STARTED by niri when you log in (see ../niri/kdl/startup.kdl).
#
#  Two layers of settings:
#   • ~/.config/noctalia/config.toml  <- written from `settings` below (Nix)
#   • ~/.local/state/noctalia/settings.toml  <- whatever you click in the
#     Settings window (Super+,). It wins over config.toml. Delete it to go
#     back to exactly what's written here.
#
#  Your own plugins live in ./plugins/ (Battery, Display, ThinkPad). Nix copies
#  that folder into the store and tells Noctalia to load plugins from it.
#  Plugins from the Noctalia community can still be added in
#  Settings -> Plugins.

{ pkgs, ... }:

let
  # This is the UNSTABLE (newest) Noctalia: modules/unstable.nix swaps it in
  # for everyone, so plain `pkgs.noctalia` already means the unstable one.
  noctalia = pkgs.noctalia;

  # Your Gruvbox wallpaper, downloaded once and pinned by
  # its hash, so it can never change underneath you.
  wallpaper = pkgs.fetchurl {
    name = "gruvbox-sunset.png";
    url = "https://raw.githubusercontent.com/AngelJumbo/gruvbox-wallpapers/64a1f5fdbc4f7e0a7700405a80f6011dbe2e00f8/wallpapers/minimalistic/sunset.png";
    hash = "sha256-Gra/Ag/MuvmkqCyWvcibv2iu8z29r/rqGf7VACQprYo=";
  };

  # ── The settings. Same names as in Noctalia's docs, written in Nix. ─────
  # Full list of options: https://docs.noctalia.dev/noctalia/configuration/
  settings = {
    shell = {
      font_family = "Inter"; # installed in modules/niri.nix
      polkit_agent = true; # Noctalia shows the "enter your password" box for admin actions
      niri_overview_type_to_launch_enabled = true; # in the overview (Super+O), just start typing to launch an app
      # Skip the first-start welcome wizard: everything it asks is already
      # decided here, and its answers would override these settings.
      setup_wizard_enabled = false;
      # Copy the wallpaper, colours, font and monitor layout to the login
      # screen (Noctalia Greeter) whenever they change here.
      greeter_sync.auto_sync = true;
    };

    theme = {
      mode = "dark";
      source = "builtin";
      builtin = "Gruvbox"; # Noctalia's own Gruvbox colours
      # Also paint GTK apps (Nautilus, Loupe, file dialogs...) in the same
      # Gruvbox colours. Noctalia writes ~/.config/gtk-3.0 and gtk-4.0/noctalia.css.
      templates.builtin_ids = [
        "gtk3"
        "gtk4"
        "btop" # and the btop system monitor
      ];
    };

    # ── Auto-lock when you walk away ─────────────────────────────────────
    # After 10 minutes without touching anything: lock the screen. One
    # minute later: turn the screens off (any key or mouse move wakes them).
    # Watching a video doesn't count as "away": players keep it awake.
    idle.behavior = {
      lock.enabled = true; # timeout = 600 seconds (Noctalia's default)
      screen-off.enabled = true; # timeout = 660 seconds

      # After 15 minutes on BATTERY: lock and go to sleep (saves the battery).
      # On the charger it never sleeps by itself. Noctalia can't check the
      # charger on its own, so this runs a tiny shell check first:
      # AC/online is 1 with the charger in, 0 without.
      battery-sleep = {
        timeout = 900;
        action = "command";
        command = "[ \"$(cat /sys/class/power_supply/AC/online)\" = 0 ] && noctalia msg session lock-and-suspend";
      };
    };

    # ── Where you are: Vakiri, Kakheti, Georgia ──────────────────────────
    # Exact coordinates instead of an online address lookup: works offline,
    # and nothing about you is sent anywhere. Used by night light and weather.
    location = {
      latitude = 41.64677;
      longitude = 45.91743;
    };

    # Warmer, softer screen colours after sunset (easier on the eyes at
    # night), back to normal at sunrise. Sunset is calculated for Vakiri and
    # moves with the seasons. 4000 K = warm; 6500 K = normal daylight.
    nightlight = {
      enabled = true;
      temperature_night = 4000;
    };

    # Weather for Vakiri, shown next to the clock (from Open-Meteo, free).
    weather = {
      enabled = true;
      unit = "celsius";
    };

    wallpaper = {
      directory = "~/Pictures/Wallpapers"; # drop more pictures here, pick them in the wallpaper panel
      default.path = "${wallpaper}"; # the one used until you pick another
    };

    # A blurred copy of the wallpaper behind niri's overview (Super+O).
    # Works together with the "noctalia-backdrop" layer-rule in ../niri/kdl/rules.kdl.
    backdrop.enabled = true;

    # Also control your Dell's own brightness through the cable (DDC/CI),
    # so the brightness keys and slider work on it. Needs modules/niri.nix's
    # i2c setting, and DDC/CI switched on in the Dell's own menu (it's on
    # by default).
    brightness.enable_ddcutil = true;

    # ── The top bar ──────────────────────────────────────────────────────
    # The left side ("start") stays default: launcher, wallpaper, workspaces.
    bar.main.center = [
      "clock"
      "weather" # Vakiri's weather next to the clock
    ];
    bar.main.end = [
      "media"
      "privacy" # lights up while the camera, microphone or screen sharing is in use
      "tray"
      "notifications"
      "clipboard"
      "keyboard_layout" # "us" or "ge"; Alt+Shift switches (set in ../niri/kdl/input.kdl)
      "network"
      "bluetooth"
      "volume"
      "brightness"
      "my-thinkpad" # ours: CPU temperature + fan (defined below)
      "my-display" # ours: screen size + refresh rate (defined below)
      "my-battery" # ours: battery + charging modes (defined below)
      "control-center"
      "session"
    ];

    # Bar names -> which widget they are. "otari/display:widget" means
    # "the widget called `widget` from the plugin `otari/display`".
    widget = {
      my-thinkpad.type = "otari/thinkpad:widget";
      my-display.type = "otari/display:widget";
      my-battery.type = "otari/battery:widget";
    };

    # ── Plugins ──────────────────────────────────────────────────────────
    plugins = {
      enabled = [
        "otari/battery"
        "otari/display"
        "otari/thinkpad"
        # From the community: a good-looking, searchable list of all your
        # keyboard shortcuts (Super+Shift+/). Read from niri's config.
        "kenn/keybind-cheatsheet"
      ];
      # Where plugins come from. Writing this list REPLACES Noctalia's
      # built-in list, so the official and community stores are listed here
      # too (they also fill Settings -> Plugins). Noctalia downloads and
      # updates those itself.
      source = [
        # A "path" source: a read-only folder. ${./plugins} is this folder's
        # copy in the Nix store, so it's always exactly what is in your repo.
        {
          name = "nix";
          kind = "path";
          location = "${./plugins}";
          enabled = true;
        }
        {
          name = "official";
          kind = "git";
          location = "https://github.com/noctalia-dev/official-plugins";
          enabled = true;
        }
        {
          name = "community";
          kind = "git";
          location = "https://github.com/noctalia-dev/community-plugins";
          enabled = true;
        }
      ];
    };
  };

  # Turn the Nix settings above into a TOML file.
  toml = pkgs.formats.toml { };
  configFile = toml.generate "noctalia-config.toml" settings;

  # Let Noctalia CHECK the file while building, like niri does for its own.
  # A real mistake stops the rebuild; warnings are only printed.
  checked =
    pkgs.runCommand "noctalia-config-checked.toml" { nativeBuildInputs = [ noctalia ]; }
      ''
        export HOME=$TMPDIR XDG_CONFIG_HOME=$TMPDIR/config XDG_STATE_HOME=$TMPDIR/state XDG_CACHE_HOME=$TMPDIR/cache
        noctalia config validate ${configFile}
        cp ${configFile} $out
      '';
in
{
  home.packages = [ noctalia ];

  xdg.configFile."noctalia/config.toml".source = checked;

  # The wallpaper folder (.keep is an empty placeholder so it exists).
  home.file."Pictures/Wallpapers/.keep".text = "";
}
