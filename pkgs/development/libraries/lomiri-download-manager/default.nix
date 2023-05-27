# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, boost
, cmake
, cmake-extras
, dbus
, doxygen
, glog
, graphviz
, gtest
, lomiri-api
, pkg-config
, python3
, qtbase
, qtdeclarative
, wrapQtAppsHook
, xvfb-run
}:

stdenv.mkDerivation rec {
  pname = "lomiri-download-manager";
  version = "0.1.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-a9C+hactBMHMr31E+ImKDPgpzxajy1klkjDcSEkPHqI=";
  };

  postPatch = ''
    substituteInPlace src/{uploads,downloads}/daemon/CMakeLists.txt \
      --replace '/usr/share' "\''${CMAKE_INSTALL_DATADIR}" \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}" \
      --replace '/usr/lib' "\''${CMAKE_INSTALL_LIBDIR}"

    substituteInPlace src/{common/public,uploads/common,downloads/{client,common}}/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBEXECDIR}/pkgconfig" "\''${CMAKE_INSTALL_LIBDIR}/pkgconfig"

    substituteInPlace src/{uploads,downloads}/daemon/*.service \
      --replace '/usr/bin' '${placeholder "out"}/bin'

    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}"

    # Deprecation warnings on Qt 5.15
    # https://gitlab.com/ubports/development/core/lomiri-download-manager/-/issues/1
    substituteInPlace CMakeLists.txt \
      --replace "-Werror" ""
  '' + lib.optionalString (!doCheck) ''
    sed -i \
      -e '/add_subdirectory(tests)/d' \
      CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    doxygen
    graphviz
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    boost
    cmake-extras
    glog
    lomiri-api
    qtbase
    qtdeclarative
  ];

  nativeCheckInputs = [
    dbus
    python3
    xvfb-run
  ];

  checkInputs = [
    gtest
  ];

  makeTargets = [
    "all"
    "doc"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  preCheck = ''
    export HOME=$TMPDIR # temp files in home
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix} # minimal platform & sqlite driver
    export QT_QPA_PLATFORM=minimal # don't use xcb
  '';

  meta = with lib; {
    description = "Performs uploads and downloads from a centralized location.";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-download-manager";
    license = licenses.lgpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
