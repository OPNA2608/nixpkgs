{ lib
, pkgs
, libsForQt5
, python3Packages
, fetchFromGitLab
}:

lib.makeScope libsForQt5.newScope (self: with self; {
  maintainers = lib.teams.lomiri.members;

  ### HELPER
  fetchFromUbports =
    { group ? "core"
    , pname
    , rev
    , hash
    }:

    fetchFromGitLab {
      owner = "ubports";
      repo = "development/${group}/${pname}";
      inherit rev hash;
    };

  ### TO BE SORTED
  # accounts-qml-module
  # buteo-syncfw
  # buteo-syncfw-qml
  # dbus-test-runner
  # dsme
  # libcal
  # libdsme
  # libiphb
  # libmce-qt
  # libngf
  # lomiri-keyboard
  # lomiri-settings-components
  # mce
  # mce-dev
  # qdjango
  # qmenumodel
  # qqc2-suru-style
  # qzxing
  # u1db-qt
  # usb_moded
  # xsct

  ### DATA
  # lomiri-schemas
  # lomiri-sounds
  # lomiri-wallpapers #TODO

  ### TOOLS
  click = python3Packages.callPackage ./tools/click {
    inherit fetchFromUbports;
  };
  cmake-extras = callPackage ./tools/cmake-extras { };

  ### TESTING
  gmenuharness = callPackage ./libraries/gmenuharness { };

  ### LIBRARIES
  deviceinfo = callPackage ./libraries/deviceinfo { };
  geonames = callPackage ./libraries/geonames { };
  libusermetrics = callPackage ./libraries/libusermetrics { };
  # qtmir

  ### LIBRARIES / LIB-CPP
  dbus-cpp = callPackage ./libraries/lib-cpp/dbus-cpp { };
  net-cpp = callPackage ./libraries/lib-cpp/net-cpp { };
  persistent-cache-cpp = callPackage ./libraries/lib-cpp/persistent-cache-cpp { };
  # process-cpp
  # properties-cpp

  ### CORE
  # lomiri
  # lomiri-action-api
  lomiri-api = callPackage ./core/lomiri-api { };
  lomiri-app-launch = callPackage ./core/lomiri-app-launch { };
  # lomiri-session
  # lomiri-ui-extras
  # lomiri-ui-toolkit
  # lomiri-url-dispatcher

  ### AYATANA-INDICATORS
  # ayatana-indicator-messages
  # ayatana-indicator-display
  # ayatana-indicator-session
  # ayatana-indicator-datetime
  # ayatana-indicator-power
  # ayatana-indicator-notifications # implemented by lomiri-notifications
  # ayatana-indicator-bluetooth # implemented by another indicator?
  # ayatana-indicator-keyboard
  # ayatana-indicator-printers
  # ayatana-indicator-application
  # ayatana-indicator-sound
  # libayatana-common
  # lomiri-notifications
  # lomiri-indicator-network

  ### SERVICES
  # biometryd
  # content-hub
  # hfd-service
  # history-service
  # location-service
  # lomiri-download-manager
  # lomiri-thumbnailer
  # mediascanner2
  # repowerd
  # sync-monitor
  # telephony-service
  # trust-store

  ### APPS
  # address-book-app
  # dialer-app
  # lomiri-calculator-app
  # lomiri-camera-app
  # lomiri-clock-app
  # lomiri-gallery-app
  # lomiri-filemanager-app
  # lomiri-music-app
  lomiri-system-settings-unwrapped = callPackage ./apps/lomiri-system-settings { };
  #   lomiri-system-settings-online-accounts
  #   lomiri-system-settings-security-privacy
  # lomiri-terminal-app
  # mediaplayer-app
  # messaging-app
  # morph-browser
})
