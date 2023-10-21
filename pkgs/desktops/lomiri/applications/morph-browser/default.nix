{ stdenv
, lib
, fetchFromGitLab
, gitUpdater
, cmake
, content-hub
, gettext
, libapparmor
, lomiri-action-api
, lomiri-ui-extras
, lomiri-ui-toolkit
, pkg-config
, python3
, qtbase
, qtdeclarative
, qtquickcontrols2
, qtsystems
, qtwebengine
, wrapQtAppsHook
, xvfb-run
}:

let
  listToQtVar = suffix: lib.makeSearchPathOutput "bin" suffix;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "morph-browser";
  version = "1.0.3";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/morph-browser";
    rev = finalAttrs.version;
    hash = "sha256-gzrNIIRTnIiL5T1HYy2x9mGawZwW6vhCt3b5k3NhpKI=";
  };

  postPatch = ''
    substituteInPlace src/{Morph,Ubuntu}/CMakeLists.txt \
      --replace '/usr/lib/''${CMAKE_LIBRARY_ARCHITECTURE}/qt5/qml' '${qtbase.qtQmlPrefix}'

    # One tests uses this path for XDG_RUNTIME_DIR, needs proper permissions to be accepted by qtbase
    sed -i tests/unittests/session-utils/tst_SessionUtilsTests.cpp \
      -e '/xdgRuntimeDir.mkpath/a QFile::setPermissions(xdgRuntimeDir.absolutePath().toUtf8(), QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);'

    # QML tests run into deadly ShapeMaterial path in LUITK that requires OpenGL
    sed -i tests/unittests/CMakeLists.txt \
      -e '/add_subdirectory(qml)/d'
  '' + lib.optionalString (!finalAttrs.doCheck) ''
    sed -i CMakeLists.txt \
      -e '/add_subdirectory(tests)/d'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    libapparmor
    qtbase
    qtdeclarative
    qtwebengine

    # QML
    content-hub
    lomiri-action-api
    lomiri-ui-extras
    lomiri-ui-toolkit
    qtquickcontrols2
    qtsystems
  ];

  nativeCheckInputs = [
    (python3.withPackages (ps: with ps; [
      flake8
    ]))
    xvfb-run
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  preCheck = ''
    export HOME=$TMPDIR
    export QT_PLUGIN_PATH=${listToQtVar qtbase.qtPluginPrefix [ qtbase ]}
    export QML2_IMPORT_PATH=${listToQtVar qtbase.qtQmlPrefix ([ lomiri-ui-toolkit qtwebengine qtdeclarative qtquickcontrols2 qtsystems ] ++ lomiri-ui-toolkit.propagatedBuildInputs)}
  '';

  passthru.updateScript = gitUpdater { };

  meta = with lib; {
    description = "Lightweight web browser tailored for Ubuntu Touch";
    homepage = "https://gitlab.com/ubports/development/core/morph-browser";
    license = with licenses; [ gpl3Only cc-by-sa-30 ];
    mainProgram = "morph-browser";
    maintainers = teams.lomiri.members;
    platforms = platforms.linux;
  };
})
