{ stdenv
, lib
, fetchFromGitLab
, cmake
, lomiri-api
, lomiri-indicator-network
, pkg-config
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-push-qml";
  version = "unstable-2022-09-15";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-push-qml";
    rev = "6f87ee5cf92e2af0e0ce672835e71704e236b8c0";
    hash = "sha256-ezLcQRJ7Sq/TVbeGJL3Vq2lzBe7StRRCrWXZs2CCUX8=";
  };

  postPatch = ''
    substituteInPlace src/*/PushNotifications/CMakeLists.txt \
      --replace 'qmake -query QT_INSTALL_QML' 'echo ''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}' \
      --replace 'qt5_use_modules(''${PLUGIN} Core Gui Qml DBus)' 'find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5DBus REQUIRED)
target_link_libraries(''${PLUGIN} PUBLIC Qt5::Core Qt5::Gui Qt5::Qml Qt5::DBus)'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qtdeclarative # qmlplugindump
  ];

  buildInputs = [
    lomiri-api
    lomiri-indicator-network
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    # In case anything still depends on deprecated hints
    "-DENABLE_UBUNTU_COMPAT=ON"
  ];

  preBuild = ''
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}
  '';

  meta = with lib; {
    description = "";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-push-qml";
    license = licenses.gpl3Only;
    maintainers = teams.lomiri.members;
    platforms = platforms.linux;
  };
})
