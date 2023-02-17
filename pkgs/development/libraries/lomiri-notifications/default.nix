{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, qtdeclarative
, lomiri-api
, qtbase
, libqtdbustest
}:

stdenv.mkDerivation rec {
  pname = "lomiri-notifications";
  version = "1.3.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-EGslfTgfADrmVGhNLG7HWqcDKhu52H/r41j7fxoliko=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace 'qt5/qml' 'qt-${qtbase.version}/qml'
    substituteInPlace src/CMakeLists.txt \
      --replace '--variable=plugindir' '--define-variable=prefix=${placeholder "out"} --variable=plugindir'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    libqtdbustest
    lomiri-api
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;
}
