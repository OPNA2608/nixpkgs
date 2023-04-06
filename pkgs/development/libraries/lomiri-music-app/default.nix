{ stdenv
, lib
, fetchFromGitLab
, cmake
, gettext
, libusermetrics
, lomiri-thumbnailer
, lomiri-ui-toolkit
, mediascanner2
, pkg-config
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, qtmultimedia
, qtsystems
, runtimeShell
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-music-app";
  version = "3.0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/${pname}";
    rev = "v${version}";
    hash = "sha256-zeI15Q1ppZ186U3TRWLv/k2hBY8RVqEr90SW072Qa/U=";
  };

  postPatch = ''
    # First one is embedded into files so must be absolute, second one tries to make first one absolute
    # Wrong (old?) content-hub name
    # lomiri-url-dispatcher name broken in non-click mode
    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_DATADIR}/\''${APP_HARDCODE}" "\''${CMAKE_INSTALL_FULL_DATADIR}/\''${APP_HARDCODE}" \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${DATA_DIR}" "\''${DATA_DIR}" \
      --replace 'RENAME music-app' 'RENAME ${pname}' \
      --replace 'DESTINATION ''${URLS_DIR}' 'DESTINATION ''${URLS_DIR} RENAME ${pname}.url-dispatcher'
    substituteInPlace lomiri-music-app.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@DATA_DIR@' '@DATA_DIR@' \
      --replace 'qmlscene' '${qtdeclarative.dev}/bin/qmlscene'
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
    # QML
    libusermetrics
    lomiri-thumbnailer
    lomiri-ui-toolkit
    mediascanner2
    qtdeclarative
    qtfeedback
    qtgraphicaleffects
    qtmultimedia
    qtsystems
  ];

  cmakeFlags = [
    "-DCLICK_MODE=OFF"
    "-DINSTALL_TESTS=OFF"

    # TODO Not set in non-click, report upstream
    "-DSPLASH=${placeholder "out"}/share/${pname}/app/music-app-splash.svg"
  ];

  # TODO
  doCheck = false;

  postInstall = ''
    substituteInPlace $out/bin/${pname} \
      --replace '/bin/bash' '${runtimeShell}'

    # Not installed in non-click mode
    install -Dm644 {../app/graphics,$out/share/${pname}/app}/music-app-splash.svg
  '';

  postFixup = ''
    wrapQtApp $out/bin/lomiri-music-app
  '';
}
