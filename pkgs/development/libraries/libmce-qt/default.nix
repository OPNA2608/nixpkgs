# TODO
# - meta
{ stdenv
, lib
, fetchFromGitHub
, mce
, mce-dev
, pkg-config
, qmake
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "libmce-qt";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "libmce-qt";
    rev = version;
    hash = "sha256-4hQegZxsWYAPkOWAfbeEvtol86MtWYX+JUUu93uvI+M=";
  };

  postPatch = ''
    substituteInPlace lib/lib.pro \
      --replace '$$[QT_INSTALL_LIBS]' "$out/lib"
    substituteInPlace plugin/plugin.pro \
      --replace '$$[QT_INSTALL_QML]' "$out/$qtQmlPrefix"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    qmake
    qtdeclarative
  ];

  buildInputs = [
    mce-dev
    qtdeclarative
  ];

  dontWrapQtApps = true;
}
