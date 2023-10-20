{ stdenv
, lib
, fetchFromGitLab
, gitUpdater
, testers
, cmake
, cmake-extras
, dbus-test-runner
, doxygen
, gettext
, glib
, graphviz
, gsettings-qt
, gtest
, libapparmor
, libnotify
, lomiri-api
, lomiri-app-launch
, lomiri-download-manager
, lomiri-ui-toolkit
, pkg-config
, properties-cpp
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, wrapGAppsHook
, xvfb-run
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "content-hub";
  version = "1.0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/content-hub";
    rev = finalAttrs.version;
    hash = "sha256-OGHZCTtvBmq/oBHcyrw+e6yLSHwi/aM04ALcaZXXaNs=";
  };

  outputs = [
    "out"
    "dev"
    "doc"
    "examples"
  ];

  patches = [
    ./0001-Migrate-GetConnectionAppArmorSecurityContext-GetConnectionCredentials.patch
  ];

  postPatch = ''
    # -qt=qt5 argument not accepted by our qmlplugindump?
    substituteInPlace import/*/Content/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}" \
      --replace 'qmlplugindump -qt=qt5' 'qmlplugindump'

    substituteInPlace src/com/lomiri/content/service/com.lomiri.content.dbus.Service.service \
      --replace '/usr' '${placeholder "out"}'

    # Look for peer files and themes in running system
    # TODO the one in contenthubplugin.cpp overrides Qt's default theme search paths, why? Considerations for packaging & upstream
    # - remove from file?
    # - append to list?
    # - append to fallbacks instead?
    substituteInPlace src/com/lomiri/content/service/registry-updater.cpp import/Lomiri/Content/contenthubplugin.cpp \
      --replace '/usr' '/run/current-system/sw'

    # Bad concatenation, let output fixup handle pkg-config patching
    # Install headers correctly
    substituteInPlace CMakeLists.txt \
      --replace 'libdir ''${prefix}/''${CMAKE_INSTALL_LIBDIR}' 'libdir ''${prefix}/lib' \
      --replace 'install(DIRECTORY include DESTINATION ''${CMAKE_INSTALL_PREFIX})' 'install(DIRECTORY include/ DESTINATION ''${CMAKE_INSTALL_INCLUDEDIR})'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    qtdeclarative # qmlplugindump
    wrapGAppsHook
    doxygen
    graphviz
  ];

  buildInputs = [
    cmake-extras
    glib
    gsettings-qt
    libapparmor
    libnotify
    lomiri-api
    lomiri-app-launch
    lomiri-download-manager
    lomiri-ui-toolkit
    properties-cpp
    qtbase
    qtdeclarative
    qtfeedback
    qtgraphicaleffects
  ];

  nativeCheckInputs = [
    dbus-test-runner
    xvfb-run
  ];

  checkInputs = [
    gtest
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DGSETTINGS_COMPILE=ON"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DENABLE_DOC=ON"
    "-DENABLE_TESTS=${lib.boolToString finalAttrs.doCheck}"
    "-DENABLE_UBUNTU_COMPAT=ON" # in case something still depends on it
  ];

  preBuild = let
    listToQtVar = list: suffix: lib.strings.concatMapStringsSep ":" (drv: "${lib.getBin drv}/${suffix}") list;
  in ''
    # Executes qmlplugindump
    export QT_PLUGIN_PATH=${listToQtVar [ qtbase ] qtbase.qtPluginPrefix}
    export QML2_IMPORT_PATH=${listToQtVar [ qtdeclarative lomiri-ui-toolkit qtfeedback qtgraphicaleffects ] qtbase.qtQmlPrefix}
  '';

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  # Starts & talks to D-Bus services, breaks under parallelism
  enableParallelChecking = false;

  preFixup = ''
    for exampleExe in content-hub-test-{importer,exporter,sharer}; do
      moveToOutput bin/$exampleExe $examples
      moveToOutput share/applications/$exampleExe.desktop $examples
    done
    moveToOutput share/icons $examples
  '';

  postFixup = ''
    for exampleBin in $examples/bin/*; do
      wrapGApp $exampleBin
    done
  '';

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
    updateScript = gitUpdater { };
  };

  meta = with lib; {
    description = "Content sharing/picking service";
    longDescription = ''
      content-hub is a mediation service to let applications share content between them,
      even if they are not running at the same time.
    '';
    homepage = "https://gitlab.com/ubports/development/core/content-hub";
    license = with licenses; [ gpl3Only lgpl3Only ];
    mainProgram = "content-hub-send";
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
    pkgConfigModules = [
      "libcontent-hub"
      "libcontent-hub-glib"
    ];
  };
})
