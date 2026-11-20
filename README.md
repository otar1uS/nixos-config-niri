# nixos-config

NixOS (nixos-unstable) flake for the ThinkPad T14s Gen 3 AMD (hostname
`nixos`, user `otari`), with the **Umbriel** compositor and the **Noctalia**
shell.

Why Umbriel and not COSMIC: Umbriel and Noctalia are made by the same team
and built to work together. Your Noctalia bar, plugins (Battery, Display,
ThinkPad), lock screen and login screen carry over unchanged, and Umbriel's
scrolling layout works like niri, so your shortcuts keep working. COSMIC
would replace all of that with its own panel and applets.

| Job | Pick |
|---|---|
| Compositor | **Umbriel** (scrolling layout; dwindle/master/stacking per workspace) |
| Bar, launcher, notifications, lock, OSD, clipboard, screenshots, Alt+Tab | **Noctalia v5** |
| Login screen | **Noctalia Greeter** on greetd, synced with Noctalia's look |
| Colours | from your wallpaper, applied to Noctalia, Umbriel, foot, GTK, btop |
| Screens (laptop off when docked) | **kanshi** + your **Display** panel |
| Battery modes (Docked / Drain / Pause / Balanced / Full) | `battery-mode` + your **Battery** panel |
| Fan modes, lid LED, temperatures | `thinkpad` + your **ThinkPad** panel |
| Terminal / shell / prompt | **foot** / **fish** / **starship** |
| Voice typing | **Voxtype** + NVIDIA **Parakeet**, offline (F9) |
| Keyboard | English + Georgian, **both Alt keys** switch |
| Browser | **Brave** (default), Firefox |
| Disk | LUKS2 + btrfs (zstd), declared in `disko.nix` |
| Backups | **restic** (`modules/backup.nix`, off until you pick a destination) |

Everything comes from one channel, nixos-unstable, prebuilt by
cache.nixos.org (Umbriel, Noctalia and the greeter included).

---

## 1. Before you wipe Fedora: back up

The install **erases the whole disk**. Copy these to an external drive
(replace `/run/media/otari/DRIVE`):

```sh
B=/run/media/otari/DRIVE/fedora-backup
mkdir -p "$B"

# Projects: list anything not pushed to GitHub first
for d in ~/code/*/; do (cd "$d" 2>/dev/null && git rev-parse 2>/dev/null &&
  [ -n "$(git status --porcelain; git log --branches --not --remotes --oneline)" ] &&
  echo "UNPUSHED: $d"); done

rsync -aHAX --info=progress2 \
  ~/code ~/Documents ~/Pictures ~/Videos ~/Music ~/Downloads ~/Backups \
  ~/.claude ~/.claude.json ~/.gemini ~/.bootdev.yaml \
  ~/.local/share/fish/fish_history \
  ~/.config/BraveSoftware ~/.mozilla \
  ~/.var/app/com.vscodium.codium/config/VSCodium ~/.vscode-oss \
  "$B"/

# Secrets go ENCRYPTED (asks for a passphrase; keep it in a password manager)
tar -C ~ -czf - .ssh .local/share/keyrings keyring-backup |
  gpg --symmetric --cipher-algo AES256 -o "$B/secrets.tar.gz.gpg"
gpg -d "$B/secrets.tar.gz.gpg" | tar -tzf -   # check: lists file names only
```

Restore the secrets on NixOS with:

```sh
gpg -d /run/media/otari/DRIVE/fedora-backup/secrets.tar.gz.gpg | tar -C ~ -xzf -
chmod 700 ~/.ssh && chmod 600 ~/.ssh/* && chmod 644 ~/.ssh/*.pub
```

- `.claude.json` and `.gemini` hold login tokens too: re-logging in
  (`claude`, `gemini`) is the alternative to copying them.
- Brave: turning on **Brave Sync** is an easier way to keep tabs and passwords.
- `~/code/*/node_modules` and Unity `Library/` folders are rebuildable; add
  `--exclude node_modules --exclude Library` to skip them.
- Noctalia's settings don't need a backup: this repo recreates them.
- Push this repo first: `git push -u origin feat/umbriel-noctalia`.

## 2. Install

1. Download the **NixOS minimal ISO (unstable)** from
   https://nixos.org/download, write it to a USB stick, boot it (F12 at the
   Lenovo logo). Secure Boot must be off.
2. Get online: `sudo nmtui` (Wi-Fi), then:

```sh
sudo -i
nix-shell -p git
git clone https://github.com/otar1uS/nixos-config-niri /tmp/nixos-config
cd /tmp/nixos-config && git switch feat/umbriel-noctalia

# Check the disk ID in disko.nix matches (KIOXIA ... 82DPG6HUQBQK):
ls -l /dev/disk/by-id/ | grep nvme

# ERASES THE DISK. Asks for the new disk password (you'll type it at every boot).
nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- \
  --mode destroy,format,mount ./disko.nix

# Optional: compare detected hardware with hardware-configuration.nix
nixos-generate-config --no-filesystems --show-hardware-config

nixos-install --flake /tmp/nixos-config#nixos --no-root-passwd
nixos-enter --root /mnt -c 'passwd otari'     # your login password

# Put the repo where the config expects it
mkdir -p /mnt/home/otari && cp -a /tmp/nixos-config /mnt/home/otari/nixos-config
nixos-enter --root /mnt -c 'chown -R otari:users /home/otari/nixos-config'
reboot
```

(If you'd rather use the graphical installer: install with encryption, then
copy `/etc/nixos/hardware-configuration.nix` over the one here, delete
`./disko.nix` from the imports in `configuration.nix`, and run
`sudo nixos-rebuild boot --flake ~/nixos-config#nixos`.)

## 3. First login

1. Disk password, then your password on the Noctalia login screen.
2. `gh auth login` (GitHub; then `git push` never asks again).
3. Restore your backup into `~` (rsync back). Then:
   `atuin import fish` (old history into Ctrl+R) and `rustup default stable`.
4. Plug in the Dell: the laptop screen turns off by itself.
5. Press **Super+Shift+/** to see every shortcut.

VSCodium says "OS keyring couldn't be identified"? Add
`"password-store": "gnome-libsecret"` to `~/.vscode-oss/argv.json`.

## Daily use

| Type | What it does |
|---|---|
| `rebuild` | apply changes to this config |
| `upgrade` | newest versions of everything, shows the diff, asks y/n |
| `cleanup` | free disk space now (also runs weekly, keeps the last 10 versions) |
| `se brave` | search packages |
| `sudo nixos-rebuild switch --rollback` | undo the last rebuild |

These are fish abbreviations: they expand to the real command when you
press space. Flakes only see files git knows about, so `git add` new files
before `rebuild`. After `upgrade`, commit `flake.lock`: it records exact
versions, so you can always go back.

**Safety net:** every rebuild is a boot menu entry (last 10). If something
breaks, reboot and pick the one below the top.

## Files

```
~/nixos-config/
├── flake.nix                 inputs (nixos-unstable, Home Manager, disko, hardware) and wiring
├── flake.lock                exact versions (don't edit; `upgrade` updates it)
├── configuration.nix         the machine: boot, nix, network, sound, locale, you
├── hardware-configuration.nix  detected hardware (kernel modules, CPU)
├── disko.nix                 disk layout: LUKS2 + btrfs subvolumes (used once at install)
├── modules/                  SYSTEM (needs root)
│   ├── desktop.nix           Umbriel, Noctalia, login screen, keyring, portals, fonts
│   ├── dev.nix               Docker, libvirt/virt-manager, nix-ld, direnv
│   ├── battery.nix           charging modes and the `battery-mode` command
│   ├── thinkpad.nix          fan modes, lid LED, the `thinkpad` command
│   └── backup.nix            restic backups (off until set up)
├── home.nix                  YOU: imports the files below
└── home/
    ├── umbriel/              compositor: general, input, look, binds, rules (.nix each)
    ├── noctalia/             shell settings + plugins/ (battery, display, thinkpad)
    ├── kanshi.nix            screen profiles (docked / laptop)
    ├── theme.nix             GTK dark mode, Adwaita icons/cursor/font
    ├── shell.nix             fish, abbreviations, starship, zoxide, eza, navi
    ├── foot.nix              terminal
    ├── dev.nix               git, delta, gh, lazygit, atuin, herdr, npm prefix
    ├── packages.nix          CLI tools and languages
    ├── apps.nix              desktop apps + default apps
    ├── nvim/                 your LazyVim config (config/ is linked, editable)
    ├── voice.nix, camera.nix, yazi.nix
```

Umbriel's settings are Nix attribute sets with the same names as its docs
(`[input.keyboard] layout = "us"` is `input.keyboard.layout = "us";`). They
are merged into `~/.config/umbriel/config.toml` and **checked by Umbriel
while building**, so a typo stops the rebuild instead of breaking the
desktop. Noctalia's settings are checked the same way.

## Shortcuts

| Keys | Action |
|---|---|
| Super+Shift+/ | All shortcuts on screen |
| Super+Space or Super+D | App launcher |
| Super+T / Super+Shift+T | herdr in foot / plain foot (also Super+Enter) |
| Super+E / Super+Y | Nautilus / Yazi |
| F9 or Super+Alt+D | Voice typing: start / stop |
| Both Alt keys | English / Georgian |
| Super+S | Control center |
| Super+X | Power menu |
| Super+Alt+L | Lock |
| Super+Ctrl+V | Clipboard history |
| Super+Shift+W / Super+Alt+W | Wallpapers / Wallhaven browser |
| Super+Shift+, | Noctalia settings |
| Super+Shift+. | Kaomoji |
| Super+B | Battery panel: charging mode, power mode |
| Super+Shift+D | Display panel: screen size, refresh rate |
| Super+Alt+T | ThinkPad panel: temperatures, fan, lid LED |
| Super+Alt+R | Start/stop screen recording |
| Print or Super+Shift+S | Screenshot an area (Ctrl+Print: screen, Alt+Print: window) |
| Alt+Tab | Switch windows |
| Super+Q | Close window |
| Super+O | Overview (or mouse to the top-left corner); start typing to launch |
| Super+H/J/K/L or arrows | Move focus |
| Super+Ctrl+H/J/K/L | Move window |
| Super+Shift+H/J/K/L | Focus other monitor |
| Super+R | Width 1/3, 1/2, 2/3 |
| Super+- / Super+= | Narrower / wider |
| Super+F / Super+Shift+F / Super+M | Full width / fullscreen / maximize to edges |
| Super+V | Float window |
| Super+W | Tabs in this column |
| Super+[ / Super+] | Move window into / out of a column |
| Super+Alt+Space | Cycle layout: scrolling, dwindle, master, stacking |
| Super+\` / Super+Shift+\` | Scratchpad: show / park a window |
| Super+1..9 | Go to workspace |
| Super+Ctrl+1..9 / Super+Shift+1..9 | Send column / window to workspace |
| Super+U / Super+I | Workspace down / up |
| Super+Escape | Let a VM or game grab all keys (press again to undo) |
| Super+Shift+E | Log out |

## Terminal tools

| Type | What it does |
|---|---|
| `battery-mode` (`bm`) | charging mode: `bm drain`, `bm docked`, `bm json` |
| `thinkpad` | temperatures, fan, LED as JSON; `thinkpad fan charger` |
| `, cowsay hi` | run any program without installing it |
| Ctrl+R / Ctrl+T / Ctrl+G | history (atuin) / files (fzf) / cheat sheets (navi) |
| `z proj` | jump to a folder you've visited |
| `y` | yazi; the shell follows to where you quit |
| `tldr tar`, `lazygit`, `bat file` | examples, git TUI, coloured cat |

Unknown command? The terminal tells you which package has it.

## How to change things

Edit, `git add` new files, `rebuild`. Umbriel and Noctalia reload by themselves.

| I want to change... | File |
|---|---|
| A shortcut | `home/umbriel/binds.nix` |
| Gaps, borders, blur, layout | `home/umbriel/look.nix` |
| Keyboard layouts / switch key, touchpad | `home/umbriel/input.nix` |
| Window rules | `home/umbriel/rules.nix` |
| Bar, theme, idle/lock times, location | `home/noctalia/default.nix` |
| Which screens are on when | `home/kanshi.nix` |
| Screen size / refresh rate | Display panel (Super+Shift+D), remembered |
| Charging modes and their % | `modules/battery.nix` (`modes`) |
| Apps | `home/apps.nix`, CLI tools `home/packages.nix` |
| Turn on backups | `modules/backup.nix` (2 steps at the top) |

Anything you click in Noctalia's Settings is saved to
`~/.local/state/noctalia/settings.toml` and wins over the Nix settings.
Delete that file to go back to exactly what Nix says.

## If something breaks

- **Rebuild stops with an Umbriel or Noctalia config error:** that's the
  check working. Read the message, fix that line.
- **No bar:** `journalctl --user -b | grep -i noctalia`, or run `noctalia`
  in a terminal. Umbriel's own log: `~/.cache/umbriel/umbriel.log`.
- **Laptop screen came back on while docked:** `systemctl --user restart kanshi`.
  Your screen choices are in `~/.config/kanshi/display.conf`; delete it and
  rebuild to reset.
- **A charging mode does nothing:** run `battery-mode drain` in a terminal and read the error.
- **Black screen / no login screen:** Ctrl+Alt+F2, log in as text, run
  `sudo nixos-rebuild switch --rollback`. Or reboot into the previous boot entry.
- **Want an older Umbriel:** `git log flake.lock`, check out the previous
  lock, `rebuild`.
