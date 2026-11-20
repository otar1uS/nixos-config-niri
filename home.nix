# Your personal setup (Home Manager). One small file per topic in ./home/.
{ ... }:

{
  imports = [
    ./home/umbriel # the compositor: keys, layout, input, looks, rules (a folder)
    ./home/noctalia # the shell: bar, launcher, lock, theme + your plugins (a folder)
    ./home/kanshi.nix # which screens are on: laptop off when the Dell is plugged in
    ./home/theme.nix # GTK dark mode, icons, cursor, fonts
    ./home/shell.nix # fish, prompt, abbreviations, zoxide, eza, navi
    ./home/foot.nix # the terminal
    ./home/dev.nix # git, delta, gh, lazygit, atuin, herdr, npm
    ./home/packages.nix # command-line tools and languages
    ./home/apps.nix # desktop apps and default apps
    ./home/nvim # Neovim with your LazyVim config
    ./home/yazi.nix # terminal file manager
    ./home/voice.nix # voice typing on F9 (Voxtype + Parakeet, offline)
    ./home/camera.nix # webcam apps, and keeping its picture settings
  ];

  # The release this home was first set up with. Never change it.
  home.stateVersion = "26.11";
}
