# TODO
# - tests
# - meta
# - docs
# - cleanup that qmlplugindump stuff
{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, gettext
, glib
, gsettings-qt
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
, withDocumentation ? false
, wrapGAppsHook
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

  postPatch = ''
    substituteInPlace import/Lomiri/Content/CMakeLists.txt \
      --replace 'qt5/qml' 'qt-${qtbase.version}/qml' \
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

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DGSETTINGS_COMPILE=ON"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DENABLE_DOC=${lib.boolToString withDocumentation}"
  ];

  preBuild = ''
    # Executes qmlplugindump
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/lib/qt-${qtbase.version}/plugins
    export QML2_IMPORT_PATH=${lib.getBin qtdeclarative}/lib/qt-${qtbase.version}/qml:${lib.getBin lomiri-ui-toolkit}/lib/qt-${qtbase.version}/qml:${lib.getBin qtfeedback}/lib/qt-${qtbase.version}/qml:${lib.getBin qtgraphicaleffects}/lib/qt-${qtbase.version}/qml
  '';

  # TODO
  doCheck = false;
}
