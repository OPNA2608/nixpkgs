{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, cmake-extras
, glib
, gtest
, libqtdbustest
, lomiri-api
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "gmenuharness";
  version = "0.1.4";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-MswB8cQvz3JvcJL2zj7szUOBzKRjxzJO7/x+87m7E7c=";
  };

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
    lomiri-api
    qtbase
  ];

  dontWrapQtApps = true;
}
