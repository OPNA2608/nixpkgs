{ config, pkgs, lib, ... }:
{
  imports = [
    ./chrp-nixos-installer.nix
  ];

  isoImage = {
    makeNewWorldMacBootable = lib.mkForce true;
  };
}
