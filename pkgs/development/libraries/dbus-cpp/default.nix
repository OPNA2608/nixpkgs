{ stdenv
, lib
, fetchFromGitLab
, boost
, cmake
, cmake-extras
, dbus
, gtest
, libxml2
, pkg-config
, process-cpp
, properties-cpp
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

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  meta = with lib; {
    description = "A header-only dbus-binding leveraging C++-11";
    homepage = "https://gitlab.com/ubports/development/core/lib-cpp/dbus-cpp";
    license = licenses.lgpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
    mainProgram = "dbus-cppc";
  };
}
