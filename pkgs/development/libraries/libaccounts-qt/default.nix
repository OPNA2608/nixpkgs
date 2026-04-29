{
  stdenv,
  lib,
  fetchFromGitLab,
  testers,
  unstableGitUpdater,
  dbus-test-runner,
  doxygen,
  glib,
  graphviz,
  libaccounts-glib,
  pkg-config,
  qmake,
  qtbase,
  qttools,
  writableTmpDirAsHomeHook,
}:

let
  withQt6 = lib.strings.versionAtLeast qtbase.version "6";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "libaccounts-qt";
  version = "1.17-unstable-2026-04-06";

  src = fetchFromGitLab {
    owner = "accounts-sso";
    repo = "libaccounts-qt";
    rev = "6b88a0cfede8a451bff7ba7e2e0b7bd5c6c3a5ad";
    hash = "sha256-sTdMQzO3MYLJRIvq93iB3y2S+EdMwkbNp4s4ftRwJaA=";
  };

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  postPatch =
    # Don't install test binary. Not useful, and it has ref to /build
    ''
      substituteInPlace tests/tst_libaccounts.pro \
        --replace-fail 'include( ../common-installs-config.pri )' '# include( ../common-installs-config.pri )'
    ''
    # We're installing headers to dev output
    + ''
      substituteInPlace Accounts/AccountsQt*Config.cmake.in \
        --replace-fail 'set(ACCOUNTSQT_INCLUDE_DIRS $${INSTALL_PREFIX}' 'set(ACCOUNTSQT_INCLUDE_DIRS $${NIX_OUTPUT_DEV}'
    ''
    # qhelpgenerator isn't on PATH w/ Qt6
    + ''
      substituteInPlace doc/doxy.conf \
        --replace-fail \
          '= qhelpgenerator' \
          '= ${if withQt6 then "${qttools}/libexec" else "${lib.getDev qttools}/bin"}/qhelpgenerator'
    '';

  # QMake
  strictDeps = false;

  nativeBuildInputs = [
    doxygen
    graphviz
    pkg-config
    qmake
    qttools # qhelpgenerator
    writableTmpDirAsHomeHook # to stop doxygen from complaining
  ];

  buildInputs = [
    glib
    libaccounts-glib
  ];

  nativeCheckInputs = [
    dbus-test-runner
  ];

  # Library
  dontWrapQtApps = true;

  # Configure *now*
  postConfigure = ''
    make qmake_all
  '';

  postBuild = ''
    make docs
  '';

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  env.QT_PLUGIN_PATH = "${lib.getBin qtbase}/${qtbase.qtPluginPrefix}";

  passthru = {
    tests.pkg-config = testers.hasPkgConfigModules {
      package = finalAttrs.finalPackage;
      # Unstable packaging
      version = builtins.head (builtins.split "-unstable-" finalAttrs.finalPackage.version);
      versionCheck = true;
    };
    updateScript = unstableGitUpdater {
      tagPrefix = "VERSION_";
    };
  };

  meta = {
    description = "Qt-based client library for the accounts database";
    homepage = "https://accounts-sso.gitlab.io/";
    license = lib.licenses.lgpl21Only;
    maintainers = [ lib.maintainers.OPNA2608 ];
    platforms = lib.platforms.unix;
    pkgConfigModules = [
      "accounts-qt${lib.versions.major qtbase.version}"
    ];
  };
})
