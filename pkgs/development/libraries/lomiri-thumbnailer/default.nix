# TODO
# - tests
{ stdenv
, lib
, fetchFromGitLab
, boost
, cmake
, cmake-extras
, gst_all_1
, gdk-pixbuf
, gtest
, makeFontsConf
, leveldb
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

stdenv.mkDerivation rec {
  pname = "lomiri-thumbnailer";
  version = "3.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-0IrhmKNRr+Ojpix5hHMxmtIqfZAdUyvh+7SOWQlIs5c=";
  };

  patches = [
    ./0001-Drop-deprected-qt5_use_modules.patch
  ];

  postPatch = ''
    patchShebangs tools/{parse-settings.py,run-xvfb.sh} tests/{headers,whitespace,server}/*.py

    substituteInPlace tests/thumbnailer-admin/thumbnailer-admin_test.cpp \
      --replace '/usr/bin/test' 'test'

    # thumbnailer-static doesn't properly propagate its link dependencies
    # undefined reference to `core::PersistentCacheStats::...', `QNetworkReply::...', `boost::filesystem::...'
    substituteInPlace src/service/CMakeLists.txt tests/slow-vs-thumb/CMakeLists.txt tests/thumbnailer/CMakeLists.txt \
      --replace 'thumbnailer-static' 'thumbnailer-static ''${Boost_LIBRARIES} Qt5::Network ''${CACHE_DEPS_LDFLAGS}'

    substituteInPlace plugins/Lomiri/Thumbnailer*/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}"

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

    # Tests run in parallel to other builds
    compileCores=1
    if [ "''${enableParallelBuilding-1}" ]; then
      compileCores=$NIX_BUILD_CORES
    fi
    substituteInPlace tests/headers/compile_headers.py \
      --replace 'max_workers=multiprocessing.cpu_count()' "max_workers=$compileCores"

    # TODO It says that it clears this because it might interfere with the tests, but I think the QML ones might need our help to get a D-Bus server?
    # substituteInPlace tests/qml/CMakeLists.txt \
    #   --replace 'DBUS_SESSION_BUS_ADDRESS=;' ""

    # TODO figure out why this fails
    # substituteInPlace tests/headers/CMakeLists.txt \
    #   --replace 'compile_headers.py' 'compile_headers.py -v'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gdk-pixbuf # setup hook
    pkg-config
    python3
    wrapGAppsHook
  ];

  buildInputs = [
    boost
    cmake-extras
    gdk-pixbuf
    libapparmor
    libexif
    lomiri-api
    persistent-cache-cpp
    qtbase
    qtdeclarative
    taglib

    # persistent-cache-cpp
    leveldb

    # thumbnailers & mime types
    librsvg
    shared-mime-info
  ] ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
  ]);

  nativeCheckInputs = [
    (python3.withPackages (ps: with ps; [
      python-dbusmock
      tornado
    ]))
    shared-mime-info
    xvfb-run
  ];

  checkInputs = [
    gtest
    libqtdbustest
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    # TODO C++ error message screen vomit
    #"-DENABLE_WERROR=OFF"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
    # error: use of old-style cast to 'std::remove_reference<_GstElement*>::type' {aka 'struct _GstElement*'}
    "-DWerror=OFF"
  ];

  # TODO borked
  # - qml has dbus-related problems
  #   - tried manually launching dbus session via patching, gives NETWORK DOWN errors
  # - stand-alone-lomiri-thumbnailer-qt-headers fails to compile its headers
  #   - dies on lomiri-thumbnailer-qt.h -> QImage, despite compiler call seemingly being correct & having the required -I ?
  doCheck = false;

  # TODO
  enableParallelChecking = false;

  preCheck = ''
    # Fontconfig breaks some tests with its errors
    export FONTCONFIG_FILE=${makeFontsConf { fontDirectories = []; }}
    export HOME=$TMPDIR

    # Some tests need Qt plugins
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}

    # QML tests need QML modules
    export QML2_IMPORT_PATH=${lib.getBin qtdeclarative}/${qtbase.qtQmlPrefix}

    # We need to ensure that some tests can find the gsettings schema and a dbus service that points to the build-tree binary
    # TODO why doesn't this work automatically?
    mkdir -p $HOME/{glib-2.0,dbus-1/services}
    ln -s $PWD/data $HOME/glib-2.0/schemas
    # cp src/service/com.lomiri.Thumbnailer.service $HOME/dbus-1/services/
    # sed -i \
    #   -e "s,$out/libexec/lomiri-thumbnailer/thumbnailer-service,$PWD/src/service/thumbnailer-service,g" \
    #   $HOME/dbus-1/services/com.lomiri.Thumbnailer.service
    export XDG_DATA_DIRS=$HOME:$XDG_DATA_DIRS
  '';

#  checkPhase = ''
#    runHook preCheck
#
#    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf make test ''${enableParallelChecking:+-j $NIX_BUILD_CORES}
#
#    runHook postCheck
#  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix XDG_DATA_DIRS : ${lib.makeSearchPath "share" [ shared-mime-info ]}
    )
  '';

  meta = with lib; {
    description = "D-Bus service for out of process thumbnailing";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-thumbnailer";
    license = with licenses; [ gpl3Only lgpl3Only ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
