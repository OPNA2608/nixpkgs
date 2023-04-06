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
, dbus-cpp
, gdk-pixbuf
, glib
, gst_all_1
, libapparmor
, libexif
, qtbase
, qtdeclarative
, pkg-config
, properties-cpp
, sqlite
, taglib
, udisks
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "mediascanner2";
  version = "0.115";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-UEwFe65VB2asxQhuWGEAVow/9rEvZxry4dd2/60fXN4=";
  };

  postPatch = ''
    substituteInPlace src/qml/MediaScanner.*/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" '${placeholder "out"}/${qtbase.qtQmlPrefix}'
    substituteInPlace src/daemon/scannerdaemon.cc \
      --replace 'Unity8' 'Lomiri'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    boost # dbus-cpp
    cmake-extras
    dbus
    dbus-cpp
    gdk-pixbuf
    glib
    libapparmor
    libexif
    properties-cpp # dbus-cpp
    qtbase
    qtdeclarative
    sqlite
    taglib
    udisks
  ] ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
  ]);

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  # TODO
  doCheck = false;

  preFixup = ''
    qtWrapperArgs+=(
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
    )
  '';

}
