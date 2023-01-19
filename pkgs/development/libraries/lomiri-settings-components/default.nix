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
  version = "1.0.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-vKofr2kbJU2qou62q/M+q83bMjp64EIAu9yO+4DfYzk=";
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
