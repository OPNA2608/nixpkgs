{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, qtdeclarative
, qtbase
, qtpim
, qtmultimedia
, qtfeedback
, libphonenumber
, telepathy
, libnotify
, history-service
, ayatana-indicator-messages
, libusermetrics
, lomiri-url-dispatcher
, protobuf
, telepathy-glib
, dbus-glib
, dbus
, telepathy-mission-control
, dconf
}:

stdenv.mkDerivation rec {
  pname = "telephony-service";
  version = "0.5.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-2hFB+0ySoyCRS0a5hXuiGc1HksLFpbJi65aBQ0ccYpA=";
  };

  postPatch = ''
    # Queries qmake for the QML installation path, which returns a reference to Qt5's build directory
    # Same fix like in history-service, but someone un-negated the cross condition in this project
    substituteInPlace CMakeLists.txt \
      --replace 'if(CMAKE_CROSSCOMPILING)' 'if(NOT CMAKE_CROSSCOMPILING)' \
      --replace "\''${QMAKE_EXECUTABLE} -query QT_INSTALL_QML" "echo $out/lib/qt-${qtbase.version}/qml"

  '' + (if doCheck then ''
    substituteInPlace tests/common/dbus-services/CMakeLists.txt \
      --replace "\''${DBUS_SERVICES_DIR}/org.freedesktop.Telepathy.MissionControl5.service" "${telepathy-mission-control}/share/dbus-1/services/org.freedesktop.Telepathy.MissionControl5.service" \
      --replace "\''${DBUS_SERVICES_DIR}/org.freedesktop.Telepathy.AccountManager.service" "${telepathy-mission-control}/share/dbus-1/services/org.freedesktop.Telepathy.AccountManager.service" \
      --replace "\''${DBUS_SERVICES_DIR}/ca.desrt.dconf.service" "${dconf}/share/dbus-1/services/ca.desrt.dconf.service
  '' else ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '');

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    qtbase
    qtdeclarative
    qtpim
    qtmultimedia
    qtfeedback
    libphonenumber
    telepathy
    libnotify
    history-service
    ayatana-indicator-messages
    libusermetrics
    lomiri-url-dispatcher

    # Missing includedirs
    telepathy-glib
    dbus-glib

    # libphonenumber
    protobuf
  ];

  # Somewhere in this telepathy stuff), an -I into telepathy-glib is missing
  NIX_CFLAGS_COMPILE = "-I${lib.getDev telepathy-glib}/include/telepathy-1.0 -I${lib.getDev dbus-glib}/include/dbus-1.0 -I${lib.getDev dbus}/include/dbus-1.0";

  dontWrapQtApps = true;

  # TODO
  doCheck = false;
}
