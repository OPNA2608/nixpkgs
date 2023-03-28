# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitHub
, qmake
, qtdeclarative
, qtmultimedia
}:

stdenv.mkDerivation rec {
  pname = "qzxing";
  version = "3.3.0";

  src = fetchFromGitHub {
    owner = "ftylitak";
    repo = "qzxing";
    rev = "v${version}";
    hash = "sha256-ASgsF5ocNWAiIy2jm6ygpDkggBcEpno6iVNWYkuWcVI=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    qmake
    # qmake can't handle strictDeps properly
    qtmultimedia
  ];

  buildInputs = [
    qtmultimedia
  ];

  dontWrapQtApps = true;

  preConfigure = ''
    cd src
  '';

  qmakeFlags = [
    "CONFIG+=qzxing_qml"
    "CONFIG+=qzxing_multimedia"
    "QMAKE_PKGCONFIG_PREFIX=${placeholder "out"}"
  ];

  postInstall = ''
    # Some packages try to use this without pkg-config
    ln -s $out/include $out/include/qzxing
    for qzxinglib in $out/lib/libQZXing.so*; do
      ln -s $qzxinglib $(echo $qzxinglib | tr '[:upper:]' '[:lower:]')
    done
  '';
}
