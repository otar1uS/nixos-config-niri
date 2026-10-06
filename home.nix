{ pkgs,pkgs-unstable, ... }: {
  # Your personal desktop settings, one small file per topic in ./home/.
  imports = [
    ./home/niri # niri's settings: shortcuts, looks, touchpad (a folder: Nix opens its default.nix)
    ./home/noctalia # the bar, launcher, notifications, lock screen + your own plugins (a folder)
    ./home/ghostty.nix # the terminal
    ./home/yazi.nix # file manager inside the terminal
    ./home/starship.nix # the colourful prompt in your terminal
    ./home/theme.nix # icons, dark mode, cursor and fonts for GTK apps (Nautilus, Loupe)
    ./home/kanshi.nix # laptop screen turns off when a monitor is plugged in
    ./home/dev.nix # developer tools: delta, atuin, tldr, lazygit, bat, gh, git defaults
    ./home/voice.nix # voice typing on F9 / Super+D (Voxtype + Parakeet, offline)
    ./home/camera.nix # webcam: "Camera" for photos/videos, "Camera Settings" (remembered)
  ];

  home.packages =
  (with pkgs; [
discord
telegram-desktop
ncspot
obsidian
  ])
  ++
  (with pkgs-unstable; [
    claude-code # an app, but it changes weekly, so it comes from unstable too
    herdr # terminal multiplexer that shows what each AI agent (Claude Code etc.) is doing; only in unstable
  ]);
  programs.git = {
    enable = true;
    settings = {
      user.name = "Otari Pkhovelishvili";
      user.email = "opkhovelishvili@gmail.com";   
      init.defaultBranch = "main";      
    };
  };
  
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "eza -la";  
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#nixos";
      # Get the newest versions of everything (both channels), then apply.
      # nh shows a list of what changes ("noctalia 5.2.0 -> 5.2.1") and asks
      # y/n before applying. Afterwards, commit flake.lock in git so you can
      # always go back to the versions that worked.
      upgrade = "nh os switch --update --ask"; # nh knows the folder (programs.nh.flake)
    };
  };

  # Hooks for tools you already installed system-wide
  programs.zoxide.enable = true;   # adds the `z` command
  programs.fzf.enable = true;      # Ctrl+T file search (Ctrl+R history is atuin's now, see home/dev.nix)

  home.stateVersion = "26.05";
}
