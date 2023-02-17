{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, cmake-extras
, pkg-config
, boost
, doxygen
, gtest
, leveldb
}:

stdenv.mkDerivation rec {
  pname = "persistent-cache-cpp";
  version = "1.0.5";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lib-cpp/${pname}";
    rev = version;
    hash = "sha256-MOH8ardiTliTKrtRQ5eFRhbRtnC0Yq20WJYoo1tAn3E=";
  };

  patches = [
    # Fix build on GCC 12
    # Remove when version > 1.0.5
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/lib-cpp/persistent-cache-cpp/-/commit/3ed84ee1d32a27d183de2cb5f9feffc3f48fd9a1.patch";
      hash = "sha256-aNZ6KVHAsLVYlAcPNNkjUlOPRDZxzN5tzk4/1KuVaSY=";
    })
    # Fix build on current Boost
    # Remove when version > 1.0.5
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/lib-cpp/persistent-cache-cpp/-/commit/a590ffcccec252caa7b19a2922c678502069b057.patch";
      hash = "sha256-OhlsnUVhclt17brkncYkJ0+lXrJO671mtwopaAGPrtY=";
    })
  ];

  postPatch = ''
    # Wrong concatenation
    substituteInPlace data/libpersistent-cache-cpp.pc.in \
      --replace "\''${prefix}/@CMAKE_INSTALL_LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
    doxygen
    pkg-config
  ];

  buildInputs = [
    boost
    cmake-extras
    leveldb
  ];

  checkInputs = [
    gtest
  ];

  cmakeFlags = [
    # error: 'old_version' may be used uninitialized
    "-DWerror=OFF"
  ];

  # TODO
  doCheck = false;
}
