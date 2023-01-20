{ stdenv
, lib
, fetchbzr
, cmake
, cmake-extras
, pkg-config
, qtbase
, gtest
, dbus
, procps
, python3
}:

stdenv.mkDerivation rec {
  pname = "libqtdbustest";
  version = "0.2+17.04.20170106-0ubuntu1";

  src = fetchbzr {
    url = "lp:libqtdbustest";
    rev = "42";
    sha256 = "sha256-5MQdGGtEVE/pM9u0B0xFXyITiRln9p+8/MLtrrCZqi8=";
  };

  strictDeps = true;

  patches = [
    # Tests are overly pedantic when they look for launched process names in `ps`, break on python wrapper vs real python
    # Just check if basename + arguments match, like libqtdbusmock does
    ./less-pedantic-process-finding.patch
  ];

  postPatch = lib.optionalString (!doCheck) ''
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

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  checkPhase = ''
    runHook preCheck

    export CTEST_OUTPUT_ON_FAILURE=1
    # tests need access to the system bus
    dbus-run-session --config-file=${../polkit/system_bus.conf} make test

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
