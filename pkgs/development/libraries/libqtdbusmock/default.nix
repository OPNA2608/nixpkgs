{ stdenv
, lib
, fetchbzr
, cmake
, cmake-extras
, dbus
, gtest
, libqtdbustest
, networkmanager
, pkg-config
, procps
, python3
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "libqtdbusmock";
  version = "0.7+17.04.20170316.1-0ubuntu1";

  src = fetchbzr {
    url = "lp:libqtdbusmock";
    rev = "49";
    sha256 = "sha256-q3jL8yGLgcNxXHPh9M9cTVtUvonrBUPNxuPJIvu7Q/s=";
  };

  postPatch = ''
    # Look for the new(?) name
    substituteInPlace CMakeLists.txt \
      --replace 'NetworkManager' 'libnm'

    # Workaround for "error: expected unqualified-id before 'public'" on "**signals"
    # Don't build tests when we're not running them
    sed -i -e '/add_definitions/a -DQT_NO_KEYWORDS' -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    libqtdbustest
    networkmanager
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
    description = "Library for mocking DBus interactions using Qt";
    homepage = "https://launchpad.net/libqtdbusmock";
    license = licenses.lgpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
