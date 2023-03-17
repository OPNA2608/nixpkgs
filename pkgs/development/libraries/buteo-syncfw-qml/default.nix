# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "buteo-syncfw-qml";
  version = "unstable-2021-12-10";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/packaging/${pname}";
    rev = "8772af8de98689250123f2b47b9c644cf5647bdc";
    hash = "sha256-nEWI+22yskzDg5v1/5zwm+G8jnTc3W9JHR2oW2Ugln8=";
  };

  postPatch = ''
    substituteInPlace Buteo/CMakeLists.txt \
      --replace "\''${QT_IMPORTS_DIR}" '${placeholder "out"}/${qtbase.qtQmlPrefix}'

    # Implementation was removed?
    sed -i -e '/void onSyncProfilesByKeyFinished/d' Buteo/buteo-sync-qml.h
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;
}
