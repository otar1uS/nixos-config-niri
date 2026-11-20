# ═══════════════════════════════════════════════════════════════════════════
#  home/nvim  —  Neovim with your own LazyVim config (copied from Fedora)
# ═══════════════════════════════════════════════════════════════════════════
#
#  ./config is your ~/.config/nvim. It is LINKED, not copied into the Nix
#  store, so it stays editable and lazy.nvim can update lazy-lock.json.
#  Edit it in place (~/.config/nvim or ~/nixos-config/home/nvim/config):
#  no rebuild needed, and git sees the changes.
#
#  Neovim itself is installed in configuration.nix (programs.neovim).
#  LazyVim's language servers come from Mason; nix-ld (modules/dev.nix) lets
#  those downloaded binaries run.

{
  config,
  pkgs,
  flakeDir,
  ...
}:

{
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${flakeDir}/home/nvim/config";

  # What LazyVim expects to find on PATH.
  home.packages = with pkgs; [
    tree-sitter # compiles syntax parsers
    lua-language-server
    stylua
  ];
}
