{ stdenv
, lib
, fetchbzr
, cmake
, pkg-config
, cmake-extras
, gtest
, libqtdbustest
, networkmanager
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "libqtdbusmock";
  version = "0.7+17.04.20170316.1-0ubuntu1";

  src = fetchbzr {
    url = "lp:libqtdbusmock";
    rev = "49";
    sha256 = "sha256-q3jL8yGLgcNxXHPh9M9cTVtUvonrBUPNxuPJIvu7Q/s=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace 'NetworkManager' 'libnm'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    gtest
    libqtdbustest
    networkmanager
    qtbase
  ];

  dontWrapQtApps = true;

  NIX_CFLAGS_COMPILE = "-DQT_NO_KEYWORDS";
}
