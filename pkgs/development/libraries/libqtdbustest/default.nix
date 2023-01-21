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
  version = "0.2+17.04.20170106-0ubuntu1";

  src = fetchbzr {
    url = "lp:libqtdbustest";
    rev = "42";
    sha256 = "sha256-5MQdGGtEVE/pM9u0B0xFXyITiRln9p+8/MLtrrCZqi8=";
  };

  strictDeps = true;

  postPatch = ''
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

  # The tests can be made to work, but are too flaky to be worth it
  # They require access to the system bus and randomly failed at least twice on us
  doCheck = false;

  meta = with lib; {
    description = "Library for testing DBus interactions using Qt";
    homepage = "https://launchpad.net/libqtdbustest";
    license = licenses.lgpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
    mainProgram = "qdbus-simple-test-runner";
  };
}
