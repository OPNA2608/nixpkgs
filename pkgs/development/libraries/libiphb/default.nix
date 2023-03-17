# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, dbus
, glib
, libdsme
, mce-dev
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "libiphb";
  version = "1.2.7";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "libiphb";
    rev = version;
    fetchSubmodules = true; # https://github.com/sailfishos-mirror/dbus-glib/tree/d42176ae4763e5288ef37ea314fe58387faf2005
    hash = "sha256-Pl3GBM2Qo8TvZF8s99Y+sumkWLtk+HSKRA9nbHHQpZ4=";
  };

  postPatch = lib.optionalString (!doCheck) ''
    substituteInPlace configure.ac \
      --replace 'tests/Makefile' ""
    substituteInPlace Makefile.am \
      --replace 'tests' ""
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    dbus
    glib
    libdsme
    mce-dev
  ];

  enableParallelBuilding = true;

  # TODO
  doCheck = false;
}
