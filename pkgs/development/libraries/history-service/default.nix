{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, dbus
, dbus-test-runner
, dconf
, gnome
, libphonenumber
, libqtdbustest
, lomiri-api
, pkg-config
, protobuf
, qtbase
, qtdeclarative
, qtpim
, telepathy
, telepathy-mission-control
, xvfb-run
}:

stdenv.mkDerivation rec {
  pname = "history-service";
  version = "0.4";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-oCX+moGQewzstbpddEYYp1kQdO2mVXpWJITfvzDzQDI=";
  };

  patches = [
    # Deprecation warnings with Qt5.15, allow disabling -Werror
    # Remove when version > 0.4
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/history-service/-/commit/1370777952c6a2efb85f582ff8ba085c2c0e290a.patch";
      hash = "sha256-Z/dFrFo7WoPZlKto6wNGeWdopsi8iBjmd5ycbqMKgxo=";
    })
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    export VERBOSE=1

    # Uses pkg_get_variable, cannot substitute prefix with that
    substituteInPlace daemon/CMakeLists.txt \
      --replace 'DESTINATION ''${SYSTEMD_USER_UNIT_DIR}' 'DESTINATION "${placeholder "out"}/lib/systemd/user"'

    # Queries qmake for the QML installation path, which returns a reference to Qt5's build directory
    substituteInPlace CMakeLists.txt \
      --replace "\''${QMAKE_EXECUTABLE} -query QT_INSTALL_QML" "echo $out/lib/qt-${qtbase.version}/qml"

  '' + (if doCheck then ''
    substituteInPlace tests/common/dbus-services/CMakeLists.txt \
      --replace "\''${DBUS_SERVICES_DIR}/org.freedesktop.Telepathy.MissionControl5.service" "${telepathy-mission-control}/share/dbus-1/services/org.freedesktop.Telepathy.MissionControl5.service" \
      --replace "\''${DBUS_SERVICES_DIR}/org.freedesktop.Telepathy.AccountManager.service" "${telepathy-mission-control}/share/dbus-1/services/org.freedesktop.Telepathy.AccountManager.service" \
      --replace "\''${DBUS_SERVICES_DIR}/ca.desrt.dconf.service" "${dconf}/share/dbus-1/services/ca.desrt.dconf.service"

    substituteInPlace cmake/modules/GenerateTest.cmake \
      --replace '/usr/lib/dconf' '${lib.getLib dconf}/libexec' \
      --replace '/usr/lib/telepathy' '${lib.getLib telepathy-mission-control}/libexec'
  '' else ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '');

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    libphonenumber
    protobuf
    qtbase
    qtdeclarative
    qtpim
    telepathy
  ];

  nativeCheckInputs = [
    dbus
    dbus-test-runner
    dconf
    gnome.gnome-keyring
    telepathy-mission-control
    xvfb-run
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    # Many deprecation warnings with Qt5.15
    "-DENABLE_WERROR=OFF"
  ];

  # 50% of tests still fail
  # doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  doCheck = false;

  # Multiple tests try to access the same sqlite db
  enableParallelChecking = false;

  checkPhase = ''
    runHook preCheck

    export QT_PLUGIN_PATH=${lib.getBin qtbase}/lib/qt-${qtbase.version}/plugins
    export HOME=$PWD
    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- make test

    runHook postCheck
  '';

  meta = with lib; {
    description = "Service that provides call log and conversation history";
    longDescription = ''
      History service provides the database and an API to store/retrieve the call log (used by dialer-app) and the sms/mms history (used by messaging-app).

      See as well telepathy-ofono for incoming message events.

      Database location: ~.local/share/history-service/history.sqlite
    '';
    homepage = "https://gitlab.com/ubports/development/core/history-service";
    license = licenses.;
    platforms = platforms.;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
