# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, cups
, exiv2
, pam
, pkg-config
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "lomiri-ui-extras";
  version = "0.6.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-aKce+w+ZROfxARBTyRRW136jfXZbucgQ0awTk7Faajk=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    substituteInPlace modules/Lomiri/Components/Extras{,/{plugin,PamAuthentication}}/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" '${qtbase.qtQmlPrefix}'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    cups
    exiv2
    pam
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  # TODO
  doCheck = false;
}
