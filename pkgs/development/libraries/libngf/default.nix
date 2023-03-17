# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, check
, dbus-glib
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "libngf";
  version = "0.28";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "libngf";
    rev = version;
    hash = "sha256-RUgJXV8kDy0e1b+/cEldaRivUkTql6bw87qdj0kdGrY=";
  };

  postPatch = ''
    substituteInPlace libngf0.pc.in \
      --replace '/usr' "$out"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    check
    dbus-glib
  ];

  enableParallelBuilding = true;
}
