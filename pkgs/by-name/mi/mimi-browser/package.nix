{
  stdenv,
  lib,
  fetchFromGitHub,
  at-spi2-atk,
  cairo,
  cmake,
  flite,
  glib,
  gperf,
  gst_all_1,
  harfbuzzFull,
  intltool,
  lcms,
  libepoxy,
  libgcrypt,
  libglvnd,
  libgpg-error,
  libpng,
  libjpeg,
  libsoup_3,
  libtasn1,
  libwebp,
  libwpe,
  libwpe-fdo,
  libxkbcommon,
  libxml2,
  libxslt,
  lomiri,
  mesa,
  openssl,
  perl,
  pkg-config,
  python3,
  qt5,
  ruby,
  sqlite,
  systemdLibs,
  unifdef,
  wayland,
  wayland-protocols,
  wayland-scanner,
  woff2,
}:

let
  webkit = stdenv.mkDerivation (finalAttrs: {
    pname = "webkit-fredldotme";
    version = "0-unstable-2024-12-13";

    src = fetchFromGitHub {
      owner = "fredldotme";
      repo = "WebKit";
      # Original rev from mimi-browser tag has copy-pasting error
      rev = "c49642681d6f1c029c878fd507fbea43710b59d6";
      hash = "sha256-LKjlClJTItq5hoBMgnn8CM3k4IVXy6LIqFL5/oLBXcs=";
    };

    strictDeps = true;

    nativeBuildInputs = [
      cmake
      glib
      gperf
      libxml2 # xmllint
      perl
      pkg-config
      python3
      ruby
      unifdef
      wayland-scanner
    ];

    buildInputs = [
      at-spi2-atk
      cairo
      flite
      harfbuzzFull
      lcms
      libepoxy
      libgcrypt
      libglvnd # EGL/eglplatform.h
      libgpg-error
      libpng
      libjpeg
      libsoup_3
      libtasn1
      libwebp
      libxkbcommon
      libxml2
      libxslt
      openssl
      sqlite
      systemdLibs
      libwpe
      libwpe-fdo
      wayland
      wayland-protocols
      woff2
    ] ++ (with gst_all_1; [
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
    ]);

    cmakeFlags = [
      (lib.cmakeFeature "PORT" "WPE")
      (lib.cmakeBool "DEVELOPER_MODE" true)
      (lib.cmakeBool "DEVELOPER_MODE_FATAL_WARNINGS" false)
      (lib.cmakeBool "ENABLE_INTROSPECTION" false)
      (lib.cmakeBool "ENABLE_API_TESTS" false)
      (lib.cmakeBool "ENABLE_TOOLS" false)
      (lib.cmakeBool "ENABLE_PDFJS" false)
      (lib.cmakeBool "ENABLE_WEBASSEMBLY" true)
      (lib.cmakeBool "ENABLE_WPE_QT_API" false)
      (lib.cmakeBool "ENABLE_WPE_1_1_API" false)
      (lib.cmakeBool "ENABLE_SMOOTH_SCROLLING" true)
      (lib.cmakeBool "ENABLE_KINETIC_SCROLLING" true)
      (lib.cmakeBool "ENABLE_TOUCH_EVENTS" true)
      (lib.cmakeBool "ENABLE_OVERFLOW_SCROLLING_TOUCH" true)
      (lib.cmakeBool "ENABLE_PLUGIN_PROCESS" false)
      (lib.cmakeBool "ENABLE_DOCUMENTATION" false)
      (lib.cmakeBool "ENABLE_WEB_RTC" true)
      (lib.cmakeBool "ENABLE_BUBBLEWRAP_SANDBOX" false)
      (lib.cmakeBool "ENABLE_CONTEXT_MENUS" true)
      (lib.cmakeBool "ENABLE_EXPERIMENTAL_FEATURES" true)
      (lib.cmakeBool "ENABLE_WEBXR" false)
      (lib.cmakeBool "ENABLE_THUNDER" false)
      (lib.cmakeBool "USE_SOUP2" false)
      (lib.cmakeBool "USE_SKIA" false)
      (lib.cmakeBool "USE_JPEGXL" false)
      (lib.cmakeBool "USE_LIBBACKTRACE" false)
      (lib.cmakeBool "USE_AVIF" false)
      (lib.cmakeBool "USE_GBM" false)
      (lib.cmakeBool "USE_LIBDRM" false)
      (lib.cmakeBool "USE_GSTREAMER_TRANSCODER" false)
      (lib.cmakeBool "USE_GSTREAMER_WEBRTC" true)
    ];
  });
  wpewebkit-qt = stdenv.mkDerivation (finalAttrs: {
    pname = "wpewebkit-qt-fredldotme";
    version = "0-unstable-2024-12-13";

    src = fetchFromGitHub {
      owner = "fredldotme";
      repo = "wpewebkit-qt";
      rev = "4441abd3201548e69897c12e8a38ce4754ae21c5";
      hash = "sha256-8nTNSftBsTgMs4tmPAnhiHYI1i1XfEa0EKpLOIziW94=";
    };

    strictDeps = true;

    nativeBuildInputs = [
      cmake
      pkg-config
    ];

    buildInputs = [
      libepoxy
      libwpe
      libwpe-fdo
      mesa # gbm.h
      webkit
      # webkit propagated deps
      libsoup_3
    ] ++ (with qt5; [
      qtbase
      qtdeclarative
    ]);

    dontWrapQtApps = true;

    cmakeFlags = [
      (lib.cmakeBool "USE_QT6" false)
      (lib.cmakeFeature "INSTALL_QMLDIR" "${placeholder "out"}/${qt5.qtbase.qtQmlPrefix}")
    ];

    doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "mimi-browser";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "fredldotme";
    repo = "webhunt";
    tag = finalAttrs.version;
    hash = "sha256-7EoJ6wcjO4YvPdYPmbDKHAoJ2m5p0KTsnCjKPRSHRtg=";
  };

  postPatch = ''
    # Use GNUInstallDirs
    substituteInPlace CMakeLists.txt \
      --replace-fail 'set(CMAKE_AUTOMOC ON)' 'set(CMAKE_AUTOMOC ON)
    include(GNUInstallDirs)' \
      --replace-fail 'set(DATA_DIR /)' 'set(DATA_DIR ''${CMAKE_INSTALL_DATADIR}/mimi-browser)' \
      --replace-fail 'RUNTIME DESTINATION ''${CMAKE_INSTALL_PREFIX}' 'RUNTIME DESTINATION ''${CMAKE_INSTALL_BINDIR}'

    # Don't force wayland
    substituteInPlace main.cpp \
      --replace-fail 'qputenv("QT_QPA_PLATFORM", "wayland-egl");' '// qputenv("QT_QPA_PLATFORM", "wayland-egl");'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    intltool
    pkg-config
  ] ++ (with qt5; [
    wrapQtAppsHook
  ]);

  buildInputs = [
    # QML
    wpewebkit-qt
  ] ++ (with qt5; [
    qtbase
    qtquickcontrols2
    qtwayland
  ]) ++ (with lomiri; [
    lomiri-content-hub
    lomiri-ui-toolkit
  ]);
})
