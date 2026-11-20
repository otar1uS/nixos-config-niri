# Hardware detected on this ThinkPad (what `nixos-generate-config` prints).
#
# The disks are NOT here: disko.nix describes them. When installing, run
#   nixos-generate-config --no-filesystems --show-hardware-config
# and compare its output with this file. If it lists more kernel modules,
# copy them in.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
