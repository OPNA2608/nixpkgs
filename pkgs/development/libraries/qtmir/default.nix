{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, pkg-config
, wrapQtAppsHook
, gsettings-qt
, gtest
, libqtdbustest
, libqtdbusmock
, libuuid
, lomiri-api
, lomiri-app-launch
, lomiri-url-dispatcher
, lttng-ust
, mir_1
, process-cpp
, qtbase
, qtdeclarative
, qtsensors
, valgrind
, protobuf
, glm
, boost
, properties-cpp
}:

stdenv.mkDerivation rec {
  pname = "qtmir";
  version = "0.7.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/qtmir";
    rev = version;
    hash = "sha256-Yp5myir9D6HoTW7m0AHv9vDtVVs2mN6LTu/UWgnVBkI=";
  };

  postPatch = ''
    sed -i \
      -e '/get_target_property(Qt5Gui_QPA_Plugin_Path/d' \
      -e '/_populate_Gui_plugin_properties/d' \
      -e 's,''${CMAKE_INSTALL_PREFIX}/''${CMAKE_INSTALL_LIBDIR},''${CMAKE_INSTALL_FULL_LIBDIR},g' \
      CMakeLists.txt

    substituteInPlace demos/paths.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_LIBDIR@' '@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

    # mirclient is required & searched for but its flags never assigned to any build targets
    sed -i \
      -e '/MIRCOMMON_INCLUDE_DIRS/a ''${MIRCLIENT_INCLUDE_DIRS}' \
      src/platforms/mirserver/CMakeLists.txt
    for brokenTest in tests/mirserver/{EventBuilder,QtEventFeeder,Screen,ScreensModel}/CMakeLists.txt; do
      sed -i \
        -e '/MIRSERVER_INCLUDE_DIRS/a ''${MIRCLIENT_INCLUDE_DIRS}' \
        $brokenTest
    done

    # Needs a header from Boost
    for needsBoost in {src/modules/QtMir/Application,tests/modules/SurfaceManager}/CMakeLists.txt; do
      sed -i \
        -e '/MIRAL_INCLUDE_DIRS/a "${lib.getDev boost}/include"' \
        $needsBoost
    done
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    cmake-extras
    boost
    gsettings-qt
    gtest
    libqtdbustest
    libqtdbusmock
    libuuid
    lomiri-api
    lomiri-app-launch
    lomiri-url-dispatcher
    lttng-ust
    mir_1
    process-cpp
    protobuf
    qtbase
    qtdeclarative
    qtsensors
    valgrind

    # mir
    glm
    # lomiri-app-launch
    properties-cpp
  ];

  # src/modules/QtMir/Application/surfacemanager.h:29:10: fatal error: boost/bimap.hpp: No such file or directory
  NIX_CFLAGS_COMPILE = "-isystem ${lib.getDev properties-cpp}/include";
}
