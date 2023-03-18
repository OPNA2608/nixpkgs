# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, accounts-qt
, cmake
, cmake-extras
, coreutils
, gtest
, libnotify
, lomiri-api
, lomiri-indicator-network
, lomiri-url-dispatcher
, pkg-config
, qtbase
, qtdeclarative
, qtpim
, signond
, systemd
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "sync-monitor";
  version = "unstable-2023-03-04";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "5ade403ee2dd33406ee74489cf2c51291dc11c88";
    hash = "sha256-ziutlPo5OSqnT6NycheAzTllwIo/qoMJzRYWrtIxvoI=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    # Uses pkg_get_variable to get systemduserunitdir, cannot substitute prefix that way
    substituteInPlace systemd/CMakeLists.txt \
      --replace "\''${SYSTEMD_USER_UNIT_DIR}" '"${placeholder "out"}/lib/systemd/user"'

    substituteInPlace Lomiri/SyncMonitor/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" '${placeholder "out"}/${qtbase.qtQmlPrefix}'
    substituteInPlace accounts/desktop/sync-monitor-calendar.desktop.in \
      --replace '/bin/false' '${lib.getBin coreutils}/bin/false'

    # Move binaries from lib to libexec
    substituteInPlace {authenticator,src}/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${CMAKE_INSTALL_LIBDIR}" "\''${CMAKE_INSTALL_FULL_LIBEXECDIR}"
    substituteInPlace src/dbus/com.lomiri.SyncMonitor.service.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_LIBDIR@' '@CMAKE_INSTALL_FULL_LIBEXECDIR@'
    substituteInPlace systemd/sync-monitor.service.in \
      --replace '@CMAKE_INSTALL_FULL_LIBDIR@' '@CMAKE_INSTALL_FULL_LIBEXECDIR@'
  '' + lib.optionalString (!doCheck) ''
    sed -i \
      -e '/find_package(GMock REQUIRED)/d' \
      -e '/add_subdirectory(tests)/d' \
      CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    accounts-qt
    cmake-extras
    libnotify
    lomiri-api # lomiri-indicator-network pkg-config file lacks Requires section for lomiri-api
    lomiri-indicator-network
    lomiri-url-dispatcher
    qtbase
    qtdeclarative
    qtpim
    signond
    systemd
  ];

  checkInputs = [
    gtest
  ];

  # TODO
  doCheck = false;
}
