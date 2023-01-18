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

let
  pythonTestEnv = python3.withPackages (ps: with ps; [
    python-dbusmock
  ]);
in
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
    pythonTestEnv
    xvfb-run
  ];

  enableParallelBuilding = true;

  # Don't error on deprecations
  NIX_CFLAGS_COMPILE = "-Wno-error";

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  makeFlags = [
    "XVFB_RUN=${xvfb-run}/bin/xvfb-run"
  ];
}
