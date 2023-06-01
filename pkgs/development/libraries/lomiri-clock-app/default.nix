# TODO
# - WARNING: alarm manager "eds" not installed, using "memory"
#   WARNING: Creating dedicated collection for alarms was not possible, alarms will be saved into the default collection!
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, geonames
, gettext
, libusermetrics
, lomiri-sounds
, lomiri-ui-toolkit
, makeWrapper
, pkg-config
, qtbase
, qtdeclarative
, qtmultimedia
, qtpositioning
, qtsystems
, runtimeShell
, u1db-qt
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-clock-app";
  version = "4.0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/${pname}";
    rev = "v${version}";
    hash = "sha256-GxptJzSIA6pTu6Ml+sTY5ctdns2GuBTBfNh837X/xz0=";
  };

  postPatch = ''
    # First one is embedded into files so must be absolute, second one tries to make first one absolute
    # QT_IMPORTS_DIR returned by qmake -query is broken
    # Splash broken when not building in click mode
    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_DATADIR}/\''${APP_HARDCODE}" "\''${CMAKE_INSTALL_FULL_DATADIR}/\''${APP_HARDCODE}" \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${LOMIRI-CLOCK_APP_DIR}" "\''${LOMIRI-CLOCK_APP_DIR}" \
      --replace "\''${QT_IMPORTS_DIR}" '${placeholder "out"}/${qtbase.qtQmlPrefix}' \
      --replace 'clock-app-splash.svg' "$out/share/lomiri-clock-app/clock-app-splash.svg" \
      --replace 'qmlscene' '${qtdeclarative.dev}/bin/qmlscene'

    # Broken path?
    substituteInPlace app/components/Information.qml \
      --replace 'Qt.resolvedUrl("../../../clock-app.svg")' '"${placeholder "out"}/share/lomiri-clock-app/clock-app.svg"'

    # Path to default sounds
    # TODO maybe change to /run/current-system/sw instead?
    substituteInPlace app/alarm/AlarmSound.qml backend/modules/Alarm/sound.cpp \
      --replace '/usr' '${lomiri-sounds}'
  '' + lib.optionalString (!doCheck) ''
    sed -i \
      -e '/add_subdirectory(tests)/d' \
      CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    makeWrapper
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    geonames
    qtbase

    # QML
    libusermetrics
    lomiri-ui-toolkit
    qtdeclarative
    qtmultimedia
    qtpositioning
    qtsystems
    u1db-qt
  ];

  dontWrapGApps = true;

  cmakeFlags = [
    "-DCLICK_MODE=OFF"
    "-DINSTALL_TESTS=OFF"
    "-DUSE_XVFB=${lib.boolToString doCheck}"
  ];

  # TODO
  doCheck = false;

  postInstall = ''
    # By default, only installs a desktop file that execs qmlscene with its QML files, but we require Qt wrapping
    mkdir -p $out/bin
    echo "#!${runtimeShell}" > $out/bin/${pname}
    printf 'exec ' >> $out/bin/${pname}
    grep 'Exec=' $out/share/applications/lomiri-clock-app.desktop | cut -d'=' -f2- >> $out/bin/${pname}
    chmod +x $out/bin/${pname}
    sed -i -e 's|^Exec=.*$|Exec=${placeholder "out"}/bin/${pname}|' $out/share/applications/lomiri-clock-app.desktop

    # Doesn't handle splash graphic when not building in click mode
    install -Dm644 {../app,$out/share/lomiri-clock-app}/clock-app-splash.svg

    # Rename dispatcher so our custom binary is found (else it doesn't work, maybe another non-click problem?)
    mv $out/share/lomiri-url-dispatcher/urls/{clock.ubports_clock,${pname}}.url-dispatcher
  '';

  postFixup = ''
    # Why doesn't this happen automatically?
    wrapQtApp $out/bin/lomiri-clock-app
  '';
}
