{ mkDerivation
, lib
, fetchFromGitHub
, fetchpatch

, at-spi2-atk
, at-spi2-core
, libepoxy
, gtk3
, libdatrie
, libselinux
, libsepol
, libthai
, pcre
, qtbase
, util-linux
, wayland
, xorg

, cmake
, doxygen
, pkg-config
, wayland-protocols
}:

mkDerivation rec {
  pname = "maliit-framework";
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "maliit";
    repo = "framework";
    rev = "refs/tags/${version}";
    sha256 = "sha256-q+hiupwlA0PfG+xtomCUp2zv6HQrGgmOd9CU193ucrY=";
  };

  patches = [
    # FIXME: backport GCC 12 build fix, remove for next release
    (fetchpatch {
      url = "https://github.com/maliit/framework/commit/86e55980e3025678882cb9c4c78614f86cdc1f04.diff";
      hash = "sha256-5R+sCI05vJX5epu6hcDSWWzlZ8ns1wKEJ+u8xC6d8Xo=";
    })
  ];

  postPatch = ''
    # Fix paths in QMake specs
    substituteInPlace common/maliit-framework.prf.in src/maliit-plugins.prf.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_INCLUDEDIR@' '@CMAKE_INSTALL_FULL_INCLUDEDIR@' \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_LIBDIR@' '@CMAKE_INSTALL_FULL_LIBDIR@'
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
    xorg.libXdmcp
    xorg.libXtst
  ];

  nativeBuildInputs = [
    cmake
    doxygen
    pkg-config
    wayland-protocols
  ];

  cmakeFlags = [
    "-DQT5_PLUGINS_INSTALL_DIR=${placeholder "out"}/${qtbase.qtPluginPrefix}"
    # Qt's setup hook expects the mkspecs there
    "-DQT5_MKSPECS_INSTALL_DIR=${placeholder "out"}/mkspecs"
  ];

  meta = with lib; {
    description = "Core libraries of Maliit and server";
    homepage = "http://maliit.github.io/";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ samueldr ];
  };
}
