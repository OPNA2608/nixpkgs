{ stdenv
, lib
, fetchbzr
, cmake
, cmake-extras
, pkg-config
, gtest
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "libqtdbustest";
  version = "0.2+17.04.20170106-0ubuntu1";

  src = fetchbzr {
    url = "lp:libqtdbustest";
    rev = "42";
    sha256 = "sha256-5MQdGGtEVE/pM9u0B0xFXyITiRln9p+8/MLtrrCZqi8=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    gtest
    qtbase
  ];

  dontWrapQtApps = true;
}
