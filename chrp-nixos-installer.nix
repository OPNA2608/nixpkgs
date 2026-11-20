{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  # Basic startx setup
  #services.xserver.enable = true;

  isoImage = {
    makeEfiBootable = lib.mkForce false;
    makeChrpBootable = lib.mkForce true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.xserver.displayManager.startx.enable = config.services.xserver.enable;
  services.xserver.videoDrivers = [
    # Want Radeon driver if usable. These machines only support oooold cards, and the old driver at least somewhat supports big-endian...
    "radeon"
    "modesetting"
    "fbdev"
  ];
  services.speechd.enable = false;

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

  environment.systemPackages =
    with pkgs;
    (
      [
        # Wrangling the wacky disk & partition formats
        hfsutils
        #mac-fdisk # currently FTBFS
        pdisk

        # personal preferences
        ## *gotta* have a fetch... but fastfetch needs wayyyy too much :(
        cpufetch
        disfetch

        ## for messing around on the machine
        btop
        htop
        ghc
        lua5_5
        python3
        spidermonkey_140
      ]
      ++ lib.optionals config.services.xserver.enable [
        mesa-demos
      ]
    );
}
