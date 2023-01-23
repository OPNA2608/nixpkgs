{ stdenv
, lib
, fetchFromGitLab
, cmake
, doxygen
, intltool
, pkg-config
, cmake-extras
, gsettings-qt
, gtest
, libapparmor
, libqtdbustest
, qdjango
, qtbase
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
    qtbase
    qtxmlpatterns
  ];

  checkInputs = [
    gtest
    libqtdbustest
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  # Tests rely on system D-Bus, flaky
  doCheck = false;

  preCheck = ''
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/lib/qt-${qtbase.version}/plugins/
  '';

  meta = with lib; {
    description = "Enables apps to locally store interesting numerical data for later presentation";
    homepage = "https://gitlab.com/ubports/development/core/libusermetrics";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
