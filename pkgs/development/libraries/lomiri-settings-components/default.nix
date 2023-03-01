# TODO
# - tests
# - meta
# - use qtbase variable for plugin/qml path
{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, cmake-extras
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "lomiri-settings-components";
  version = "1.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-Ybg+qyecvhPUDoIoq+0194u57imx7SxDMEmufGN22jM=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;

  postInstall = ''
    mv $out/lib/{qt5,qt-${qtbase.version}}
  '';
}
