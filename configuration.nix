# ═══════════════════════════════════════════════════════════════════════════
#  configuration.nix  —  the machine: ThinkPad T14s Gen 3 AMD ("nixos")
# ═══════════════════════════════════════════════════════════════════════════
#
#  Apply:   rebuild            (fish abbreviation for `nh os switch`)
#  Update:  upgrade            (newest versions of everything, shows a diff, asks y/n)
#  Undo:    sudo nixos-rebuild switch --rollback   or pick an older boot entry
#  Search:  https://search.nixos.org  (Options tab = every setting below)
#
#  modules/ is for the machine, home/ is for you. One topic per file.

{
  pkgs,
  flakeDir,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix # CPU, kernel modules (generated)
    ./disko.nix # the disk layout: LUKS + btrfs
    ./modules/desktop.nix # Umbriel, Noctalia, the login screen, fonts, portals
    ./modules/dev.nix # Docker, VMs, nix-ld, direnv
    ./modules/battery.nix # charging modes (Docked / Drain / Pause / Balanced / Full)
    ./modules/thinkpad.nix # fan modes, lid-logo LED, temperatures
    ./modules/backup.nix # encrypted restic backups (off until you pick a destination)
  ];

  # ─────────────────────────────────────────────────────────────────────────
  #  Boot
  # ─────────────────────────────────────────────────────────────────────────
  boot = {
    # Newest kernel: best for the Radeon 680M, the MT7922 Wi-Fi and suspend.
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10; # boot menu keeps the last 10 versions to roll back to
        editor = false; # no editing kernel options at boot (would bypass the login)
      };
      efi.canTouchEfiVariables = true;
    };

    # Graphical boot splash with the disk password box, no scrolling text.
    # (The early boot is systemd-based; on nixos-unstable that's the only kind.)
    plymouth.enable = true;
    consoleLogLevel = 3;
    kernelParams = [
      "quiet"
      "splash"
      "udev.log_level=3"
    ];

    kernel.sysctl = {
      # Tuned for zram (swap in compressed RAM): swapping is cheap, so do it
      # early, and read one page at a time (values from the kernel docs / ArchWiki).
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      # Editors, dev servers and file watchers run out of these fast
      # (Fedora's default here was 127904 watches and 128 instances).
      "fs.inotify.max_user_watches" = 524288;
      "fs.inotify.max_user_instances" = 1024;
    };
  };

  # Swap in RAM, compressed ~3x. Grows only when needed. Check with: zramctl
  # (No disk swap, so no hibernate. Normal sleep works.)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # btrfs checks every block for silent corruption once a month.
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  # ─────────────────────────────────────────────────────────────────────────
  #  Nix itself
  # ─────────────────────────────────────────────────────────────────────────
  nix = {
    package = pkgs.nixVersions.latest;
    channel.enable = false; # flake only: no old-style channels to drift out of sync
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false; # no "Git tree is dirty" warning on every rebuild
      download-buffer-size = 268435456; # 256 MiB: avoids "download buffer is full" on big updates
    };
    # Hard-links identical files in the store; runs on a timer, never slows builds.
    optimise.automatic = true;
  };

  nixpkgs.config.allowUnfree = true; # VS Code-style apps, Discord, Brave, Obsidian, Unity Hub...

  # nh: a friendlier nixos-rebuild. Shows what changes before applying, and
  # cleans the store weekly while ALWAYS keeping your last 10 versions plus
  # everything from the last 14 days.
  programs.nh = {
    enable = true;
    flake = flakeDir;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 10 --keep-since 14d";
    };
  };

  # ─────────────────────────────────────────────────────────────────────────
  #  Network
  # ─────────────────────────────────────────────────────────────────────────
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    # The firewall is on by default (nothing open). LocalSend opens its own
    # port in modules/desktop.nix.
  };
  services.resolved.enable = true; # DNS cache + DNS-over-TLS capable, like Fedora

  # ─────────────────────────────────────────────────────────────────────────
  #  Language, keyboard, time
  # ─────────────────────────────────────────────────────────────────────────
  time.timeZone = "Asia/Tbilisi";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ka_GE.UTF-8";
    LC_IDENTIFICATION = "ka_GE.UTF-8";
    LC_MEASUREMENT = "ka_GE.UTF-8";
    LC_MONETARY = "ka_GE.UTF-8";
    LC_NAME = "ka_GE.UTF-8";
    LC_NUMERIC = "ka_GE.UTF-8";
    LC_PAPER = "ka_GE.UTF-8";
    LC_TELEPHONE = "ka_GE.UTF-8";
    LC_TIME = "ka_GE.UTF-8";
  };
  console.keyMap = "us";
  # The desktop keyboard (English + Georgian, both Alt keys switch) is set in
  # home/umbriel/input.nix.

  # ─────────────────────────────────────────────────────────────────────────
  #  Hardware
  # ─────────────────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true; # shows headphone battery levels
  };

  # Printing, and finding printers on the network.
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # BIOS, Thunderbolt and other firmware updates from Lenovo (LVFS):
  #   fwupdmgr refresh && fwupdmgr get-updates
  services.fwupd.enable = true;

  # Sound: PipeWire, with PulseAudio/ALSA/JACK apps working unchanged.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # JACK apps: run them through `pw-jack <app>` (the global switch is deprecated).

    # PipeWire also handles cameras. Two fixes so camera apps (Camera,
    # Brave, Discord...) list each real webcam once:
    wireplumber.extraConfig."10-webcam-v4l2-only" = {
      # 1. Each camera showed up twice: through v4l2 (the normal way for USB
      #    webcams) and through libcamera (only needed for Intel MIPI laptop
      #    cameras). libcamera off = no duplicates.
      "wireplumber.profiles".main."monitor.libcamera" = "disabled";

      # 2. The built-in camera module also has an INFRARED camera (greyscale,
      #    for Windows Hello). Hide it, by its fixed internal USB address.
      "monitor.v4l2.rules" = [
        {
          matches = [ { "node.name" = "v4l2_input.pci-0000_34_00.0-usb-0_1_1.2"; } ];
          actions.update-props."node.disabled" = true;
        }
      ];
    };
  };

  # D-Bus broker: the faster D-Bus daemon Fedora also uses.
  services.dbus.implementation = "broker";

  # Under memory pressure, kill the hungriest app instead of freezing the
  # whole laptop for minutes.
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
  };

  # ─────────────────────────────────────────────────────────────────────────
  #  Shell and basic programs (the rest of your apps are in home/)
  # ─────────────────────────────────────────────────────────────────────────
  programs.fish.enable = true; # your login shell; configured in home/shell.nix
  programs.firefox.enable = true;
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    # $EDITOR stays nano, like on Fedora (home/shell.nix).
  };

  # `, cowsay hi` runs any program without installing it, and unknown
  # commands say which package has them.
  programs.nix-index-database.comma.enable = true;
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false; # the old version; doesn't work with flakes

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    unzip
    zip
    file
    tree
    htop
    pciutils
    usbutils
    lsof
  ];

  # ─────────────────────────────────────────────────────────────────────────
  #  You
  # ─────────────────────────────────────────────────────────────────────────
  users.users.otari = {
    isNormalUser = true;
    description = "Otari Pkhovelishvili";
    shell = pkgs.fish;
    extraGroups = [
      "wheel" # sudo
      "networkmanager"
    ];
    # More groups are added where they're needed: docker/libvirtd in
    # modules/dev.nix, video/i2c in modules/desktop.nix.
  };

  # ─────────────────────────────────────────────────────────────────────────
  #  The release this machine was installed with. Never change it: it is
  #  not "the version you run", it keeps old data formats readable.
  # ─────────────────────────────────────────────────────────────────────────
  system.stateVersion = "26.11";
}
