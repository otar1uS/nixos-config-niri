# ═══════════════════════════════════════════════════════════════════════════
#  Keyboard shortcuts. (Merged into ~/.config/umbriel/config.toml.)
# ═══════════════════════════════════════════════════════════════════════════
#  Your Fedora niri shortcuts, moved to Umbriel's actions. Super+Shift+/
#  shows them all on screen.
#
#  "Mod" = Super. A plain string is the action; a { } table adds options:
#    repeat = false            fire once while held
#    allow_when_locked = true  also works on the lock screen (media keys)
#    cooldown_ms = 150         for mouse wheels
#  Actions: https://docs.noctalia.dev/umbriel/actions/
#  Noctalia commands: `noctalia msg --help`.
#
#  This table REPLACES Umbriel's built-in binds, so everything you want is
#  listed here.

let
  once = action: {
    inherit action;
    repeat = false;
  };
  locked = action: {
    inherit action;
    allow_when_locked = true;
  };
  wheel = action: {
    inherit action;
    cooldown_ms = 150;
  };
  noctalia = args: "spawn noctalia msg ${args}";

  # Super+1..9 go to a workspace, Super+Ctrl+1..9 send the column there.
  workspaceBinds = builtins.listToAttrs (
    builtins.concatMap (
      n:
      let
        i = toString n;
      in
      [
        {
          name = "Mod+${i}";
          value = "workspace-switch ${i}";
        }
        {
          name = "Mod+Ctrl+${i}";
          value = "column-move-to-workspace ${i}";
        }
        {
          name = "Mod+Shift+${i}";
          value = "window-move-to-workspace ${i}";
        }
      ]
    ) (builtins.genList (n: n + 1) 9)
  );
in
{
  keybinds = workspaceBinds // {
    # ── Apps ─────────────────────────────────────────────────────────
    "Mod+T" = once "spawn foot -e herdr"; # herdr (agent multiplexer)
    "Mod+Shift+T" = once "spawn foot";
    "Mod+Return" = once "spawn foot";
    "Mod+E" = once "spawn nautilus";
    "Mod+Y" = once "spawn foot -e yazi";
    "F9" = once "spawn voxtype record toggle"; # voice typing
    "Mod+Alt+D" = once "spawn voxtype record toggle";

    # ── Noctalia ─────────────────────────────────────────────────────
    "Mod+D" = once (noctalia "panel-toggle launcher");
    "Mod+Space" = once (noctalia "panel-toggle launcher");
    "Mod+S" = once (noctalia "panel-toggle control-center");
    "Mod+X" = once (noctalia "panel-toggle session"); # lock, log out, reboot...
    "Mod+Ctrl+V" = once (noctalia "panel-toggle clipboard");
    "Mod+Shift+W" = once (noctalia "panel-toggle wallpaper");
    "Mod+Alt+W" = once (noctalia "panel-toggle noctalia/wallhaven:browser");
    "Mod+Shift+Comma" = once (noctalia "settings-toggle");
    "Mod+Shift+Period" = once (noctalia "panel-toggle launcher /kao"); # kaomoji
    "Mod+Alt+L" = once (noctalia "session lock");
    "Mod+Alt+R" = once (noctalia "plugin noctalia/screen_recorder:service all toggle");
    "Alt+Tab" = noctalia "window-switcher hold";
    "Alt+Shift+Tab" = noctalia "window-switcher hold reverse";

    # Your plugin panels.
    "Mod+B" = once (noctalia "panel-toggle otari/battery:panel"); # charging + power modes
    "Mod+Shift+D" = once (noctalia "panel-toggle otari/display:panel"); # screen size, refresh rate
    "Mod+Alt+T" = once (noctalia "panel-toggle otari/thinkpad:panel"); # temps, fan, lid LED

    # Screenshots (Noctalia: pick an area, then annotate / copy / save).
    "Print" = once (noctalia "screenshot-region");
    "Mod+Shift+S" = once (noctalia "screenshot-region");
    "Ctrl+Print" = once (noctalia "screenshot-fullscreen");
    "Alt+Print" = once (noctalia "screenshot-window");
    "Mod+Shift+A" = once (noctalia "screenshot-annotate");

    # ── Media, volume, brightness (Noctalia shows the OSD) ───────────
    "XF86AudioRaiseVolume" = locked (noctalia "volume-up");
    "XF86AudioLowerVolume" = locked (noctalia "volume-down");
    "XF86AudioMute" = locked (noctalia "volume-mute");
    "XF86AudioMicMute" = locked (noctalia "mic-mute");
    "XF86AudioPlay" = locked (noctalia "media toggle");
    "XF86AudioStop" = locked (noctalia "media stop");
    "XF86AudioNext" = locked (noctalia "media next");
    "XF86AudioPrev" = locked (noctalia "media previous");
    "XF86MonBrightnessUp" = locked (noctalia "brightness-up");
    "XF86MonBrightnessDown" = locked (noctalia "brightness-down");

    # ── Windows ──────────────────────────────────────────────────────
    "Mod+Q" = once "window-close";
    "Mod+O" = once "overview-toggle";
    "Mod+Shift+Slash" = once "cheatsheet-toggle"; # every shortcut, on screen

    "Mod+Left" = "window-focus-left";
    "Mod+Down" = "window-focus-down";
    "Mod+Up" = "window-focus-up";
    "Mod+Right" = "window-focus-right";
    "Mod+H" = "window-focus-left";
    "Mod+J" = "window-focus-down";
    "Mod+K" = "window-focus-up";
    "Mod+L" = "window-focus-right";
    "Mod+Home" = "column-focus-first";
    "Mod+End" = "column-focus-last";

    "Mod+Ctrl+Left" = "column-move-left";
    "Mod+Ctrl+Down" = "window-move-down";
    "Mod+Ctrl+Up" = "window-move-up";
    "Mod+Ctrl+Right" = "column-move-right";
    "Mod+Ctrl+H" = "column-move-left";
    "Mod+Ctrl+J" = "window-move-down";
    "Mod+Ctrl+K" = "window-move-up";
    "Mod+Ctrl+L" = "column-move-right";
    "Mod+Ctrl+Home" = "column-move-to-first";
    "Mod+Ctrl+End" = "column-move-to-last";

    # Monitors
    "Mod+Shift+Left" = "output-focus-left";
    "Mod+Shift+Down" = "output-focus-down";
    "Mod+Shift+Up" = "output-focus-up";
    "Mod+Shift+Right" = "output-focus-right";
    "Mod+Shift+H" = "output-focus-left";
    "Mod+Shift+J" = "output-focus-down";
    "Mod+Shift+K" = "output-focus-up";
    "Mod+Shift+L" = "output-focus-right";
    "Mod+Shift+Ctrl+Left" = "column-move-to-output-left";
    "Mod+Shift+Ctrl+Down" = "column-move-to-output-down";
    "Mod+Shift+Ctrl+Up" = "column-move-to-output-up";
    "Mod+Shift+Ctrl+Right" = "column-move-to-output-right";
    "Mod+Shift+Ctrl+H" = "column-move-to-output-left";
    "Mod+Shift+Ctrl+J" = "column-move-to-output-down";
    "Mod+Shift+Ctrl+K" = "column-move-to-output-up";
    "Mod+Shift+Ctrl+L" = "column-move-to-output-right";

    # Workspaces (up/down, like niri)
    "Mod+Page_Down" = "workspace-next";
    "Mod+Page_Up" = "workspace-previous";
    "Mod+U" = "workspace-next";
    "Mod+I" = "workspace-previous";
    "Mod+Ctrl+Page_Down" = "column-move-to-workspace-next";
    "Mod+Ctrl+Page_Up" = "column-move-to-workspace-previous";
    "Mod+Ctrl+U" = "column-move-to-workspace-next";
    "Mod+Ctrl+I" = "column-move-to-workspace-previous";
    "Mod+Shift+Page_Down" = "workspace-move-down";
    "Mod+Shift+Page_Up" = "workspace-move-up";
    "Mod+Shift+U" = "workspace-move-down";
    "Mod+Shift+I" = "workspace-move-up";

    # Mouse wheel with Super held
    "Mod+WheelDown" = wheel "workspace-next";
    "Mod+WheelUp" = wheel "workspace-previous";
    "Mod+Ctrl+WheelDown" = wheel "column-move-to-workspace-next";
    "Mod+Ctrl+WheelUp" = wheel "column-move-to-workspace-previous";
    "Mod+WheelRight" = "window-focus-right";
    "Mod+WheelLeft" = "window-focus-left";
    "Mod+Shift+WheelDown" = "window-focus-right";
    "Mod+Shift+WheelUp" = "window-focus-left";

    # ── Columns and sizes ────────────────────────────────────────────
    "Mod+BracketLeft" = "window-consume-or-expel-left";
    "Mod+BracketRight" = "window-consume-or-expel-right";
    "Mod+Comma" = "window-consume-from-right"; # pull the next window into this column
    "Mod+Period" = "window-consume-or-expel-right"; # push it back out

    "Mod+R" = "window-cycle-primary-extent"; # width: 1/3, 1/2, 2/3
    "Mod+Shift+R" = "window-cycle-primary-extent-back";
    "Mod+Ctrl+Shift+R" = "window-cycle-secondary-extent"; # height
    "Mod+Minus" = "window-modify-primary-extent -0.1";
    "Mod+Equal" = "window-modify-primary-extent +0.1";
    "Mod+Shift+Minus" = "window-modify-secondary-extent -0.1";
    "Mod+Shift+Equal" = "window-modify-secondary-extent +0.1";

    "Mod+F" = once "window-toggle-maximize"; # full width column
    "Mod+Shift+F" = once "window-toggle-fullscreen";
    "Mod+M" = once "window-toggle-maximize-to-edges";
    "Mod+C" = "column-center";
    "Mod+V" = once "window-toggle-floating";
    "Mod+Shift+V" = once "window-focus-switch-floating";
    "Mod+W" = once "column-toggle-tabbed"; # tabs in this column
    "Mod+P" = once "window-toggle-pinned"; # keep above everything
    "Mod+Alt+Space" = once "workspace-set-layout toggle"; # scrolling/dwindle/master/stacking

    # Scratchpad: park a window, call it back with Super+` (grave)
    "Mod+Shift+Grave" = once "window-move-to-scratchpad";
    "Mod+Grave" = "scratchpad-toggle";

    # ── Session ──────────────────────────────────────────────────────
    "Mod+Escape" = {
      action = "shortcuts-inhibit-toggle"; # when a VM/game grabs the keyboard
      allow_when_inhibited = true;
      repeat = false;
    };
    "Mod+Shift+E" = once "session-quit"; # asks first
    "Ctrl+Alt+Delete" = once "session-quit";
    "Mod+Shift+P" = once "dpms-off"; # screens off; any key wakes them
  };
}
