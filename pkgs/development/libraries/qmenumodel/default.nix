{ stdenv
, lib
, fetchFromGitHub
, cmake
, pkg-config
, glib
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "qmenumodel";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "qmenumodel";
    rev = version;
    hash = "sha256-cKolDRMamLWV8ASFLp1k0xslNAqVRCuM3/xvvBG98RI=";
  };

  postPatch = ''
    substituteInPlace libqmenumodel/src/qmenumodel.pc.in \
      --replace "\''${exec_prefix}/@CMAKE_INSTALL_LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace "\''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@" '@CMAKE_INSTALL_FULL_INCLUDEDIR@'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    glib
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;
}
