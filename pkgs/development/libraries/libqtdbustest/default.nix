{ stdenv
, lib
, fetchbzr
, cmake
, cmake-extras
, dbus
, gtest
, pkg-config
, procps
, python3
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "libqtdbustest";
  version = "unstable-2017-01-06";

  src = fetchbzr {
    url = "lp:libqtdbustest";
    rev = "42";
    sha256 = "sha256-5MQdGGtEVE/pM9u0B0xFXyITiRln9p+8/MLtrrCZqi8=";
  };

  patches = [
    # Tests are overly pedantic when looking for launched process names in `ps`, break on python wrapper vs real python
    # Just check if basename + arguments match, like libqtdbusmock does
    ./less-pedantic-process-finding.patch
  ];

  strictDeps = true;

  postPatch =  lib.optionalString (!doCheck) ''
    # Don't build tests when we're not running them
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    qtbase
  ];

  nativeCheckInputs = [
    dbus
    procps
    (python3.withPackages (ps: with ps; [
      python-dbusmock
    ]))
  ];

  checkInputs = [
    gtest
  ];

  dontWrapQtApps = true;

  # Tests might be flaky
  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  checkPhase = ''
    runHook preCheck

    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- make test

    runHook postCheck
  '';

  meta = with lib; {
    description = "Library for testing DBus interactions using Qt";
    homepage = "https://launchpad.net/libqtdbustest";
    license = licenses.lgpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
    mainProgram = "qdbus-simple-test-runner";
  };
}
