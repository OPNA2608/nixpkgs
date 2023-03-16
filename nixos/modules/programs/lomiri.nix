{ config, pkgs, lib, ... }:

let
  cfg = config.programs.lomiri;
in {
  options.programs.lomiri= {
    enable = lib.mkEnableOption (lib.mdDoc ''
      the Lomiri graphical shell (formerly known as Unity8)'');
  };

  config = let
    indicator-services = with pkgs; [
      ayatana-indicator-application
      ayatana-indicator-bluetooth
      ayatana-indicator-datetime
      ayatana-indicator-display
      ayatana-indicator-keyboard
      ayatana-indicator-messages
      ayatana-indicator-notifications
      ayatana-indicator-power
      ayatana-indicator-printers
      ayatana-indicator-session
      ayatana-indicator-sound
      lomiri-indicator-network
    ];
  in
  lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        lomiri-session # Wrappers to properly launch the session
        lomiri
        # not having its desktop file for Xwayland available causes any X11 application to crash the session
        qtmir
        lomiri-system-settings
        morph-browser
        lomiri-terminal-app

        # TODO OSK does not work yet
        # lomiri-keyboard is a plugin for maliit-framework, which still seems incapable of loading any plugins at all.
        # maliit-framework's maliit-server hardcodes a plugin name & location to load, and needs the plugin's glib schema.
        # It (maliit-server or the plugin?) also has a hardcoded path to hunspell dictionaries for text prediction
        maliit-framework
        lomiri-keyboard

        # Required/Expected user services
        libayatana-common
        lomiri-thumbnailer
        lomiri-url-dispatcher
        ubports-click
        lomiri-download-manager
        lomiri-schemas # exposes some required dbus interfaces
        hfd-service
        history-service
        telephony-service
        telepathy-mission-control
        repowerd
        content-hub

        # Used(?) themes
        ubuntu-themes
        vanilla-dmz
      ] ++ indicator-services;
    };

    # Required/Expected system services
    systemd.packages = with pkgs; [
      hfd-service
      lomiri-download-manager
      repowerd
    ];
    services.dbus.packages = with pkgs; [
      hfd-service
      lomiri-download-manager
      repowerd
    ];

    fonts.fonts = with pkgs; [
      # Applications tend to default to Ubuntu font
      ubuntu_font_family
    ];

    # Copy-pasted
    # TODO are all of these needed? just nice-have's? convenience?
    hardware.opengl.enable = lib.mkDefault true;
    fonts.enableDefaultFonts = lib.mkDefault true;
    programs.dconf.enable = lib.mkDefault true;
    programs.xwayland.enable = lib.mkDefault true;

    services.accounts-daemon.enable = true;
    services.udisks2.enable = true;
    services.upower.enable = true;
    services.xserver.displayManager.defaultSession = lib.mkDefault "lomiri";
    services.xserver.displayManager.sessionPackages = with pkgs; [ lomiri-session ];
    services.xserver.updateDbusEnvironment = true;

    environment.pathsToLink = [
      # Required for installed Ayatana indicators to show up in Lomiri
      "/share/ayatana"
      # Registers how to open dispatched URIs
      "/share/lomiri-url-dispatcher/urls"
      # ?
      "/share/content-hub/peers"
      # Try to get maliit stuff working
      "/share/maliit/plugins"
    ];

    # TODO is this really the way to do this, can't we reuse upstream's files?
    # Shadows ayatana-indicators.target from libayatana-common, brings up desired indicator services
    systemd.user.targets."ayatana-indicators" = {
      description = "Target representing the lifecycle of the Ayatana Indicators. Each indicator should be bound to it in its individual service file.";
      partOf = [ "graphical-session.target" ];
      wants = lib.lists.forEach indicator-services (indicator: "${indicator.pname}.service");
      before = lib.lists.forEach indicator-services (indicator: "${indicator.pname}.service");
    };
  };

  meta.maintainers = with lib.maintainers; [ OPNA2608 ];
}
