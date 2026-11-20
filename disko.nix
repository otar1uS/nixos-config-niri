# ═══════════════════════════════════════════════════════════════════════════
#  disko.nix  —  the disk layout, used ONCE when installing
# ═══════════════════════════════════════════════════════════════════════════
#
#  WARNING: running disko with this file ERASES the whole disk below.
#  It only runs when you call it yourself from the installer (README:
#  "Install"). Rebuilds never touch the disk layout.
#
#  Layout (238 GB KIOXIA NVMe):
#    1 GB   EFI partition        /boot   (systemd-boot + 10 kernels fit easily)
#    rest   LUKS2 (password at boot)
#             └─ btrfs, zstd-compressed, with subvolumes:
#                  /root  ->  /
#                  /home  ->  /home
#                  /nix   ->  /nix
#                  /log   ->  /var/log
#  No swap partition: zram (configuration.nix) is the swap.
#
#  The disk is picked by its permanent ID, not /dev/nvme0n1, so a USB stick
#  can never be wiped by mistake. Check it in the installer with:
#    ls -l /dev/disk/by-id/ | grep nvme

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-KBG5AZNV256G_LA_KIOXIA_82DPG6HUQBQK";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            # No keyFile: disko asks for the disk password while installing.
            settings.allowDiscards = true; # lets the SSD trim through the encryption
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes =
                let
                  opts = [
                    "compress=zstd"
                    "noatime"
                  ];
                in
                {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = opts;
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = opts;
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = opts;
                  };
                  "/log" = {
                    mountpoint = "/var/log";
                    mountOptions = opts;
                  };
                };
            };
          };
        };
      };
    };
  };
}
