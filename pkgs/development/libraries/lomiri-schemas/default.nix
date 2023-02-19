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
  version = "0.1.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-rDktTTk5SLQ3wJiu0g1WPv6Rh560Rx7c50WuNVlXSew=";
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
