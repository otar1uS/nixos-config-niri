# ═══════════════════════════════════════════════════════════════════════════
#  home/noctalia  —  the desktop shell (bar, launcher, panels, lock screen...)
# ═══════════════════════════════════════════════════════════════════════════
#
#  Noctalia v5 gives you in one program: the bar, app launcher,
#  notifications, lock screen, wallpaper + colours, volume/brightness
#  pop-ups, clipboard history, control center, Alt+Tab, screenshots and the
#  password pop-up for admin actions. Umbriel starts it at login.
#
#  Two layers of settings:
#   • ~/.config/noctalia/config.toml      <- written from `settings` below,
#     and CHECKED while building (`noctalia config validate`)
#   • ~/.local/state/noctalia/settings.toml  <- whatever you click in
#     Settings (Super+Shift+,). It wins over the file above. Delete it to go
#     back to exactly what's written here.
#
#  These settings recreate your Fedora setup: bar at the bottom, colours
#  from the wallpaper, JetBrains Mono, 125% UI.
#  Your own plugins (Battery, Display, ThinkPad) are in ./plugins.

{ ... }:

{
  programs.noctalia = {
    enable = true;

    settings = {
      shell = {
        font_family = "JetBrains Mono ExtraBold";
        app_icon_color = "primary";
        show_close_buttons = false;
        polkit_agent = true; # Noctalia shows the "enter your password" box
        setup_wizard_enabled = false; # everything it asks is decided here
        greeter_sync.auto_sync = true; # copy the look to the login screen
        panel.border_color = "primary";
        screen_corners = {
          enabled = true;
          size = 45;
        };
        shadow.alpha = 0.5;

        # Umbriel integration (docs: noctalia/compositor-settings/umbriel):
        umbriel_overview_type_to_launch_enabled = true; # Super+O, then type an app name
        umbriel_overview_close_on_launch_enabled = true;
      };

      accessibility.ui_scale = 1.25;

      theme = {
        mode = "dark";
        shell_mode = "dark";
        source = "wallpaper"; # colours picked from your wallpaper
        wallpaper_scheme = "faithful";
        pure_black_dark = true;
        # Recolour these to match, on every wallpaper/theme change:
        #   umbriel  window borders, title/tab bars, overview tint
        #   foot     the terminal         gtk3/gtk4  Nautilus, Loupe, dialogs
        #   btop     the system monitor
        templates.builtin_ids = [
          "umbriel"
          "foot"
          "gtk3"
          "gtk4"
          "btop"
        ];
      };

      wallpaper = {
        directory = "~/Pictures"; # where the wallpaper picker looks
        default.path = "/home/otari/Pictures/wallhaven-21jo1m.png"; # restore ~/Pictures from your backup
        edge_smoothness = 0.3;
        transition_on_startup = true;
      };

      # ── Auto-lock when you walk away ─────────────────────────────────
      # 10 min idle: lock. 11 min: screens off. 15 min on BATTERY: lock and
      # sleep. On the charger it never sleeps by itself. Videos keep it awake.
      idle.behavior = {
        lock.enabled = true;
        screen-off.enabled = true;
        battery-sleep = {
          timeout = 900;
          action = "command";
          command = "[ \"$(cat /sys/class/power_supply/AC/online)\" = 0 ] && noctalia msg session lock-and-suspend";
        };
      };

      # Vakiri, Kakheti, rounded to ~1 km (this repo is public; sunset times
      # and weather don't need more). Fixed coordinates also mean nothing is
      # looked up online.
      location = {
        latitude = 41.65;
        longitude = 45.92;
      };
      nightlight.enabled = true;
      weather = {
        enabled = true;
        unit = "celsius";
      };

      # Dell brightness through the cable (modules/desktop.nix: i2c).
      brightness.enable_ddcutil = true;

      # ── The bar (your Fedora layout) ─────────────────────────────────
      bar.default = {
        position = "bottom";
        thickness = 39;
        scale = 1.25;
        font_scale = 1.07;
        padding = 80;
        widget_spacing = 16;
        margin_ends = 0;
        panel_overlap = 3;
        capsule_thickness = 0.49;
        border = "on_hover";
        color = "error_container";
        icon_color = "#93D6FE";
        shadow = false;
        radius = 0;
        radius_top_left = 16;
        radius_top_right = 15;
        radius_bottom_right = 0;

        start = [
          "wallpaper"
          "noctalia/wallhaven:wallhaven"
          "workspaces"
          "cpu"
          "ram"
          "my-thinkpad" # ours: CPU temperature + fan (click: fan modes, lid LED)
          "caffeine"
          "audio_visualizer"
        ];
        end = [
          "media"
          "noctalia/screen_recorder:recorder"
          "tray"
          "notifications"
          "keyboard_layout" # us / ge
          "network"
          "volume"
          "brightness"
          "my-display" # ours: screen size + refresh rate
          "my-battery" # ours: battery + charging modes
          "session"
        ];
      };

      # Bar names -> which plugin widget they are.
      widget = {
        my-thinkpad.type = "otari/thinkpad:widget";
        my-display.type = "otari/display:widget";
        my-battery.type = "otari/battery:widget";
      };

      # ── Plugins ──────────────────────────────────────────────────────
      plugins = {
        enabled = [
          "otari/battery"
          "otari/display"
          "otari/thinkpad"
          "noctalia/kaomoji"
          "noctalia/wallhaven"
          "noctalia/screen_recorder"
        ];
        # Writing this list REPLACES the built-in one, so the official and
        # community stores are listed too. Noctalia downloads and updates
        # those itself (Settings -> Plugins).
        source = [
          {
            name = "nix"; # ./plugins, read-only, always what's in this repo
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
  };
}
