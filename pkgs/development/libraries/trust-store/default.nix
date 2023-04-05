# TODO
# - docs
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, boost
, cmake
, cmake-extras
, dbus-cpp
, gettext
, glog
, libapparmor
, newt
, pkg-config
, process-cpp
, properties-cpp
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "trust-store";
  version = "unstable-2023-02-27";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/trust-store";
    rev = "6c37311698e8ab95e3567001a514903be2d8f039";
    hash = "sha256-xzicLESsUuEV5dnk337mhvolQeVspU9jDst8l/g+YV8=";
  };

  postPatch = ''
    substituteInPlace src/core/trust/terminal_agent.h \
      --replace '/bin/whiptail' '${lib.getBin newt}/bin/whiptail'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
  ];

  buildInputs = [
    boost
    cmake-extras
    dbus-cpp
    glog
    libapparmor
    newt
    process-cpp
    properties-cpp # process-cpp
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    # Requires mirclient, removes in Mir 2.x
    # https://gitlab.com/ubports/development/core/trust-store/-/issues/2
    "-DTRUST_STORE_MIR_AGENT_ENABLED=OFF"
    # TODO
    "-DTRUST_STORE_ENABLE_DOC_GENERATION=OFF"
  ];

  # TODO
  doCheck = false;
}
