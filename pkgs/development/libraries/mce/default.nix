# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitHub
, dbus
, dsme
, libdsme
, libiphb
, libngf
, glib
, mce-dev
, pkg-config
, systemd
, usb_moded
}:

stdenv.mkDerivation rec {
  pname = "mce";
  version = "1.115.2";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "mce";
    rev = version;
    fetchSubmodules = true; # dbus-gmain
    hash = "sha256-1B0JL3stjO44exywKeAOK3G43nyfbu6iJBWmDdCAAo4=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    dbus
    dsme
    libdsme
    libiphb
    libngf
    glib
    mce-dev
    systemd
    usb_moded
  ];

  makeFlags = [
    "ENABLE_HYBRIS=n"
    "DESTDIR="
    "_PREFIX=${placeholder "out"}"
    "_SYSCONFDIR=${placeholder "out"}/etc"
    "_LOCALSTATEDIR=${placeholder "out"}/var"
    "_UNITDIR=${placeholder "out"}/lib/systemd/system"
  ];

  enableParallelBuilding = true;
}
