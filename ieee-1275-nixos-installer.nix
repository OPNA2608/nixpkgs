{ config, pkgs, lib, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  isoImage = {
    makeIeee1275Bootable = lib.mkForce true;
    makeEfiBootable = lib.mkForce false;
  };

  boot.loader.grub.memtest86.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    fastfetch
    hyfetch
  ];
}
