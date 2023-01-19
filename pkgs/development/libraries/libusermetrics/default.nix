{ stdenv
, lib
, fetchFromGitLab
, cmake
, doxygen
, intltool
, pkg-config
, cmake-extras
, gsettings-qt
, gtest
, libapparmor
, libqtdbustest
, qdjango
, qtbase
, qtxmlpatterns
}:

stdenv.mkDerivation rec {
  pname = "libusermetrics";
  version = "1.2.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-A7N6XkByCzuJAFO7O7ix8pUg+GAXpIXaumTLdZdds/w=";
  };

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace '/etc' "$out/etc"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    doxygen
    intltool
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    gsettings-qt
    gtest
    libapparmor
    libqtdbustest
    qdjango
    qtbase
    qtxmlpatterns
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
  ];
}
