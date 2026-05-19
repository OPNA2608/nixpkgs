{
  lib,
  stdenv,
  fetchFromGitHub,

  qtbase,

  at-spi2-atk,
  at-spi2-core,
  libepoxy,
  gtk3,
  libdatrie,
  libselinux,
  libsepol,
  libthai,
  pcre,
  util-linux,
  wayland,
  libxtst,
  libxdmcp,

  cmake,
  doxygen,
  fontconfig,
  graphviz,
  pkg-config,
  wayland-protocols,
  wayland-scanner,
  wrapQtAppsHook,
  writableTmpDirAsHomeHook,

  enableDocumentation ? true,
  enableExamples ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "maliit-framework";
  version = "2.3.0-unstable-2024-06-24";

  src = fetchFromGitHub {
    owner = "maliit";
    repo = "framework";
    rev = "ba6f7eda338a913f2c339eada3f0382e04f7dd67";
    hash = "sha256-iwWLnstQMG8F6uE5rKF6t2X43sXQuR/rIho2RN/D9jE=";
  };

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optionals enableDocumentation [
    "doc"
  ]
  ++ lib.optionals enableExamples [
    "examples"
  ];

  postPatch =
    # Fix doubled prefixes
    ''
      substituteInPlace common/maliit-framework.prf.in \
        --replace-fail '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_INCLUDEDIR@' '@CMAKE_INSTALL_FULL_INCLUDEDIR@'

      substituteInPlace src/maliit-plugins.prf.in \
        --replace-fail '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_LIBDIR@' '@CMAKE_INSTALL_FULL_LIBDIR@' \
        --replace-fail '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_INCLUDEDIR@' '@CMAKE_INSTALL_FULL_INCLUDEDIR@'
    ''
    # Use maliit-server from this build
    + ''
      substituteInPlace examples/apps/plainqt/mainwindow.cpp \
        --replace-fail 'serverName("maliit-server")' "serverName(\"$out/bin/maliit-server\")"
    '';

  buildInputs = [
    at-spi2-atk
    at-spi2-core
    libepoxy
    gtk3
    libdatrie
    libselinux
    libsepol
    libthai
    pcre
    util-linux
    wayland
    libxdmcp
    libxtst
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    wayland-protocols
    wayland-scanner
    wrapQtAppsHook
  ]
  ++ lib.optionals enableDocumentation [
    doxygen
    graphviz
    writableTmpDirAsHomeHook
  ];

  cmakeFlags = [
    (lib.strings.cmakeBool "enable-docs" enableDocumentation)
    (lib.strings.cmakeBool "enable-examples" enableExamples)
    (lib.strings.cmakeBool "enable-tests" finalAttrs.finalPackage.doCheck)
    (lib.strings.cmakeFeature "QT5_MKSPECS_INSTALL_DIR" "${placeholder "out"}/mkspecs")
    (lib.strings.cmakeFeature "QT5_PLUGINS_INSTALL_DIR" "${placeholder "out"}/${qtbase.qtPluginPrefix}")
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  postInstall = lib.optionalString enableExamples ''
    moveToOutput "bin/maliit-exampleapp-*" "$examples"
  '';

  env = {
    FONTCONFIG_FILE = lib.optionalString enableDocumentation "${fontconfig.out}/etc/fonts/fonts.conf";
    QT_PLUGIN_PATH = lib.optionalString finalAttrs.finalPackage.doCheck "${lib.getBin qtbase}/${qtbase.qtPluginPrefix}";
  };

  meta = {
    description = "Core libraries of Maliit and server";
    mainProgram = "maliit-server";
    homepage = "http://maliit.github.io/";
    license = lib.licenses.lgpl21Plus;
    maintainers = [ ];
  };
})
