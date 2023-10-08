{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, testers
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
, xwayland
}:

stdenv.mkDerivation (finalAttrs: {
  # Not regular qtmir, experimental support for Mir 2.x
  # Follows https://gitlab.com/ubports/development/core/qtmir/-/tree/ubports/focal_-_mir2.0 branch
  pname = "qtmir-mir2.0";
  version = "unstable-2023-02-23";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/qtmir";
    rev = "088cdfe4ea51aeaac54698ebf8debfa967ffe17c";
    hash = "sha256-x0/79PBqmcoAPvnh2sY2D0Lp7g2Hw+q8K1UAyBjMfgM=";
  };

  outputs = [
    "out"
    "dev"
  ];

  patches = [
    # Mir 2.15 compatibility patch
    # Remove when https://gitlab.com/ubports/development/core/qtmir/-/merge_requests/70 merged into branch
    (fetchpatch {
      name = "0001-qtmir-Update-for-Mir-2.15-removals.patch";
      url = "https://gitlab.com/RAOF_47/qtmir/-/commit/ead5cacd4d69094ab956627f4dd94ecaff1fd69e.patch";
      hash = "sha256-hUUUnYwhNH3gm76J21M8gA5okaRd/Go03ZFJ4qn0JUo=";
    })
  ];

  postPatch = ''
    # get_target_property & _populate_Gui_plugin_properties don't work?
    # Fix QML install path
    sed -i CMakeLists.txt \
      -e '/get_target_property(Qt5Gui_QPA_Plugin_Path/d' \
      -e '/_populate_Gui_plugin_properties/d' \
      -e 's,''${CMAKE_INSTALL_PREFIX}/''${CMAKE_INSTALL_LIBDIR}/qt5/qml,''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix},g'

    # Fix includedir var in pkg-config file (not using prefix)
    # Honour GNUInstallDirs' INCLUDEDIR variable in general
    # Use corrent Qt plugin path
    substituteInPlace src/platforms/mirserver/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_PREFIX}/include" "\''${CMAKE_INSTALL_FULL_INCLUDEDIR}" \
      --replace 'DESTINATION "include' 'DESTINATION "''${CMAKE_INSTALL_INCLUDEDIR}' \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/plugins" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtPluginPrefix}"

    # Bad concatenations
    substituteInPlace demos/paths.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_LIBDIR@' '@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'
    substituteInPlace demos/qtmir-demo-client/qtmir-demo-client.desktop.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

    # Needs a header from Boost
    #for needsBoost in {src/modules/QtMir/Application,tests/modules/SurfaceManager}/CMakeLists.txt; do
    #  sed -i $needsBoost \
    #    -e '/MIRAL_INCLUDE_DIRS/a "${lib.getDev boost}/include"'
    #done

    # Needs path to Xwayland, else launching X11 applications crashes qtmir
    substituteInPlace data/xwayland.qtmir.desktop \
      --replace '/usr/bin/Xwayland' '${lib.getBin xwayland}/bin/Xwayland'
  '' + lib.optionalString (!finalAttrs.doCheck) ''
    # Remove test-specific dependencies unless we want tests
    sed -i CMakeLists.txt \
      -e '/QTDBUSTEST/d' \
      -e '/QTDBUSMOCK/d'
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
    xwayland

    glm # included by mir header
    wayland # mirwayland asks for this
    properties-cpp # included by l-a-l header
  ];

  checkInputs = [
    gtest
    libqtdbustest
    libqtdbusmock
  ];

  cmakeFlags = [
    "-DWITH_MIR2=ON"
    "-DNO_TESTS=${lib.boolToString (!finalAttrs.doCheck)}"
  ];

  postInstall = ''
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  # Tests currently unavailable, don't pull in would-be dependencies until they're available
  doCheck = false;

  passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

  meta = with lib; {
    description = "QPA plugin to make Qt a Mir server";
    homepage = "https://gitlab.com/ubports/development/core/qtmir";
    license = licenses.lgpl3Only;
    maintainers = teams.lomiri.members;
    platforms = platforms.linux;
    pkgConfigModules = [
      "qtmirserver"
    ];
  };
})
