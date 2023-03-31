# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, glib
, lomiri-app-launch
, lomiri-url-dispatcher
, pkg-config
, properties-cpp
}:

stdenv.mkDerivation rec {
  pname = "indicator-location";
  version = "unstable-2023-02-16";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "9a20e02211ac7151889d2600b29a1c1871ea9e6e";
    hash = "sha256-MxUx9qMUBZJ72KAeiePW4wW4s6c9YJHRTvXhHxXIiog=";
  };

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace '/etc' "$out/etc" \
      --replace '/usr' "$out"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    glib
    lomiri-app-launch
    lomiri-url-dispatcher
    properties-cpp
  ];

  cmakeFlags = [
    "-Denable_tests=${lib.boolToString doCheck}"
  ];

  # TODO
  doCheck = false;
}
