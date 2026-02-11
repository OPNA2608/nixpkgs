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

  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.videoDrivers = [
    # Want Radeon driver if usable. These machines only support oooold cards, and the old driver at least somewhat supports big-endian...
    "radeon"
    "modesetting"
    "fbdev"
  ];

  # Not supported
  boot.loader.grub.memtest86.enable = lib.mkForce false;

  # Personal preference
  nix.package = pkgs.lixPackageSets.latest.lix;

  nixpkgs.overlays = [
    # ...and to avoid building both nix and lix...
    (final: prev: {
      nix = prev.lixPackageSets.latest.lix;
    })
  ];

  environment.systemPackages = with pkgs; [
    # Wrangling the wacky disk & partition formats
    hfsutils
    mac-fdisk
    pdisk

    # personal preferences
    ## *gotta* have a fetch... but fastfetch needs wayyyy too much :(
    cpufetch
    disfetch

    ## for messing around on the machine
    btop
    ghc
    htop
    lua5_5
    mesa-demos
    milkytracker
    python3
  ];
}
