# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, lomiri-system-settings-unwrapped
, pkg-config
, polkit
, python3
, qtbase
, qtdeclarative
, trust-store
}:

stdenv.mkDerivation rec {
  pname = "lomiri-system-settings-security-privacy";
  version = "unstable-2023-03-01";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "0ceec71b697df8945b79660f4d3db519ee475619";
    hash = "sha256-+m8qQKeL8hINfOZu/FTCJ4X5JlCLGCOGENOkPq6urF0=";
  };

  postPatch = ''
    # CMake pkg_get_variable cannot replace prefix variable
    for pcvar in plugin_manifest_dir plugin_private_module_dir plugin_qml_dir; do
      pcvarname=$(echo $pcvar | tr '[:lower:]' '[:upper:]')
      substituteInPlace CMakeLists.txt \
        --replace "pkg_get_variable($pcvarname LomiriSystemSettings $pcvar)" "set($pcvarname $(pkg-config LomiriSystemSettings --define-variable=prefix=$out --variable=$pcvar))"
    done
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ];

  buildInputs = [
    lomiri-system-settings-unwrapped
    polkit
    qtbase
    qtdeclarative
    trust-store
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  # TODO
  doCheck = false;
}
