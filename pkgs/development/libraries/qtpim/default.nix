{ stdenv
, lib
, fetchFromGitHub
, perl
, qmake
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "qtpim";
  version = "unstable-2020-11-02";

  src = fetchFromGitHub {
    owner = "qt";
    repo = "qtpim";
    rev = "f9a8f0fc914c040d48bbd0ef52d7a68eea175a98";
    hash = "sha256-/1g+vvHjuRLB1vsm41MrHbBZ+88Udca0iEcbz0Q1BNQ=";
  };

  postPatch = ''
    for module in src/{contacts,organizer,versit{,organizer}}/*.pro; do
      sed -i \
        -e '/load(qt_module)/a load(qt_module_headers)' \
        $module
    done
  '';

  strictDeps = true;

  nativeBuildInputs = [
    perl
    qmake
  ];

  buildInputs = [
    qtbase
  ];

  qmakeFlags = [
    "CONFIG+=git_build"
  ];

  dontWrapQtApps = true;
}
