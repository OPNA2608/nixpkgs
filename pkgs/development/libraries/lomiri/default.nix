{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, wrapQtAppsHook
, qtbase
, qtdeclarative
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
, mir_1
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
}:

stdenv.mkDerivation rec {
  pname = "lomiri";
  version = "unstable-2022-01-17";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri";
    rev = "8291f2d2ca73e2cfed5a5c31a2019aa30541e698";
    hash = "sha256-MbC7kzQxni03dKIyg/V8sFsJujx8cP5lFsFQ4Se2SC8=";
  };

  postPatch = ''
    # This just doesn't seem to work?
    substituteInPlace tests/uqmlscene/CMakeLists.txt \
      --replace 'set_target_properties(uqmlscene PROPERTIES INCLUDE_DIRECTORIES ''${XCB_INCLUDE_DIRS})' 'target_include_directories(uqmlscene PRIVATE ''${XCB_INCLUDE_DIRS})'

    substituteInPlace data/systemd-user/CMakeLists.txt \
      --replace "\''${SYSTEMD_USERUNITDIR}" "$out/lib/systemd/user"

    substituteInPlace include/paths.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'
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
    libqtdbustest
    libqtdbusmock
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
    mir_1
    properties-cpp
    protobuf
    qmenumodel
    qtbase
    qtdeclarative
    qtgraphicaleffects
    qtmir
    qtsvg
  ];

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';
}
