{ config, pkgs, lib, ... }:

let
  cfg = config.programs.lomiri;
in {
  options.programs.lomiri= {
    enable = lib.mkEnableOption (lib.mdDoc ''
      the Lomiri graphical shell (formerly known as Unity8)'');
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        lomiri-session # Wrappers to properly launch the session
        lomiri

        # Services
        libayatana-common
        ayatana-indicator-session
        ayatana-indicator-messages
        lomiri-indicator-network

        # Used(?) themes
        ubuntu-themes
        vanilla-dmz
      ];
    };

    # Copy-pasted
    hardware.opengl.enable = lib.mkDefault true;
    fonts.enableDefaultFonts = lib.mkDefault true;
    programs.dconf.enable = lib.mkDefault true;
    programs.xwayland.enable = lib.mkDefault true;

    # To make the Lomiri desktop session available if a display manager like SDDM is enabled:
    services.xserver.displayManager.sessionPackages = [ pkgs.lomiri-session ];

    # TODO is this really the way to do this, can't we reuse upstream's files?
    # Shadows ayatana-indicators.target from libayatana-common, brings up required indicator services
    systemd.user.targets."ayatana-indicators" = {
      description = "Target representing the lifecycle of the Ayatana Indicators. Each indicator should be bound to it in its individual service file.";
      partOf = [ "graphical-session.target" ];
      wants = [
        "ayatana-indicator-session.service"
        "ayatana-indicator-messages.service"
        "lomiri-indicator-network.service"
      ];
    };
  };

  meta.maintainers = with lib.maintainers; [ OPNA2608 ];
}
