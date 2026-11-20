# ═══════════════════════════════════════════════════════════════════════════
#  home/shell.nix  —  fish, the prompt, and small helpers around it
# ═══════════════════════════════════════════════════════════════════════════
#
#  Abbreviations expand when you press space, so you always see the real
#  command before it runs.
#    rebuild   apply this config
#    upgrade   newest versions of everything, shows what changes, asks y/n
#    se        search packages
#    bm        battery mode (`bm drain`, `bm docked`...)
#  Ctrl+R history (atuin), Ctrl+T files (fzf), Ctrl+G cheat sheets (navi),
#  `z <part of a folder name>` jumps there (zoxide).

{ ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting # no "Welcome to fish"
    '';

    shellAbbrs = {
      rebuild = "nh os switch";
      upgrade = "nh os switch --update --ask";
      up = "nh os switch --update --ask"; # your Fedora `up`, same idea
      se = "nh search";
      bm = "battery-mode";
      cleanup = "nh clean all --keep 10 --keep-since 14d"; # free disk now (also runs weekly)
    };
  };

  # Plain bash still gets your environment (scripts, `nix develop`).
  programs.bash.enable = true;

  home.sessionVariables.EDITOR = "nano"; # as on Fedora; `nvim` is one word away

  # Your own scripts and tools installed by language package managers.
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin" # go install (bootdev)
    "$HOME/.cargo/bin" # cargo install
    "$HOME/.npm-global/bin" # npm install -g (see home/dev.nix)
  ];

  # The prompt: git branch, language versions, red arrow on failure.
  # Colours come from the terminal, which Noctalia themes from your wallpaper.
  programs.starship = {
    enable = true;
    settings.add_newline = false;
  };

  programs.zoxide.enable = true; # `z proj` -> ~/code/project
  programs.fzf = {
    enable = true; # Ctrl+T: pick a file
    historyWidget.command = ""; # Ctrl+R belongs to atuin (home/dev.nix)
  };
  programs.navi.enable = true; # Ctrl+G: cheat sheets, the pick lands on your prompt
  programs.eza = {
    enable = true; # ls, ll, la, lt with colours and git status
    git = true;
    icons = "auto";
  };
}
