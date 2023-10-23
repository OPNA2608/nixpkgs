{ stdenv
, lib
, fetchFromGitLab
, gitUpdater
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

let
  replaceDbusService = pkg: name: "--replace \"\\\${DBUS_SERVICES_DIR}/${name}\" \"${pkg}/share/dbus-1/services/${name}\"";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "telephony-service";
  version = "0.5.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/telephony-service";
    rev = finalAttrs.version;
    hash = "sha256-2hFB+0ySoyCRS0a5hXuiGc1HksLFpbJi65aBQ0ccYpA=";
  };

  postPatch = ''
    # libphonenumber -> protobuf -> abseil-cpp demands C++14
    # But uses std::string_view which is C++17?
    substituteInPlace CMakeLists.txt \
      --replace '-std=c++11' '-std=c++17'

    # Queries qmake for the QML installation path, which returns a reference to Qt5's build directory
    # Cross-conditional code should
    substituteInPlace CMakeLists.txt \
      --replace 'if(CMAKE_CROSSCOMPILING)' 'if(NOT CMAKE_CROSSCOMPILING)' \
      --replace "\''${QMAKE_EXECUTABLE} -query QT_INSTALL_QML" "echo $out/${qtbase.qtQmlPrefix}"

    # Bad path concatenation
    substituteInPlace config.h.in {approver,handler,indicator}/*.service.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

    # Tests generate a required NotificationsInterface.h, but in a directory where it doesn't match the used #include line?
    sed -i tests/indicator/CMakeLists.txt \
      -e '/''${CMAKE_SOURCE_DIR}\/indicator/a ''${CMAKE_CURRENT_BINARY_DIR}/..'

    # ProtocolTest uses QtDBus
    substituteInPlace tests/libtelephonyservice/CMakeLists.txt \
      --replace 'LIBRARIES Qt5::Core Qt5::Test' 'LIBRARIES Qt5::Core Qt5::Test Qt5::DBus'

  '' + (if finalAttrs.doCheck then ''
    substituteInPlace tests/common/dbus-services/CMakeLists.txt \
      ${replaceDbusService telepathy-mission-control "org.freedesktop.Telepathy.MissionControl5.service"} \
      ${replaceDbusService telepathy-mission-control "org.freedesktop.Telepathy.AccountManager.service"} \
      ${replaceDbusService dconf "ca.desrt.dconf.service"}

    substituteInPlace cmake/modules/GenerateTest.cmake \
      --replace '/usr/lib/dconf' '${lib.getLib dconf}/libexec' \
      --replace '/usr/lib/telepathy' '${lib.getLib telepathy-mission-control}/libexec'
  '' else ''
    sed -i CMakeLists.txt -e '/add_subdirectory(tests)/d'
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

  env.NIX_CFLAGS_COMPILE = toString ([
    "-I${lib.getDev telepathy-glib}/include/telepathy-1.0" # it's in telepathy-farstream's Requires.private, so it & its dependencies don't get pulled in
    "-I${lib.getDev dbus-glib}/include/dbus-1.0" # telepathy-glib dependency
    "-I${lib.getDev dbus}/include/dbus-1.0" # telepathy-glib dependency
  ]);

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  # Starts & talks to D-Bus services, breaks with parallelism
  enableParallelChecking = false;

  preCheck = ''
    export QT_QPA_PLATFORM=minimal
    export QT_PLUGIN_PATH=${lib.makeSearchPathOutput "bin" qtbase.qtPluginPrefix [ qtbase qtpim ]}
  '';

  postInstall = ''
    patchShebangs $out/bin/phone-gsettings-migration.py
    substituteInPlace $out/bin/ofono-setup \
      --replace '/usr/bin/phone-gsettings-migration.py' "$out/bin/phone-gsettings-migration.py"

    # Still missing getprop from libhybris, we don't support it (for now?)
    wrapProgram $out/bin/ofono-setup \
      --prefix PATH : ${lib.makeBinPath [ dbus dconf gettext glib telepathy-mission-control ]}

    # These SystemD services are referenced by the installed D-Bus services, but not part of the installation. Why?
    for service in telephony-service-{approver,indicator}; do
      install -Dm644 ../debian/telephony-service."$service".user.service $out/lib/systemd/user/"$service".service
      substituteInPlace $out/lib/systemd/user/"$service".service \
         --replace '/usr' "$out"

      # Not sure what provides this
      sed -i $out/lib/systemd/user/"$service".service \
        -e '/ofono-setup.service/d'
    done
  '';

  passthru.updateScript = gitUpdater { };

  meta = with lib; {
    description = "Backend dispatcher service for various mobile phone related operations";
    homepage = "https://gitlab.com/ubports/development/core/telephony-service";
    license = licenses.gpl3Only;
    maintainers = teams.lomiri.members;
    platforms = platforms.linux;
  };
})
