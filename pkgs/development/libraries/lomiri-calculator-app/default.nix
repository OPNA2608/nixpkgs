# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, gettext
, lomiri-ui-toolkit
, pkg-config
, qqc2-suru-style
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-calculator-app";
  version = "4.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/${pname}";
    rev = "v${version}";
    hash = "sha256-9MIjpoychIOs3elFmq/TKuPYOGxX++Xg1DdwjtlMgZU=";
  };

  postPatch = ''
    # First one is embedded into files so must be absolute, second one tries to make first one absolute
    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_DATADIR}/\''${APP_HARDCODE}" "\''${CMAKE_INSTALL_FULL_DATADIR}/\''${APP_HARDCODE}" \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${LOMIRI-CALCULATOR-APP_DIR}" "\''${LOMIRI-CALCULATOR-APP_DIR}"
    substituteInPlace app/lomiri-calculator-app.in \
      --replace 'qmlscene' '${qtdeclarative.dev}/bin/qmlscene' \
      --replace '@CMAKE_INSTALL_PREFIX@/@LOMIRI-CALCULATOR-APP_DIR@' '@LOMIRI-CALCULATOR-APP_DIR@'
  '' + lib.optionalString (!doCheck) ''
    sed -i \
      -e '/add_subdirectory(tests)/d' \
      CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase

    # QML
    lomiri-ui-toolkit
    qqc2-suru-style
    qtdeclarative
  ];

  cmakeFlags = [
    "-DCLICK_MODE=OFF"
    "-DINSTALL_TESTS=OFF"
  ];

  # TODO
  doCheck = false;

  postFixup = ''
    # Why doesn't this happen automatically?
    wrapQtApp $out/bin/lomiri-calculator-app
  '';
}
