{ stdenv
, lib
, fetchFromUbports
, cmake
, pkg-config
, cmake-extras
, gtest
, yaml-cpp
}:

stdenv.mkDerivation rec {
  pname = "deviceinfo";
  version = "0.1.1";

  src = fetchFromUbports {
    inherit pname;
    rev = version;
    hash = "sha256-LiMExXB3x8N/+hkAXzO2uytAjRGpQneJVTbPQBzonKk=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    yaml-cpp
  ];

  checkInputs = [
    gtest
  ];

  cmakeFlags = [
    "-DDISABLE_TESTS=${lib.boolToString (!doCheck)}"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  meta = with lib; {
    description = "Library to detect and configure devices";
    homepage = "https://gitlab.com/ubports/development/core/deviceinfo";
    license = licenses.gpl3Only;
    platforms = platforms.all; # ?
    maintainers = teams.lomiri.members;
    mainProgram = "device-info";
  };
}
