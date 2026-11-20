{
  description = "otari's NixOS: ThinkPad T14s Gen 3 AMD with Umbriel + Noctalia";

  inputs = {
    # One channel for everything: nixos-unstable, the newest packages that
    # passed NixOS's own tests. Umbriel, Noctalia and the greeter are all in it
    # and come prebuilt from cache.nixos.org. Update with `upgrade` (fish).
    # The channels.nixos.org tarball is the same commit as the GitHub branch,
    # but a much smaller download.
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk layout (LUKS + btrfs), used once by the installer.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Known-good hardware settings (ThinkPad, AMD CPU/GPU, SSD).
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Weekly prebuilt "which package has this command" index: powers `,` (comma)
    # and the "command not found" hints.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      disko,
      nixos-hardware,
      nix-index-database,
      ...
    }:
    let
      # Where this repo is cloned. nh, the nvim link and the docs use it.
      flakeDir = "/home/otari/nixos-config";
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit flakeDir; };
        modules = [
          ./configuration.nix
          disko.nixosModules.disko
          nix-index-database.nixosModules.default

          # The T14s profile (TrackPoint, backlight) plus AMD pieces. There is
          # no dedicated "gen3 AMD" profile, so these are the parts that apply.
          nixos-hardware.nixosModules.lenovo-thinkpad-t14s
          nixos-hardware.nixosModules.common-cpu-amd-pstate
          nixos-hardware.nixosModules.common-gpu-amd
          nixos-hardware.nixosModules.common-pc-ssd

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = { inherit flakeDir; };
              users.otari = ./home.nix;
            };
          }
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
