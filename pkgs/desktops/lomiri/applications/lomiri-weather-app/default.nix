{
  stdenv,
  lib,
  fetchFromGitLab,
  fetchpatch,
  gitUpdater,
  cmake,
  flatbuffers,
  gettext,
  lomiri-indicator-network,
  lomiri-ui-toolkit,
  pyotherside,
  qtbase,
  qtdeclarative,
  qtlocation,
  qtpositioning,
  qtquickcontrols2,
  qtwebengine,
  wrapQtAppsHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-weather-app";
  version = "6.2.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/lomiri-weather-app";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sQFAaF6waca/2TpBznqow1Hu9nGNpN5NLKyqwbPrXuU=";
  };

  patches = [
    # Allow disabling of connectivity check, allows usage without lomiri-indicator-network running
    # Remove when version > 6.2.0
    (fetchpatch {
      name = "0001-lomiri-weather-app-Make-the-connectivity-check-optional.patch";
      url = "https://gitlab.com/ubports/development/apps/lomiri-weather-app/-/commit/c1217e15f457b3437465f0f9d3098be435950cc9.patch";
      hash = "sha256-QDm6sMLe/gNbrAlLoZyoFrEW+OL2Nu/946h72KiHnXE=";
    })

    # Since flatbuffers 2.0.6, verifying the data received from openmeteo fails on an alignment check
    # because their data is not aligned correctly.
    # https://gitlab.com/ubports/development/apps/lomiri-weather-app/-/issues/118
    # This patch disables the strict alignment enforcement. This will cause critical issues on archs
    # that require correct alignment (armv6, mips, sparc), but I assume those won't be able to run Lomiri anyway.
    # Remove when version > 6.2.0
    (fetchpatch {
      name = "0002-lomiri-weather-app-Disable-alignment-check.patch";
      url = "https://gitlab.com/ubports/development/apps/lomiri-weather-app/-/commit/5f4148254caf15c036708a5f81ef79d24f3c8646.patch";
      hash = "sha256-cd2jVlbIxzdq0IJevm8uhCVC9CzQ5DQI8FeS8SggKdc=";
    })
  ];

  postPatch =
    # Queries qmake for the QML installation path, which returns a reference to Qt5's build directory
    ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'qmake -query QT_INSTALL_QML' 'echo ''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}'
    ''
    # We don't want absolute paths in desktop files
    + ''
      substituteInPlace lomiri-weather-app.desktop.in.in \
        --replace-fail 'Icon=@ICON@' 'Icon=lomiri-weather-app' \
        --replace-fail 'X-Lomiri-Splash-Image=@SPLASH@' 'X-Lomiri-Splash-Image=lomiri-app-launch/splash/lomiri-weather-app.svg'
    ''
    # CMake 4.0 dropped support for old minimum CMake versions. Bump the minimum.
    # Remove when version > 6.2.0
    + ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'cmake_minimum_required(VERSION 3.5)' 'cmake_minimum_required(VERSION 3.10)'
    ''
    + lib.optionalString (!finalAttrs.finalPackage.doCheck) ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'add_subdirectory(tests)' ""
    '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    wrapQtAppsHook
  ];

  buildInputs = [
    flatbuffers
    qtlocation
    qtquickcontrols2
    qtwebengine

    # QML
    lomiri-indicator-network # still imported, even when opted out of
    lomiri-ui-toolkit
    pyotherside
    qtdeclarative
    qtpositioning
  ];

  cmakeFlags = [
    (lib.strings.cmakeBool "CLICK_MODE" false)
    (lib.strings.cmakeBool "INSTALL_TESTS" false)
    (lib.strings.cmakeBool "CONNECTIVITY_CHECK" false) # Makes running outside of Lomiri possible
  ];

  # No tests we can actually run (just autopilot)
  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/{icons/hicolor/scalable/apps,lomiri-app-launch/splash}

    ln -s $out/share/{lomiri-weather-app/weather-app,icons/hicolor/scalable/apps/lomiri-weather-app}.svg
    ln -s $out/share/{lomiri-weather-app/weather-app-splash,lomiri-app-launch/splash/lomiri-weather-app}.svg
  '';

  passthru = {
    updateScript = gitUpdater { rev-prefix = "v"; };
  };

  meta = {
    description = "Weather application for Ubuntu Touch devices";
    homepage = "https://gitlab.com/ubports/development/apps/lomiri-weather-app";
    changelog = "https://gitlab.com/ubports/development/apps/lomiri-weather-app/-/blob/v${finalAttrs.version}/ChangeLog";
    license = with lib.licenses; [
      gpl3Only # code
      cc-by-sa-40 # additional graphics
    ];
    mainProgram = "lomiri-weather-app";
    teams = [ lib.teams.lomiri ];
    platforms = lib.platforms.linux;
  };
})
