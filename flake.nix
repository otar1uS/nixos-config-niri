{
  description = "My NixOS config";

  inputs = {
    # Two "channels" (snapshots of all NixOS packages):
    #   stable   = tested, changes slowly. The base of the system and your apps.
    #   unstable = newest versions. Used for the desktop (see modules/unstable.nix).
    # Update both with:  upgrade   (an alias in home.nix)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    herdr.url = "github:herdrdev/herdr";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # A ready-made, weekly-updated index of which package contains which
    # program. Powers `comma` (run any program without installing it:
    # `, cowsay hi`) and "command not found" hints in the terminal.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # (niri needs no extra input: it already lives in nixpkgs.)
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nix-index-database, ... }:
    let
      system = "x86_64-linux";

      # The unstable package set, made ONCE here and shared with every file
      # below (the system files AND home.nix), so they all use the same one.
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true; # separate package set, so it needs its own unfree switch
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        # Lets system files (configuration.nix, modules/*.nix) ask for
        # `pkgs-unstable` in their first line, just like home.nix does.
        specialArgs = { inherit pkgs-unstable; };

        modules = [
          ./configuration.nix
          nix-index-database.nixosModules.default # adds the options used in configuration.nix (comma)
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit pkgs-unstable; }; # the same set as above
            home-manager.users.otari = import ./home.nix;
          }
        ];
      };
    };
}
