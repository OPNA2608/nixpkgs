{ stdenv
, lib
, fetchFromGitHub
, perl
, qmake
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "qtsystems";
  version = "unstable-2019-01-03";

  src = fetchFromGitHub {
    owner = "qt";
    repo = "qtsystems";
    rev = "e3332ee38d27a134cef6621fdaf36687af1b6f4a";
    hash = "sha256-P8MJgWiDDBCYo+icbNva0LODy0W+bmQTS87ggacuMP0=";
  };

  postPatch = ''
    for module in src/{publishsubscribe,serviceframework,systeminfo}/*.pro; do
      sed -i \
        -e '/load(qt_module)/a load(qt_module_headers)' \
        $module
    done

    for needsInstallFixed in src/tools/{servicefw,sfwlisten}/*.pro; do
      substituteInPlace $needsInstallFixed \
        --replace "\''$\''$[QT_INSTALL_BINS]" "$out/bin/"
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
