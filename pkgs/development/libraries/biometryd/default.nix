{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, boost
, dbus
, dbus-cpp
, libapparmor
, process-cpp
, sqlite
, qtbase
, qtdeclarative
, gtest
, properties-cpp
, libelf
}:

stdenv.mkDerivation rec {
  pname = "biometryd";
  version = "0.3.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-b095rsQnd63Ziqe+rn3ROo4LGXZxZ3Sa6h3apzCuyCs=";
  };

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}" \
      --replace '/lib' "\''${CMAKE_INSTALL_LIBDIR}"
    substituteInPlace src/biometry/qml/Biometryd/CMakeLists.txt \
      --replace 'qt5/qml' 'qt-${qtbase.version}/qml'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    boost
    dbus
    dbus-cpp
    libapparmor
    process-cpp
    properties-cpp
    sqlite
    qtbase
    qtdeclarative
    libelf
  ];

  checkInputs = [
    gtest
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    # TODO C++ error message screen vomit
    "-DENABLE_WERROR=OFF"
  ];

  preBuild = ''
    # Generating plugins.qmltypes
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/lib/qt-${qtbase.version}/plugins
  '';

  # TODO
  doCheck = false;
}
