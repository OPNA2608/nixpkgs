{ stdenv
, lib
, fetchbzr
, autoreconfHook
, bash
, coreutils
, dbus
, dbus-glib
, glib
, intltool
, pkg-config
, python3
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

    # Tests `cat` together build shell scripts
    # true is a PATHable call, bash a shebang
    substituteInPlace tests/Makefile.am \
      --replace '/bin/true' 'true' \
      --replace '/bin/bash' '${lib.getBin bash}/bin/bash'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    glib # for autoconf macro, gtester, gdbus
    intltool
    pkg-config
  ];

  buildInputs = [
    dbus-glib
    glib
  ];

  nativeCheckInputs = [
    bash
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
