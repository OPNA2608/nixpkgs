# TODO
# - doc
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, accounts-qt
, cmake
, libapparmor
, lomiri-system-settings-online-accounts
, pkg-config
, qtbase
, qtdeclarative
, signond
}:

stdenv.mkDerivation rec {
  pname = "lomiri-online-accounts";
  version = "unstable-2022-12-09";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "c35f408b38910935e0e31effc437566631345094";
    hash = "sha256-oolN5VeHP4iTcRvOhSWGKxvTubEcFmzcm3Woo7OIhGg=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    substituteInPlace src/lib/Lomiri/OnlineAccounts.2/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" '${placeholder "out"}/${qtbase.qtQmlPrefix}'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    accounts-qt
    libapparmor
    lomiri-system-settings-online-accounts
    qtbase
    qtdeclarative
    signond
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DENABLE_DOC=OFF"
  ];

  # TODO
  doCheck = false;
}
