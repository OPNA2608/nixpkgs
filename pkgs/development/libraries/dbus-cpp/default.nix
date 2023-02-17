{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, pkg-config
, boost
, libxml2
, dbus
, process-cpp
, properties-cpp
, gtest
}:

stdenv.mkDerivation rec {
  pname = "dbus-cpp";
  version = "5.0.3";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lib-cpp/${pname}";
    rev = version;
    hash = "sha256-t8SzPRUuKeEchT8vAsITf8MwbgHA+mR5C9CnkdVyX7s=";
  };

  postPatch = lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    boost
    cmake-extras
    dbus
    libxml2
    process-cpp
    properties-cpp
  ];

  checkInputs = [
    gtest
  ];

  # TODO
  doCheck = false;
}
