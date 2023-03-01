# TODO
# - tests
# - meta
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
  version = "1.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-system-settings";
    rev = version;
    hash = "sha256-7XJ2mvqcI+tBEpT6tAVJrcEzyDhiY1ttB1X1e24kmd8=";
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
    accountsservice_0_6_42 # https://gitlab.com/ubports/development/core/lomiri-system-settings/-/issues/341
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
