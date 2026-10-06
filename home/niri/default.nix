# ═══════════════════════════════════════════════════════════════════════════
#  home/niri/default.nix  —  the PERSONAL side of niri (Home Manager module)
# ═══════════════════════════════════════════════════════════════════════════
#
#  niri reads exactly ONE file:  ~/.config/niri/config.kdl
#
#  One giant file gets messy, so we keep small topic files in ./kdl/
#  and let Nix glue them together. Then Nix CHECKS the result with
#  `niri validate` while building. A typo stops the rebuild with an error
#  message, instead of giving you a broken desktop.
#
#  Hooked up from home.nix with:  imports = [ ./home/niri ];
#  (Writing a folder name makes Nix open the default.nix inside it.)

{ pkgs, lib, ... }:

let
  # ── Step 1: the list of config pieces ────────────────────────────────────
  # niri doesn't care about the order. If you create a new .kdl file,
  # add it here (and `git add` it, or Nix won't see it).
  pieces = [
    ./kdl/startup.kdl     # programs that start when you log in
    ./kdl/input.kdl       # keyboard, touchpad, TrackPoint
    ./kdl/outputs.kdl     # your screen: size (scale), resolution
    ./kdl/look.kdl        # gaps, focus border, shadows, cursor
    ./kdl/animations.kdl  # how windows move and appear
    ./kdl/rules.kdl       # special rules for some windows
    ./kdl/binds.kdl       # keyboard shortcuts
  ];

  # ── Step 2: glue them into one text file ────────────────────────────────
  # builtins.readFile reads a file as text.
  # concatMapStringsSep "\n\n" reads EACH piece and joins them,
  # with an empty line between them.
  # writeText saves that text as a file in /nix/store.
  joined = pkgs.writeText "niri-config.kdl"
    (lib.concatMapStringsSep "\n\n" builtins.readFile pieces);

  # ── Step 3: let niri check it ───────────────────────────────────────────
  # runCommand runs a tiny shell script during the build.
  # `niri validate -c FILE` exits with an error if FILE has a mistake,
  # which makes the whole rebuild stop and print what's wrong.
  # If it's valid, we copy it to $out (the result of this step).
  checked = pkgs.runCommand "niri-config-checked.kdl"
    { nativeBuildInputs = [ pkgs.niri ]; }
    ''
      export HOME=$TMPDIR
      niri validate -c ${joined}
      cp ${joined} $out
    '';
  # If this ever fails with a strange error that is NOT about your config,
  # use `joined` instead of `checked` in Step 4 below (no checking).

  # (The old `niri-polkit-agent` helper that lived here is gone: Noctalia
  # v5 shows the password pop-up itself, see `polkit_agent` in
  # ../noctalia/default.nix.)
in
{
  # ── Step 4: put the checked file where niri looks for it ────────────────
  xdg.configFile."niri/config.kdl".source = checked;

  # Make sure the screenshots folder exists (.keep is an empty placeholder).
  home.file."Pictures/Screenshots/.keep".text = "";

  home.packages = [
    pkgs.bibata-cursors  # a smooth modern mouse cursor (set in look.kdl)
    pkgs.loupe           # fast image viewer, written in Rust
  ];
}
