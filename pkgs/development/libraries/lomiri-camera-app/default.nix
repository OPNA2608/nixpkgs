# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, exiv2
, gettext
, gst_all_1
, libusermetrics
, lomiri-action-api
, lomiri-ui-toolkit
, pkg-config
, qtbase
, qtdeclarative
, qtmultimedia
, qtpositioning
, qtquickcontrols2
, qtsensors
, qzxing
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-camera-app";
  version = "4.0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/${pname}";
    rev = "v${version}";
    hash = "sha256-+rpTga8KjWpeOA4KhnSppBtQjGzuy+m+Jp8L0/hk03A=";
  };

  postPatch = ''
    substituteInPlace config.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@' \
      --replace '@CMAKE_INSTALL_PREFIX@/@CAMERA_APP_DIR@' '@CAMERA_APP_DIR@' \
      --replace '@CMAKE_INSTALL_PREFIX@/@PLUGIN_BASE@' '@PLUGIN_BASE@'
    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_DATADIR}/\''${CAMERA_APP}" "\''${CMAKE_INSTALL_FULL_DATADIR}/\''${CAMERA_APP}" \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${CAMERA_APP_DIR}" "\''${CAMERA_APP_DIR}" \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/\''${CAMERA_APP}" "\''${CMAKE_INSTALL_FULL_LIBDIR}/\''${CAMERA_APP}" \
      --replace "\''${CAMERA_APP_DIR}/lomiri" "\''${CAMERA_APP_DIR}/assets/lomiri"
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    exiv2
    qtbase
    qtdeclarative
    qtmultimedia
    qtquickcontrols2
    qzxing

    # QML
    libusermetrics
    lomiri-action-api
    lomiri-ui-toolkit
    qtpositioning
    qtsensors
  ] ++ (with gst_all_1; [
    # cannot create camera service, the 'camerabin' plugin is missing for GStreamer
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ]);

  cmakeFlags = [
    "-DINSTALL_TESTS=OFF"
    "-DCLICK_MODE=OFF"
  ];

  # TODO
  doCheck = false;

  preFixup = ''
    qtWrapperArgs+=(
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
    )
  '';
}
