{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, cmake-extras
, dbus
, glib
, gtest
, libqtdbustest
, lomiri-api
, pkg-config
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "gmenuharness";
  version = "0.1.4";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-MswB8cQvz3JvcJL2zj7szUOBzKRjxzJO7/x+87m7E7c=";
  };

  patches = [
    # Remove when version > 0.1.4
    (fetchpatch {
      name = "0001-gmenuharness-Rename-type-attribute-from-x-canonical-type-to-x-lomiri-type.patch";
      url = "https://gitlab.com/ubports/development/core/gmenuharness/-/commit/70e9ed85792a6ac1950faaf26391ce91e69486ab.patch";
      hash = "sha256-jeue0qrl2JZCt/Yfj4jT210wsF/E+MlbtNT/yFTcw5I=";
    })
  ];

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    glib
    lomiri-api
    qtbase
  ];

  nativeCheckInputs = [
    dbus
  ];

  checkInputs = [
    gtest
    libqtdbustest
  ];

  cmakeFlags = [
    "-Denable_tests=${lib.boolToString doCheck}"
  ];

  dontWrapQtApps = true;

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  checkPhase = ''
    runHook preCheck

    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- make test

    runHook postCheck
  '';

  meta = with lib; {
    description = "Library to test GMenuModel structures";
    homepage = "https://gitlab.com/ubports/development/core/gmenuharness";
    license = licenses.gpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
