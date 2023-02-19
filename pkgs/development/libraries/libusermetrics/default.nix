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
, libapparmor
, libqtdbustest
, pkg-config
, qdjango
, qtbase
, qtdeclarative
, qtxmlpatterns
}:

stdenv.mkDerivation rec {
  pname = "libusermetrics";
  version = "1.2.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-A7N6XkByCzuJAFO7O7ix8pUg+GAXpIXaumTLdZdds/w=";
  };

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace '/etc' "$out/etc"
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
  ];

  buildInputs = [
    cmake-extras
    gsettings-qt
    libapparmor
    qdjango
    qtxmlpatterns
  ];

  nativeCheckInputs = [
    dbus
  ];

  checkInputs = [
    gtest
    libqtdbustest
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

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
