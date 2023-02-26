{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, pkg-config
, wrapQtAppsHook
, qtbase
, qtdeclarative
, qtfeedback
, qtmir
, qtsvg
, lomiri-api
, geonames
, glib
, gnome-desktop
, gtk3
, qmenumodel
, lomiri-app-launch
, lomiri-download-manager
, lomiri-indicator-network
, lomiri-ui-toolkit
, lomiri-settings-components
, lomiri-system-settings
, lomiri-schemas
, lomiri-notifications
, lomiri-thumbnailer
, telephony-service
, biometryd
, hfd-service
, mir
, deviceinfo
, libqtdbustest
, libqtdbusmock
, gsettings-qt
, cmake-extras
, libuuid
, protobuf
, dbus-test-runner
, libusermetrics
, lightdm_qt
, libevdev
, pam
, properties-cpp
, glm
, boost
, wrapGAppsHook
, qtgraphicaleffects
, qtmultimedia
, nixos-artwork
}:

stdenv.mkDerivation rec {
  pname = "lomiri";
  version = "0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri";
    rev = version;
    hash = "sha256-wi/UBNgefHFG8l2k3dVn9coHNV7fT5xqMx4DPRyvhWw=";
  };

  patches = [
    # Convert to miroil for Mir 2.x support
    # Remove when https://gitlab.com/ubports/development/core/lomiri/-/merge_requests/72 merged & in release
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/lomiri/-/commit/f5832bde33149b51e6b47034dad7ecbb4345f47f.patch";
      hash = "sha256-JBi0FzZgLNzT7qXZokA4q6w8vwdndPrqV+bws6uKWr8=";
    })
  ];

  postPatch = ''
    # This just doesn't seem to work?
    substituteInPlace tests/uqmlscene/CMakeLists.txt \
      --replace 'set_target_properties(uqmlscene PROPERTIES INCLUDE_DIRECTORIES ''${XCB_INCLUDE_DIRS})' 'target_include_directories(uqmlscene PRIVATE ''${XCB_INCLUDE_DIRS})'

    # Wrong prefix
    substituteInPlace data/systemd-user/CMakeLists.txt \
      --replace "\''${SYSTEMD_USERUNITDIR}" "$out/lib/systemd/user"

    # Bad path concatenation
    substituteInPlace include/paths.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

    # Replace default
    # TODO there's prolly a better way of doing this than to hold this entire wallpaper hostage like this, try looking at other desktops?
    substituteInPlace plugins/Utils/constants.cpp \
      --replace '/usr/share/backgrounds/warty-final-ubuntu.png' '${nixos-artwork.wallpapers.simple-red.passthru.gnomeFilePath}'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    glib # populates GSETTINGS_SCHEMAS_PATH
    pkg-config
    wrapGAppsHook # sets XDG_DATA_DIRS to found schemas
    wrapQtAppsHook

    # QML import path
    lomiri-ui-toolkit
    lomiri-settings-components
    lomiri-system-settings
    qtgraphicaleffects
    gsettings-qt
    lomiri-notifications
    telephony-service
    biometryd
    qmenumodel
    lomiri-thumbnailer
    hfd-service
    qtmultimedia
    qtfeedback

    # Qt plugin path
    qtmir
  ];

  buildInputs = [
    boost
    cmake-extras
    dbus-test-runner
    deviceinfo
    geonames
    glib
    glm
    gnome-desktop
    gsettings-qt
    gtk3
    libevdev
    libusermetrics
    libuuid
    lightdm_qt
    pam
    lomiri-api
    lomiri-app-launch
    lomiri-download-manager
    lomiri-indicator-network
    lomiri-schemas
    lomiri-system-settings
    lomiri-ui-toolkit
    mir
    nixos-artwork.wallpapers.simple-red
    properties-cpp
    protobuf
    qmenumodel
    qtbase
    qtdeclarative
    qtgraphicaleffects
    qtmir
    qtsvg
  ];

  checkInputs = [
    libqtdbustest
    libqtdbusmock
  ];

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  cmakeFlags = [
    "-DNO_TESTS=${lib.boolToString (!doCheck)}"
  ];

  # Tests not ported to Mir 2.x yet
  doCheck = false;
}
