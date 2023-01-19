{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, pkg-config
, glib
, gtest
, libqtdbustest
, qtbase
, qtdeclarative
, python3
}:

stdenv.mkDerivation rec {
  pname = "lomiri-api";
  # Too recent for other components
  # version = "0.2.0-pre";
  version = "0.1.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-api";
    #rev = "f5db96f881dc9acec705177da5a146e84e158708";
    #hash = "sha256-zDPDY/Fzyguap82WWm9Xm30LwSN1UON/AXwOqgyV59E=";
    rev = version;
    hash = "sha256-GDDCENGvbO4w/lK1PWaaqqa9t+foOH62dbvvHoidhwU=";
  };

  postPatch = ''
    for pyscript in $(find test -name '*.py'); do
      patchShebangs $pyscript
    done

    for pc in data/*.pc.in; do
      substituteInPlace $pc \
        --replace "\''${prefix}/include" '@CMAKE_INSTALL_FULL_INCLUDEDIR@' \
        --replace "\''${prefix}/@CMAKE_INSTALL_LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@'
    done
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    glib
    gtest
    libqtdbustest
    qtbase
    qtdeclarative
  ];

  nativeCheckInputs = [
    python3
  ];

  dontWrapQtApps = true;

  # Fails rn
  #doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
}
