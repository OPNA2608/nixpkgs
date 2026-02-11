{ config, pkgs, lib, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  isoImage = {
    makeEfiBootable = lib.mkForce false;
    makeChrpBootable = lib.mkForce true;
  };

  # Don't care about ZFS
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # Want Radeon driver. These machines only support oooold cards, and the old driver at least somewhat supports big-endian
  services.xserver.videoDrivers = [
    "radeon"
    "modesetting"
    "fbdev"
  ];

  # Not supported
  boot.loader.grub.memtest86.enable = lib.mkForce false;

  # Personal preference
  nix.package = pkgs.lixPackageSets.latest.lix;

  environment.systemPackages = with pkgs; [
    # *gotta* have a fetch
    fastfetch

    # Wrangling the wacky disk & partition formats
    hfsutils
    mac-fdisk
    pdisk
  ];
}
