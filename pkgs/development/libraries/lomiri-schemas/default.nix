{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, intltool
, cmake-extras
, glib
}:

stdenv.mkDerivation rec {
  pname = "lomiri-schemas";
  version = "0.1.3";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-FrDUFqdD0KW2VG2pTA6LMb6/9PdNtQUlYTEo1vnW6QQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    glib # glib-compile-schemas
    pkg-config
    intltool
  ];

  buildInputs = [
    cmake-extras
    glib
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];
}
