# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, cryptsetup
, dbus
, glib
, libcal
, libdsme
, libiphb
, libngf
, mce-dev
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "dsme";
  version = "0.84.0";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "dsme";
    rev = version;
    fetchSubmodules = true; # dbus-gmain
    hash = "sha256-6CaKAH08djxY+hSG1rjpPriBHGsM8GbAMuYxTHBCM7M=";
  };

  postPatch = ''
    sed -i \
      -e '/powerontimer_la_LIBADD/a powerontimer_la_CFLAGS = $(DBUS_CFLAGS)' \
      modules/Makefile.am
  '' + lib.optionalString (!doCheck) ''
    substituteInPlace Makefile.am \
      --replace 'tests' "" \
      --replace 'test' ""
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    cryptsetup
    dbus
    glib
    libcal
    libdsme
    libiphb
    libngf
    mce-dev
  ];

  enableParallelBuilding = true;

  # TODO
  doCheck = false;
}
