{ stdenv
, lib
, fetchFromGitLab
, ayatana-indicator-messages
, cmake
, dbus
, dbus-glib
, dbus-test-runner
, dconf
, gettext
, glib
, gnome
, history-service
, libnotify
, libphonenumber
, libpulseaudio
, libusermetrics
, lomiri-ui-toolkit
, lomiri-url-dispatcher
, makeWrapper
, pkg-config
, protobuf
, python3
, qtbase
, qtdeclarative
, qtfeedback
, qtmultimedia
, qtpim
, telepathy
, telepathy-glib
, telepathy-mission-control
, xvfb-run
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

  postPatch = let
    dbusPrefix = "share/dbus-1/services";
  in ''
    # Queries qmake for the QML installation path, which returns a reference to Qt5's build directory
    # Same fix like in history-service, but someone un-negated the cross condition in this project
    substituteInPlace CMakeLists.txt \
      --replace 'if(CMAKE_CROSSCOMPILING)' 'if(NOT CMAKE_CROSSCOMPILING)' \
      --replace "\''${QMAKE_EXECUTABLE} -query QT_INSTALL_QML" "echo $out/${qtbase.qtQmlPrefix}"

    # Bad path concatenation
    substituteInPlace config.h.in handler/{com.lomiri.TelephonyServiceHandler,org.freedesktop.Telepathy.Client.TelephonyService*}.service.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

    # Tests generate a required NotificationsInterface.h, but in a directory where it doesn't match the used #include line?
    sed -i \
      -e '/''${CMAKE_SOURCE_DIR}\/indicator/a ''${CMAKE_CURRENT_BINARY_DIR}/..' \
      tests/indicator/CMakeLists.txt

  '' + (if doCheck then ''
    substituteInPlace tests/common/dbus-services/CMakeLists.txt \
      --replace "\''${DBUS_SERVICES_DIR}/org.freedesktop.Telepathy.MissionControl5.service" "${telepathy-mission-control}/${dbusPrefix}/org.freedesktop.Telepathy.MissionControl5.service" \
      --replace "\''${DBUS_SERVICES_DIR}/org.freedesktop.Telepathy.AccountManager.service" "${telepathy-mission-control}/${dbusPrefix}/org.freedesktop.Telepathy.AccountManager.service" \
      --replace "\''${DBUS_SERVICES_DIR}/ca.desrt.dconf.service" "${dconf}/${dbusPrefix}/ca.desrt.dconf.service"

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
    makeWrapper
  ];

  buildInputs = [
    ayatana-indicator-messages
    dbus-glib
    dbus
    dconf
    gettext
    glib
    history-service
    libnotify
    libphonenumber
    libpulseaudio
    libusermetrics
    lomiri-url-dispatcher
    protobuf
    (python3.withPackages (ps: with ps; [
      dbus-python
      pygobject3
    ]))
    qtbase
    qtdeclarative
    qtfeedback
    qtmultimedia
    qtpim
    telepathy
    telepathy-glib
    telepathy-mission-control
  ];

  nativeCheckInputs = [
    dbus-test-runner
    dconf
    gnome.gnome-keyring
    telepathy-mission-control
    xvfb-run
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    # These rely on libphonenumber reformatting inputs to certain results
    # Seem to be broken for a small amount of numbers, maybe libphonenumber version change?
    "-DSKIP_QML_TESTS=ON"
  ];

  # Somewhere in this, some include paths aren't being identified/passed properly
  env.NIX_CFLAGS_COMPILE = toString ([
    "-I${lib.getDev telepathy-glib}/include/telepathy-1.0"
    "-I${lib.getDev dbus-glib}/include/dbus-1.0"
    "-I${lib.getDev dbus}/include/dbus-1.0"
  ] ++ lib.optionals doCheck [
    "-I${lib.getDev qtbase}/include/QtDBus"
  ]);

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  # Starts & talks to D-Bus services, breaks with parallelism
  enableParallelChecking = false;

  preCheck = ''
    export QT_QPA_PLATFORM=minimal
    export QT_PLUGIN_PATH=${lib.strings.concatMapStringsSep ":" (drv: "${lib.getBin drv}/${qtbase.qtPluginPrefix}") [ qtbase qtpim ]}
  '';

  postInstall = ''
    patchShebangs $out/bin/phone-gsettings-migration.py
    substituteInPlace $out/bin/ofono-setup \
      --replace '/usr/bin/phone-gsettings-migration.py' "$out/bin/phone-gsettings-migration.py"

    # Still missing getprop from libhybris
    wrapProgram $out/bin/ofono-setup \
      --prefix PATH : ${lib.makeBinPath [ dbus dconf gettext glib telepathy-mission-control ]}
  '';

  meta = with lib; {
    description = "Backend dispatcher service for various mobile phone related operations";
    homepage = "https://gitlab.com/ubports/development/core/telephony-service";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
