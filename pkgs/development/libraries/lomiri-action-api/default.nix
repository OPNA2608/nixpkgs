# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, qmake
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "lomiri-action-api";
  version = "1.1.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-FOHjZ5F4IkjSn/SpZEz25CbTR/gaK4D7BRxDVSDuAl8=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    # Queries QMake for broken Qt variable: '/build/qtbase-<commit>/$(out)/$(qtQmlPrefix)'
    substituteInPlace qml/Lomiri/Action/CMakeLists.txt \
      --replace "\''${QT_IMPORTS_DIR}/Lomiri" '${qtbase.qtQmlPrefix}/Lomiri'
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

  cmakeFlags = [
    "-DENABLE_TESTING=${lib.boolToString doCheck}"
    "-Duse_libhud2=OFF" # Use vendored libhud2, TODO package libhud2 separately
  ];

  dontWrapQtApps = true;

  # TODO
  doCheck = false;
}
