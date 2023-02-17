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
, mir
, process-cpp
, qtbase
, qtdeclarative
, qtsensors
, valgrind
, protobuf
, glm
, boost
, properties-cpp
, glib
, wayland
}:

stdenv.mkDerivation rec {
  pname = "qtmir";
  version = "unstable-2023-02-11-mir2.0";

  # Experimental support for Mir 2.x
  # Follows https://gitlab.com/ubports/development/core/qtmir/-/tree/ubports/focal_-_mir2.0
  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/qtmir";
    rev = "2ba9390629c96ee5221d6d607210e9993f6f0346";
    hash = "sha256-R8QBEViI+emKdW7lAcAQVi97th8oZiiYsGP1BjGM42c=";
  };

  postPatch = ''
    sed -i \
      -e '/get_target_property(Qt5Gui_QPA_Plugin_Path/d' \
      -e '/_populate_Gui_plugin_properties/d' \
      -e 's,''${CMAKE_INSTALL_PREFIX}/''${CMAKE_INSTALL_LIBDIR}/qt5/qml,''${CMAKE_INSTALL_FULL_LIBDIR}/qt-${qtbase.version}/qml,g' \
      CMakeLists.txt
    substituteInPlace src/platforms/mirserver/CMakeLists.txt \
      --replace 'qt5/plugins' 'qt-${qtbase.version}/plugins'

    substituteInPlace demos/paths.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_LIBDIR@' '@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

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
    glib # glib-compile-schemas
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
    mir
    process-cpp
    protobuf
    qtbase
    qtdeclarative
    qtsensors
    valgrind

    # mir
    glm
    wayland
    # lomiri-app-launch
    properties-cpp
  ];

  # src/modules/QtMir/Application/surfacemanager.h:29:10: fatal error: boost/bimap.hpp: No such file or directory
  NIX_CFLAGS_COMPILE = "-isystem ${lib.getDev properties-cpp}/include";

  cmakeFlags = [
    "-DWITH_MIR2=ON"
  ];

  postInstall = ''
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';
}
