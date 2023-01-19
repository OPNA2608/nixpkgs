{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, qtbase
, qtdeclarative
, glib
, geonames
, lomiri-click
, gettext
, intltool
, libqtdbustest
, libqtdbusmock
, accountsservice_0_6_42
, gsettings-qt
, gnome-desktop
, gtk3
, upower
, icu
, cmake-extras
, xvfb-run
}:

stdenv.mkDerivation rec {
  pname = "lomiri-system-settings";
  version = "unstable-2023-01-17";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-system-settings";
    rev = "47bd8f9e87cb61d7d2424ad0f5784a7bb33e5bc9";
    hash = "sha256-IyQWBsgG3nVVrCSGw/MtAJ+7YkiHHwu32ZoCR1MmYFw=";
  };

  postPatch = ''
    substituteInPlace  lib/LomiriSystemSettings/LomiriSystemSettings.pc.in \
      --replace "\''${prefix}/@LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    gettext
    intltool
  ];

  buildInputs = [
    accountsservice_0_6_42
    cmake-extras
    glib
    geonames
    gnome-desktop
    gtk3
    gsettings-qt
    icu
    libqtdbustest
    libqtdbusmock
    lomiri-click
    qtbase
    qtdeclarative
    upower
  ];

  nativeCheckInputs = [
    xvfb-run
  ];

  dontWrapQtApps = true;
}
