{ stdenv
, lib
, fetchbzr
, autoreconfHook
, intltool
, pkg-config
, dbus-glib
, glib
}:

stdenv.mkDerivation rec {
  pname = "dbus-test-runner";
  version = "unstable-2019-10-02";

  src = fetchbzr {
    url = "lp:dbus-test-runner";
    rev = "109";
    sha256 = "sha256-4yH19X98SVqpviCBIWzIX6FYHWxCbREpuKCNjQuTFDk=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    intltool
    pkg-config
    glib # for autoconf macro
  ];

  buildInputs = [
    dbus-glib
    glib
  ];

  enableParallelBuilding = true;

  # Don't error on deprecations
  NIX_CFLAGS_COMPILE = "-Wno-error";
}
