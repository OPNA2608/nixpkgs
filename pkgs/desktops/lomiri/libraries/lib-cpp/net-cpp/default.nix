# TODO
# - docs
# - tests
# - meta
{ stdenv
, lib
, fetchFromUbports
, fetchpatch
, boost
, cmake
, curl
}:

stdenv.mkDerivation rec {
  pname = "net-cpp";
  version = "3.1.0";

  src = fetchFromUbports {
    inherit pname;
    group = "core/lib-cpp";
    rev = version;
    hash = "sha256-qXKuFLmtPjdqTcBIM07xbRe3DnP7AzieCy7Tbjtl0uc=";
  };

  patches = [
    (fetchpatch {
      name = "0001-net-cpp-Add-ENABLE_WERROR-option.patch";
      url = "https://gitlab.com/ubports/development/core/lib-cpp/net-cpp/-/commit/0945180aa6dd38245688d5ebc11951b272e93dc4.patch";
      hash = "sha256-91YuEgV+Q9INN4BJXYwWgKUNHHtUYz3CG+ROTy24GIE=";
    })
  ];

  postPatch = lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    boost
    curl
  ];

  cmakeFlags = [
    # https://gitlab.com/ubports/development/core/lib-cpp/net-cpp/-/issues/4
    "-DENABLE_WERROR=OFF"
  ];

  # TODO
  doCheck = false;

  meta = with lib; {
    description = "A simple yet beautiful networking API for C++11";
    homepage = "https://gitlab.com/ubports/development/core/lib-cpp/net-cpp";
    license = licenses.lgpl3Only;
    platforms = platforms.all;
    maintainers = teams.lomiri.members;
  };
}
