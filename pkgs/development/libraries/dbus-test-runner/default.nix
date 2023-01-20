{ stdenv
, lib
, fetchbzr
, autoreconfHook
, intltool
, pkg-config
, dbus-glib
, glib
, coreutils
, dbus
, python3
, runtimeShell
, xvfb-run
}:

stdenv.mkDerivation rec {
  pname = "dbus-test-runner";
  version = "unstable-2019-10-02";

  src = fetchbzr {
    url = "lp:dbus-test-runner";
    rev = "109";
    sha256 = "sha256-4yH19X98SVqpviCBIWzIX6FYHWxCbREpuKCNjQuTFDk=";
  };

  postPatch = ''
    patchShebangs tests/test-wait-outputer

    substituteInPlace tests/Makefile.am \
      --replace '/bin/true' '${coreutils}/bin/true' \
      --replace '/bin/bash' '${runtimeShell}'
  '';

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

  nativeCheckInputs = [
    coreutils
    dbus
    (python3.withPackages (ps: with ps; [
      python-dbusmock
    ]))
    xvfb-run
  ];

  enableParallelBuilding = true;

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  checkFlags = [
    "XVFB_RUN=${xvfb-run}/bin/xvfb-run"
  ];

  meta = with lib; {
    description = "A small little utility to run a couple of executables under a new DBus session for testing";
    homepage = "https://launchpad.net/dbus-test-runner";
    license = licenses.gpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
