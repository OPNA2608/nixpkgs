# TODO
# - meta
{ stdenv
, lib
, fetchFromGitLab
, qmake
, qtdeclarative
, qtquickcontrols2
}:

stdenv.mkDerivation rec {
  pname = "qqc2-suru-style";
  version = "0.20230206";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-ZLPuXnhlR1IDhGnprcdWHLnOeS6ZzVkFhQML0iKMjO8=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    qmake
    # qmake + strictDeps isn't smart enough to find them from buildInputs
    qtdeclarative
    qtquickcontrols2
  ];

  buildInputs = [
    qtdeclarative
    qtquickcontrols2
  ];

  dontWrapQtApps = true;
}
