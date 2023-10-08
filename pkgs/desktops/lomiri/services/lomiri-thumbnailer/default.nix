{ stdenv
, lib
, fetchFromGitLab
, gitUpdater
, testers
, boost
, cmake
, cmake-extras
, gst_all_1
, gdk-pixbuf
, gtest
, makeFontsConf
, libapparmor
, libexif
, libqtdbustest
, librsvg
, lomiri-api
, persistent-cache-cpp
, pkg-config
, python3
, qtbase
, qtdeclarative
, shared-mime-info
, taglib
, wrapGAppsHook
, xvfb-run
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-thumbnailer";
  version = "3.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-thumbnailer";
    rev = finalAttrs.version;
    hash = "sha256-0IrhmKNRr+Ojpix5hHMxmtIqfZAdUyvh+7SOWQlIs5c=";
  };

  outputs = [
    "out"
    "dev"
  ];

  patches = [
    ./0001-Drop-deprected-qt5_use_modules.patch
  ];

  postPatch = ''
    patchShebangs tools/{parse-settings.py,run-xvfb.sh} tests/{headers,whitespace,server}/*.py

    substituteInPlace tests/thumbnailer-admin/thumbnailer-admin_test.cpp \
      --replace '/usr/bin/test' 'test'

    substituteInPlace plugins/Lomiri/Thumbnailer*/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}"

    # thumbnailer-static doesn't properly propagate its link dependencies?
    # undefined reference to `core::PersistentCacheStats::...', `QNetworkReply::...', `boost::filesystem::...'
    substituteInPlace src/service/CMakeLists.txt tests/slow-vs-thumb/CMakeLists.txt tests/thumbnailer/CMakeLists.txt \
      --replace 'thumbnailer-static' 'thumbnailer-static ''${Boost_LIBRARIES} Qt5::Network ''${CACHE_DEPS_LDFLAGS}'

    # Unnecessary & wrong concatenation
    substituteInPlace src/liblomiri-thumbnailer-qt/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${CMAKE_INSTALL_LIBDIR}" "\''${CMAKE_INSTALL_LIBDIR}"

    # I think this variable fails to be populated because of our toolchain, while upstream uses Debian / Ubuntu where this works fine
    # https://cmake.org/cmake/help/v3.26/variable/CMAKE_LIBRARY_ARCHITECTURE.html
    # > If the <LANG> compiler passes to the linker an architecture-specific system library search directory such as
    # > <prefix>/lib/<arch> this variable contains the <arch> name if/as detected by CMake.
    substituteInPlace tests/qml/CMakeLists.txt \
      --replace 'CMAKE_LIBRARY_ARCHITECTURE' 'CMAKE_SYSTEM_PROCESSOR' \
      --replace 'powerpc-linux-gnu' 'ppc' \
      --replace 's390x-linux-gnu' 's390x'

    # The error returned in this test is slightly different than expected
    # boost::filesystem::canonical: No such file or directory [generic:2]: "/build/source/tests/media/no-such-file.jpg"
    substituteInPlace \
      tests/dbus/dbus_test.cpp \
      tests/liblomiri-thumbnailer-qt/liblomiri-thumbnailer-qt_test.cpp \
      tests/thumbnailer/thumbnailer_test.cpp \
      --replace 'No such file or directory:' 'No such file or directory'

    # Tests run in parallel to other builds, don't suck up cores
    substituteInPlace tests/headers/compile_headers.py \
      --replace 'max_workers=multiprocessing.cpu_count()' "max_workers=1"

    # The code here inserts include flags for includes in a compile test but (accidentally?) prepends an extra /, producing the following:
    # "-I//nix/store/<hash>-qtbase-<version>-dev/include/QtGui", to cover "#include <QImage>"
    # Our CC wrapper filters out these include flags with doubled /'s pointing into the store because it consideres them impure, which breaks this test.
    # Work around this by not prepending the extra /.
    # TODO report as a defect? Is this intentional behaviour?
    substituteInPlace tests/headers/CMakeLists.txt \
      --replace '-I/' '-I'

    # QSignalSpy checks in QML tests never see signal changes, works when running under nix-shell -A?
    sed -i tests/CMakeLists.txt \
      -e '/qml/d'
  '' + lib.optionalString (!finalAttrs.doCheck) ''
    sed -i CMakeLists.txt \
      -e '/add_subdirectory(tests)/d'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gdk-pixbuf # setup hook
    pkg-config
    (python3.withPackages (ps: with ps; lib.optionals finalAttrs.doCheck [
      python-dbusmock
      tornado
    ]))
    wrapGAppsHook
  ];

  buildInputs = [
    boost
    cmake-extras
    gdk-pixbuf
    libapparmor
    libexif
    librsvg
    lomiri-api
    persistent-cache-cpp
    qtbase
    qtdeclarative
    shared-mime-info
    taglib
  ] ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    # maybe add ugly to cover all kinds of formats?
  ]);

  nativeCheckInputs = [
    shared-mime-info
    xvfb-run
  ];

  checkInputs = [
    gtest
    libqtdbustest
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
    # error: use of old-style cast to 'std::remove_reference<_GstElement*>::type' {aka 'struct _GstElement*'}
    "-DWerror=OFF"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  enableParallelChecking = false;

  preCheck = ''
    # Fontconfig warnings breaks some tests
    export FONTCONFIG_FILE=${makeFontsConf { fontDirectories = []; }}
    export HOME=$TMPDIR

    # Some tests need Qt plugins
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}

    # QML tests need QML modules
    export QML2_IMPORT_PATH=${lib.getBin qtdeclarative}/${qtbase.qtQmlPrefix}
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix XDG_DATA_DIRS : ${lib.makeSearchPath "share" [ shared-mime-info ]}
    )
  '';

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
    updateScript = gitUpdater { };
  };

  meta = with lib; {
    description = "D-Bus service for out of process thumbnailing";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-thumbnailer";
    license = with licenses; [ gpl3Only lgpl3Only ];
    maintainers = teams.lomiri.members;
    platforms = platforms.linux;
    pkgConfigModules = [
      "liblomiri-thumbnailer-qt"
    ];
  };
})
