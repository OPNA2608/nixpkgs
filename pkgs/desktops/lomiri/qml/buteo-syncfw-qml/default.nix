{
  stdenv,
  lib,
  fetchFromGitLab,
  fetchpatch,
  cmake,
  dbus-test-runner,
  gobject-introspection,
  pkg-config,
  python3,
  qtbase,
  qtdeclarative,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "buteo-syncfw-qml";
  version = "0.3";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/buteo-syncfw-qml";
    tag = finalAttrs.version;
    hash = "sha256-CfPQDplKbSU6eXrAntz9IdC3ShynNQmwAeucTpv9N3M=";
  };

  patches = [
    # Remove when version > 0.3
    (fetchpatch {
      name = "0001-buteo-syncfw-qml-Remove-not-used-anywhere-method-declaration.patch";
      url = "https://gitlab.com/ubports/development/core/buteo-syncfw-qml/-/commit/e61fe12188abf0cc58ce3cd11370536f7dcd3a29.patch";
      hash = "sha256-7EAEkrCy5Bd5HkC43LZbWdaD7DDpgznH3o+hi1ZhKU8=";
    })

    # Remove when https://gitlab.com/ubports/development/core/buteo-syncfw-qml/-/merge_requests/5 merged & in release
    ./1001-tst_ButeoSyncFW-Await-component-being-initialised.patch
  ];

  postPatch =
    ''
      substituteInPlace Buteo/CMakeLists.txt \
        --replace-fail 'qmake -query QT_INSTALL_QML' 'echo ''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}'

      substituteInPlace tests/qml/CMakeLists.txt \
        --replace-fail 'NO_DEFAULT_PATH' ""
    ''
    + (if finalAttrs.finalPackage.doCheck then ''
      patchShebangs tests/qml/buteo-syncfw.py
    '' else ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'add_subdirectory(tests)' '# add_subdirectory(tests)'
    '');

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    qtbase
    qtdeclarative
  ];

  nativeCheckInputs = [
    dbus-test-runner
    gobject-introspection
    (python3.withPackages (ps: with ps; [
      dbus-python
      pygobject3
    ]))
    qtdeclarative # qmltestrunner
  ];

  dontWrapQtApps = true;

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  # Spins up D-Bus
  enableParallelChecking = false;

  preCheck = ''
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}
  '';

  meta = {
    description = "Buteo sync framework client - QML bindings";
    homepage = "https://gitlab.com/ubports/development/core/buteo-syncfw-qml";
    changelog = "https://gitlab.com/ubports/development/core/buteo-syncfw-qml/-/blob/${finalAttrs.version}/ChangeLog";
    license = lib.licenses.gpl3Only;
    maintainers = lib.teams.lomiri.members;
    platforms = lib.platforms.linux;
  };
})
