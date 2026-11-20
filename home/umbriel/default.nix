# ═══════════════════════════════════════════════════════════════════════════
#  home/umbriel  —  the compositor (Umbriel), your personal settings
# ═══════════════════════════════════════════════════════════════════════════
#
#  Umbriel reads ONE file: ~/.config/umbriel/config.toml (TOML).
#  Here it is split by topic into small Nix files; each one returns part of
#  the settings, and they're merged into that one file:
#
#    general.nix  autostart (Noctalia), the colour include, hot corner
#    input.nix    keyboard (English + Georgian), touchpad, mouse focus, cursor
#    look.nix     gaps, borders, rounded corners, blur, layout
#    binds.nix    keyboard shortcuts
#    rules.nix    per-window and per-panel rules
#
#  Same names as in Umbriel's docs (https://docs.noctalia.dev/umbriel/),
#  written in Nix:  [input.keyboard] layout = "us"  ->  input.keyboard.layout = "us";
#
#  Saving the file makes Umbriel reload it by itself after a rebuild.
#  Screens are NOT set here: kanshi owns them (home/kanshi.nix).

{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  pieces = [
    ./general.nix
    ./input.nix
    ./look.nix
    ./binds.nix
    ./rules.nix
  ];
  settings = lib.foldl' lib.recursiveUpdate { } (map import pieces);

  configFile = (pkgs.formats.toml { }).generate "umbriel-config.toml" settings;

  # Let Umbriel itself check the file while building (the same Umbriel that
  # runs, from modules/desktop.nix). A typo or an unknown action stops the
  # rebuild with Umbriel's message, instead of a broken desktop.
  umbriel = osConfig.programs.umbriel.package;
  checked = pkgs.runCommand "umbriel-config-checked.toml" { nativeBuildInputs = [ umbriel ]; } ''
    export HOME=$TMPDIR XDG_CONFIG_HOME=$TMPDIR/config XDG_RUNTIME_DIR=$TMPDIR
    umbriel -c ${configFile} config validate
    cp ${configFile} $out
  '';
in
{
  xdg.configFile."umbriel/config.toml".source = checked;
}
