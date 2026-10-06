# Fedora Workstation setup

Scripts that set up a fresh **Fedora Workstation** (GNOME) on the ThinkPad
T14s the way the NixOS config in this repo had it.

## Run it

After installing Fedora, log in to GNOME, open a terminal and run:

```bash
sudo dnf install -y git
git clone https://github.com/<you>/nixos-config.git ~/nixos-config
cd ~/nixos-config/fedora
./install.sh          # as yourself, NOT with sudo
```

Then reboot once. You can run it again at any time; steps that are already
done are skipped. Anything that couldn't be installed is listed at the end.

| Step | What it does | NixOS file it replaces |
|---|---|---|
| `steps/10-repos.sh` | RPM Fusion, VS Code, Docker, COPR (ghostty, starship, lazygit, lazydocker), Flathub | `flake.nix` |
| `steps/20-packages.sh` | all your programs, codecs, Discord / Telegram / Obsidian, the Nerd Font | `configuration.nix`, `home.nix` |
| `steps/30-thinkpad.sh` | battery modes, fan modes, lid LED | `modules/battery.nix`, `modules/thinkpad.nix` |
| `steps/40-system.sh` | time zone, Georgian formats, docker, webcam fix, kernel settings | `configuration.nix` |
| `steps/50-gnome.sh` | English + Georgian (Alt+Shift), key repeat, touchpad, dark mode, lock after 10 min | `home/niri/kdl/input.kdl` |
| `steps/60-dotfiles.sh` | git + delta, prompt, atuin, ghostty, bat, lazygit, aliases | `home/*.nix` |
| `steps/70-backup.sh` | daily encrypted backups (**run it yourself**, see below) | `modules/backup.nix` |

Every step can be run on its own, e.g. `./steps/30-thinkpad.sh`.

## Battery modes

```bash
battery-charge-mode            # show the current mode
battery-charge-mode desk       # 35-40%: plugged in all day (kindest to the battery)
battery-charge-mode daily      # 75-80%: everyday balance
battery-charge-mode travel     # 95-100%: charge to full before going out
```

No password needed. Your last mode comes back after every reboot. To change
the numbers, edit `MODES` in `files/system/battery-charge-mode` and run
`./steps/30-thinkpad.sh` again.

Leave **Settings → Power → Preserve Battery Health** off. It's GNOME's own
charge limit, and the two would keep overwriting each other.

## Fan and lid LED

```bash
thinkpad                       # temperatures, fan speed, modes
thinkpad fan auto|charger|max  # charger = full speed only while plugged in
thinkpad led off|on|charging   # the red dot on the lid's ThinkPad logo
```

Fan control needs one reboot after the first install.

## Screens (laptop screen off when the monitor is plugged in)

GNOME does this by itself; it just has to be told once:

1. Plug in the Dell.
2. Press **Super+P** (or open Settings → Displays) and pick **External only**.
   Set 3440×1440 at **120 Hz** while you're there.
3. Unplug it, then open Settings → Displays and set the laptop screen to **125%**.

GNOME remembers the layout for each combination of screens, so from now on
plugging the Dell in turns the laptop screen off, and unplugging turns it
back on. Closing the lid while the monitor is connected also works and
doesn't put the laptop to sleep.

## Backups

**Turn these on.** Without them, one bad command can wipe your home folder
with no way back.

```bash
./steps/70-backup.sh /run/media/$USER/<drive name>/restic   # an external drive
```

It prints a password once: **save it in a password manager**. Without it
the backups can't be opened. After that, a backup runs every day by itself.

```bash
sudo systemctl start restic-home                                 # back up now
restic-home snapshots                                            # list backups
restic-home restore latest --target /tmp/restore --include ~/code   # get files back
```

Also push your projects to GitHub often. That's a second copy of your code.

## After installing

- `gh auth login`: log in to GitHub. Then `git push` never asks for a password.
- `rustup default stable`: if you need Rust.
- Firefox: sign in to Firefox Sync for your bookmarks and passwords.
- Camera Settings (from Flathub) saves your webcam brightness and exposure.

## Not set up by these scripts

- **Voice typing** (Voxtype + Parakeet, F9): install Voxtype using its
  project's Fedora instructions, then add an F9 shortcut in Settings → Keyboard → Custom Shortcuts running
  `voxtype record toggle`.
- **herdr**: see https://github.com/herdrdev/herdr.
- **niri + Noctalia**: this setup uses GNOME. If you'd rather keep niri, it's
  in Fedora (`sudo dnf install niri`). Your niri settings are in
  `home/niri/kdl/`, and the screen profiles for kanshi are in `home/kanshi.nix`.
