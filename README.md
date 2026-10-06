# nixos-config

NixOS 26.05 flake for the ThinkPad T14s (hostname `nixos`, user `otari`),
with a Gruvbox **niri** desktop.

| Job | Pick |
|---|---|
| Window manager | **niri** (scrolling tiling) |
| Login screen | **Noctalia Greeter** on greetd (C++, synced with the bar's look) |
| Voice typing | **Voxtype** + NVIDIA **Parakeet** model, offline (F9 / Super+D) |
| Webcam | **Snapshot** ("Camera": photos, videos) + **cameractrls** ("Camera Settings", remembered) |
| Keyboard | English + Georgian, **Alt+Shift** switches |
| Night light, weather | Noctalia, for Vakiri, Kakheti |
| Backups | **restic** (prepared in `modules/backup.nix`, off until you pick a destination) |
| Bar, launcher, notifications, lock, wallpaper, Alt+Tab | **Noctalia v5** (`noctalia`) |
| Battery charging modes (Desk / Daily / Travel) | your **Battery** panel (`home/noctalia/plugins/battery`) |
| Screen size and refresh rate | your **Display** panel (`home/noctalia/plugins/display`) |
| Temperatures, fan modes, lid-logo LED | your **ThinkPad** panel (`home/noctalia/plugins/thinkpad`) |
| Auto-lock (10 min) and screen off (11 min) | Noctalia |
| Which screens are on (laptop off when docked) | **kanshi** |
| Terminal | **Ghostty** |
| File managers | **Nautilus** (mouse), **Yazi** (keyboard, in the terminal) |
| Prompt | **Starship** |
| Image viewer | **Loupe** |
| Clipboard history | Noctalia (built in) |
| Screenshots | niri built-in |
| Old X11 apps | **xwayland-satellite** |

## Apply / undo

```sh
cd ~/nixos-config
git add .                                    # flakes only see files git knows about
nixos-rebuild build --flake ~/nixos-config#nixos   # optional: test only, changes nothing
sudo nixos-rebuild switch --flake ~/nixos-config#nixos   # apply (alias: rebuild)

sudo nixos-rebuild switch --rollback         # undo the last switch

upgrade                                      # newest versions of everything, then apply
```

`upgrade` updates both channels, builds, shows a list of what changes
(e.g. `noctalia 5.2.0 -> 5.2.1`) and asks y/n before applying. Run it every
week or two so you never fall behind. Afterwards commit `flake.lock` in git:
it records the exact versions, so you can always go back to ones that worked.

### Stable vs unstable

| From **unstable** (newest) | From **stable** (nixos-26.05) |
|---|---|
| niri, xwayland-satellite, screen-sharing portal | the system base: kernel, systemd, sound, network |
| Noctalia, Noctalia Greeter (login screen), kanshi | greetd, the login manager (so you can always log in) |
| claude-code, VS Code (change fast) | your apps: Firefox, Ghostty, Nautilus, Discord... |
| | the graphics driver (Mesa): it must be the oldest version in use, see `modules/unstable.nix` |

The list lives in `modules/unstable.nix`. To move something to unstable, add
its name there.

Always use the `--flake ~/nixos-config#nixos` form (or the `rebuild` alias):
plain `sudo nixos-rebuild switch` doesn't know where your config lives.

For big changes (a different login screen or desktop), use `boot` instead of
`switch`: it means "use this next time the computer starts", so your running
session isn't disturbed. Then `reboot`.

**Safety net:** every rebuild is kept as an entry in the boot menu (the last
10, see `programs.nh.clean`). If something goes wrong, restart and pick the
entry below the top one using the arrow keys.

## Files

```
~/nixos-config/
├── flake.nix                 inputs (nixpkgs, Home Manager) and wiring
├── flake.lock                exact versions of the inputs (don't edit by hand)
├── configuration.nix         the system: boot, network, sound, packages
├── hardware-configuration.nix   disks + LUKS. Generated, do not edit
├── home.nix                  your apps, git, bash. Imports the files in home/
├── modules/
│   ├── unstable.nix          which parts come from the unstable channel
│   ├── niri.nix              SYSTEM: niri, login screen, fonts, services
│   ├── battery.nix           SYSTEM: the charging modes (Desk/Daily/Travel)
│   ├── thinkpad.nix          SYSTEM: fan modes, lid LED, the `thinkpad` command
│   └── backup.nix            SYSTEM: automatic encrypted backups (off until set up)
└── home/
    ├── niri/
    │   ├── default.nix       glues the .kdl pieces together and CHECKS them
    │   └── kdl/
    │       ├── startup.kdl     programs started at login
    │       ├── input.kdl       keyboard, touchpad, TrackPoint
    │       ├── outputs.kdl     empty on purpose: kanshi owns the screens
    │       ├── look.kdl        gaps, focus ring, shadows, cursor
    │       ├── animations.kdl  window and workspace motion
    │       ├── rules.kdl       per-window rules
    │       └── binds.kdl       keyboard shortcuts
    ├── noctalia/
    │   ├── default.nix       the shell: its settings, checked while building
    │   └── plugins/
    │       ├── battery/      the Battery widget + panel
    │       ├── display/      the Display widget + panel
    │       └── thinkpad/     the ThinkPad widget + panel (temps, fan, LED)
    ├── kanshi.nix            which screens are on, per situation
    ├── dev.nix               delta, atuin, tldr, lazygit, bat, gh, git defaults
    ├── voice.nix             voice typing (Voxtype + Parakeet)
    ├── camera.nix            webcam apps, and keeping its settings
    ├── ghostty.nix           terminal
    ├── yazi.nix              terminal file manager
    ├── starship.nix          prompt
    └── theme.nix             icons, dark mode + fonts for GTK apps
```

The rule: `modules/` is for the machine, `home/` is for you. One topic per
file. niri's settings are plain `.kdl` files (niri's own language, same syntax
as its docs). Nix joins them into `~/.config/niri/config.kdl` and runs
`niri validate` on the result while building, so a typo stops the rebuild
instead of breaking your desktop.

## First login

Press **Super+Shift+/** to see every shortcut.

The Gruvbox colours, your Gruvbox wallpaper and the bar layout are already
set from `home/noctalia/default.nix`. More wallpapers: drop pictures into
`~/Pictures/Wallpapers`. Anything you change in Noctalia's Settings
(**Super+,**) is saved to `~/.local/state/noctalia/settings.toml` and wins over
the Nix settings. Delete that file to go back to exactly what Nix says.

Try: the **battery** in the bar (charging modes), the **monitor icon** next
to it (screen size and refresh rate), **Alt+Tab**, and **Super+O** then just
start typing an app name.

Touchpad: swipe three fingers left/right to scroll through windows, up/down to
switch workspaces. Push the mouse into the top-left corner (or Super+O) for
the overview.

GTK apps (Nautilus, Loupe, file dialogs) get the same Gruvbox colours from
Noctalia (`theme.templates` in `home/noctalia/default.nix`).

## Shortcut cheat sheet

| Keys | Action |
|---|---|
| Super+Shift+/ | All shortcuts, searchable |
| F9 (fn+F9 on Apple) or Super+D | Voice typing: start / stop |
| Alt+Shift | Switch English / Georgian |
| Super+Enter | Terminal |
| Super+Space | App launcher |
| Super+E / Super+Y | Nautilus / Yazi |
| Super+B | Firefox |
| Super+V | Clipboard history |
| Super+S | Control center |
| Super+, | Noctalia settings |
| Super+X | Power menu |
| Super+P | Display panel: screen size, refresh rate |
| Super+Shift+B | Battery panel: charging mode, power mode |
| Super+Shift+T | ThinkPad panel: temperatures, fan mode, lid LED |
| Alt+Tab | Switch windows (with previews) |
| Super+Alt+L | Lock |
| Super+Q | Close window |
| Super+H/J/K/L or arrows | Move focus |
| Super+Ctrl+H/J/K/L | Move window |
| Super+R | Cycle width 1/3, 1/2, 2/3 |
| Super+F / Super+Shift+F | Maximize / fullscreen |
| Super+- / Super+= | Narrower / wider |
| Super+W | Tabbed column |
| Super+Shift+V | Float window |
| Super+1..9 | Go to workspace |
| Super+Shift+1..9 | Send window to workspace |
| Super+U / Super+I | Workspace down / up |
| Super+O | Overview |
| Print or Super+Shift+S | Screenshot an area |
| Super+Shift+E | Log out |

## Terminal tools worth knowing

| Type | What it does |
|---|---|
| `, cowsay hi` | run any program without installing it (comma) |
| Ctrl+R | search your whole command history (atuin) |
| `tldr tar` | short examples for a command |
| `lazygit` | git in a friendly screen |
| `git diff` | side-by-side, coloured (delta) |
| `bat file` | `cat` with colours |
| `thinkpad` | temperatures, fan and LED as JSON |
| `battery-charge-mode` | charging mode from the terminal |
| `upgrade` | newest versions of everything, then apply |

Unknown command? The terminal tells you which package has it.

## How to change things

Edit the file, `git add .` if you made a new file, then `rebuild`. niri
reloads its config by itself when the file changes.

| I want to change... | File | What to edit |
|---|---|---|
| Gaps between windows | `home/niri/kdl/look.kdl` | `gaps 10` |
| Focus ring colours | `home/niri/kdl/look.kdl` | `active-gradient from=... to=...` |
| Animation speed | `home/niri/kdl/animations.kdl` | `slowdown 1.0` (bigger = slower) |
| Screen size / refresh rate | Display panel | Super+P, tap a button (remembered) |
| Which screens are on when | `home/kanshi.nix` | the profiles |
| Charging modes and their % | `modules/battery.nix` | the `modes` list |
| Fan / lid LED | ThinkPad panel | Super+Shift+T (remembered) |
| Auto-lock / sleep times | `home/noctalia/default.nix` | `idle.behavior` |
| Location (night light, weather) | `home/noctalia/default.nix` | `location` |
| Voice typing model, sounds | `home/voice.nix` | `settings` |
| Webcam brightness, exposure... | "Camera Settings" app | change, then close it (saved) |
| Turn on backups | `modules/backup.nix` | follow the 2 steps at the top |
| Add Georgian keyboard | `home/niri/kdl/input.kdl` | follow the comment there |
| A shortcut | `home/niri/kdl/binds.kdl` | copy a line, change keys and action |
| Terminal font or theme | `home/ghostty.nix` | `font-size`, `theme` |
| Prompt colours | `home/starship.nix` | the `style` values |
| Login screen | `modules/niri.nix` | the `services.greetd` block |
| Bar layout, theme, wallpaper | `home/noctalia/default.nix` | the `settings` block |

To add a new `.kdl` piece: create it in `home/niri/kdl/`, add it to the
`pieces` list in `home/niri/default.nix`, then `git add` it.

## If something breaks

**Rebuild fails with a `.kdl` error:** that's the safety check working. Read
the line number and fix the typo.

**Rebuild fails with a strange `niri validate` error that isn't about your
config:** in `home/niri/default.nix`, change `.source = checked;` to
`.source = joined;` to skip the check.

**A Noctalia shortcut does nothing:** run `noctalia msg --help` in a
terminal to list the commands it accepts, then fix the words in `binds.kdl`.

**No bar appears, or a widget is missing:** read the log,
`~/.cache/noctalia/noctalia.log` (look for `[ERR]`), or run `noctalia` in a
terminal (Super+Enter still works).

**The laptop screen came back on while docked:** run
`systemctl --user restart kanshi`. Screen settings you picked are in
`~/.config/kanshi/display.conf`; delete it and rebuild to reset them.

**A charging mode button does nothing:** try it in a terminal,
`battery-charge-mode travel`, and read the error.

**VS Code says "OS keyring couldn't be identified":** add
`"password-store": "gnome-libsecret"` to `~/.vscode/argv.json` and restart
it. Logins are stored in GNOME Keyring, which unlocks when you log in.

**No login screen / black screen:** press Ctrl+Alt+F2, log in as text, and run
`sudo nixos-rebuild switch --rollback`. Or restart and pick the previous
entry in the boot menu.
