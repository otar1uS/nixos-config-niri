# ═══════════════════════════════════════════════════════════════════════════
#  home/starship.nix  —  a nicer terminal prompt
# ═══════════════════════════════════════════════════════════════════════════
#
#  Starship (written in Rust) replaces the plain  [otari@nixos:~]$  line
#  with a smart one: it shows the git branch, the language version of the
#  project you're in (Node, Python, Go...), and whether the last command
#  failed. It lives in your shell, so it works in every terminal.
#
#  These settings only change colours to Gruvbox. Everything else stays
#  default. Full list of options: https://starship.rs/config/

{ ... }:

{
  programs.starship = {
    enable = true;   # Home Manager also hooks it into bash for you

    settings = {
      # No empty line before every prompt.
      add_newline = false;

      # The arrow at the end of the prompt:
      # green when the last command worked, red when it failed.
      character = {
        success_symbol = "[❯](bold #b8bb26)";
        error_symbol = "[❯](bold #fb4934)";
      };

      # The current folder, in yellow.
      directory.style = "bold #fabd2f";

      # The git branch, in orange.
      git_branch.style = "bold #fe8019";
    };
  };
}
