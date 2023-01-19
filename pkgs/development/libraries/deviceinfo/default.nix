{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, pkg-config
, cmake-extras
, gtest
, yaml-cpp
}:

stdenv.mkDerivation rec {
  pname = "deviceinfo";
  version = "0.1.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/deviceinfo";
    rev = "v${version}";
    hash = "sha256-YOjEYJkkGoArEFd9tZSBl+Vnjmd8NsPCnITVYT4Y56A=";
  };

  patches = [
    (fetchpatch {
      name = "deviceinfo-0001-Fix-FTBFS-when-building-without-Android-properties.patch";
      url = "https://gitlab.com/ubports/development/core/deviceinfo/-/commit/c25eedf01f6725aaa72f00e52eb2302383ea1429.patch";
      hash = "sha256-5OgpEd/8BU7sL7yqKHiIWh61XafnvBZN1e5yFdaGH1s=";
    })
  ];

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    gtest
    yaml-cpp
  ];
}
