{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, dbus
, doxygen
, gsettings-qt
, gtest
, intltool
, json-glib
, libapparmor
, libqtdbustest
, ubports-click
, pkg-config
, qdjango
, qtbase
, qtdeclarative
, qtxmlpatterns
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "libusermetrics";
  version = "1.3.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-yO9wZcXJBKt1HZ1GKoQ1flqYuwW9PlXiWLE3bl21PSQ=";
  };

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace '/etc' "$out/etc"

    # Tries to query QMake for QT_INSTALL_QML variable, would return broken paths into /build/qtbase-<commit> even if qmake was available
    substituteInPlace src/modules/UserMetrics/CMakeLists.txt \
      --replace "\''${QT_IMPORTS_DIR}/UserMetrics" '${placeholder "out"}/${qtbase.qtQmlPrefix}/UserMetrics'
  '' + lib.optionalString (!doCheck) ''
    # Only needed by tests
    sed -i -e '/QTDBUSTEST/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    doxygen
    intltool
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    cmake-extras
    gsettings-qt
    json-glib
    libapparmor
    ubports-click
    qdjango
    qtxmlpatterns

    # Plugin
    qtbase
  ];

  nativeCheckInputs = [
    dbus
  ];

  checkInputs = [
    gtest
    libqtdbustest
    qtdeclarative
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  # click -> json-glib -> include path not propagated?
  NIX_CFLAGS_COMPILE = "-I${lib.getDev json-glib}/include/json-glib-1.0";

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  checkPhase = ''
    runHook preCheck

    export QT_PLUGIN_PATH=${lib.getBin qtbase}/lib/qt-${qtbase.version}/plugins/
    export QML2_IMPORT_PATH=${lib.getBin qtdeclarative}/lib/qt-${qtbase.version}/qml/
    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- make test

    runHook postCheck
  '';

  meta = with lib; {
    description = "Enables apps to locally store interesting numerical data for later presentation";
    homepage = "https://gitlab.com/ubports/development/core/libusermetrics";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ OPNA2608 ];
    mainProgram = "usermetricsinput";
  };
}
