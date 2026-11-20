# ═══════════════════════════════════════════════════════════════════════════
#  modules/dev.nix  —  the SYSTEM side of development
# ═══════════════════════════════════════════════════════════════════════════
#
#  Only what needs root: container and VM daemons, and the compatibility
#  layer for downloaded binaries. Your dev tools (node, go, kubectl...) are
#  in home/packages.nix.

{ ... }:

{
  # ── Docker ─────────────────────────────────────────────────────────────
  # `docker compose` and buildx come with it.
  # NOTE: the "docker" group is effectively root (a container can mount /).
  # Same as on Fedora. Remove the group below to use `sudo docker` instead.
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true; # weekly: delete stopped containers and dangling images
  };

  # ── Virtual machines: libvirt + virt-manager (as on Fedora) ────────────
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true; # pass USB sticks into VMs
  programs.virt-manager.enable = true;

  users.users.otari.extraGroups = [
    "docker"
    "libvirtd"
    "kvm"
  ];

  # ── Downloaded binaries ────────────────────────────────────────────────
  # NixOS has no /usr/lib, so prebuilt programs (Mason's language servers in
  # LazyVim, VS Codium extensions, uv's Python builds, Unity) can't find
  # their libraries. nix-ld provides them.
  programs.nix-ld.enable = true;

  # ── direnv ─────────────────────────────────────────────────────────────
  # `cd` into a project with a .envrc and its own toolchain loads by itself
  # (`use flake` with nix-direnv, cached). Hooks into fish automatically.
  programs.direnv.enable = true;
}
