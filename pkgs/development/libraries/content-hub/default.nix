{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, dbus-test-runner
, doxygen
, gettext
, glib
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
, withDocumentation ? true
, wrapGAppsHook
, xvfb-run
}:

stdenv.mkDerivation rec {
  pname = "content-hub";
  version = "1.0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-OGHZCTtvBmq/oBHcyrw+e6yLSHwi/aM04ALcaZXXaNs=";
  };

  patches = [
    ./0001-Migrate-GetConnectionAppArmorSecurityContext-GetConnectionCredentials.patch
  ];

  postPatch = ''
    substituteInPlace import/Lomiri/Content/CMakeLists.txt \
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
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    qtdeclarative # qmlplugindump
    wrapGAppsHook
  ] ++ lib.optionals withDocumentation [
    doxygen
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
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DENABLE_DOC=${lib.boolToString withDocumentation}"
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

  meta = with lib; {
    description = "Content sharing/picking service";
    longDescription = ''
      content-hub is a mediation service to let applications share content between them,
      even if they are not running at the same time.
    '';
    homepage = "https://gitlab.com/ubports/development/core/content-hub";
    license = with licenses; [ gpl3Only lgpl3Only ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
