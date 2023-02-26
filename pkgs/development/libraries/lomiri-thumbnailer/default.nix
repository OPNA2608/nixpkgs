{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, boost
, gst_all_1
, gdk-pixbuf
, gtest
, libapparmor
, libexif
, lomiri-api
, persistent-cache-cpp
, qtbase
, qtdeclarative
, taglib
, python3
, leveldb
, wrapGAppsHook
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

  postPatch = ''
    patchShebangs tools/parse-settings.py

    # undefined reference to `core::PersistentCacheStats::...', `QNetworkReply::...', `boost::filesystem::...'
    substituteInPlace src/service/CMakeLists.txt \
      --replace 'target_link_libraries(thumbnailer-service' 'target_link_libraries(thumbnailer-service ''${Boost_LIBRARIES} Qt5::Network ''${CACHE_DEPS_LDFLAGS}'

    substituteInPlace plugins/Lomiri/Thumbnailer*/CMakeLists.txt \
      --replace 'qt5/qml' 'qt-${qtbase.version}/qml'

    substituteInPlace src/liblomiri-thumbnailer-qt/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${CMAKE_INSTALL_LIBDIR}" "\''${CMAKE_INSTALL_LIBDIR}"

  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
    wrapGAppsHook
  ];

  buildInputs = [
    boost
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
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
  ];

  checkInputs = [
    gtest
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

  # TODO
  doCheck = false;
}
