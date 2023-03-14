# TODO
# - meta
# - tests
{ stdenv
, lib
, fetchFromGitLab
, cmake
, gsettings-qt
, lomiri-ui-extras
, lomiri-ui-toolkit
, pkg-config
, qmltermwidget
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, qtsystems
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-terminal-app";
  version = "2.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/lomiri-terminal-app";
    rev = "v${version}";
    hash = "sha256-WYPP4sZisZMJmRs+QtILh1TELqrJxE+RarkXI58GIKc=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" '${qtbase.qtQmlPrefix}' \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${DATA_DIR}" "\''${CMAKE_INSTALL_FULL_DATADIR}/lomiri-terminal-app" \
      --replace 'EXEC "''${APP_NAME}"' 'EXEC "${placeholder "out"}/bin/''${APP_NAME}"'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtdeclarative
    qmltermwidget

    # QML
    gsettings-qt
    lomiri-ui-extras
    lomiri-ui-toolkit
    qtfeedback
    qtgraphicaleffects
    qtsystems
  ];

  cmakeFlags = [
    "-DINSTALL_TESTS=OFF"
    "-DCLICK_MODE=OFF"
  ];

  # TODO
  doCheck = false;
}
