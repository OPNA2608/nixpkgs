# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, boost
, cmake-extras
, glog
, gtest
, lomiri-api
, qtbase
, qtdeclarative
, dbus-test-runner
, xvfb-run
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-download-manager";
  version = "0.1.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-a9C+hactBMHMr31E+ImKDPgpzxajy1klkjDcSEkPHqI=";
  };

  postPatch = ''
    substituteInPlace src/{uploads,downloads}/daemon/CMakeLists.txt \
      --replace '/usr/share' "\''${CMAKE_INSTALL_DATADIR}" \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}" \
      --replace '/usr/lib' "\''${CMAKE_INSTALL_LIBDIR}"

    substituteInPlace src/{common/public,uploads/common,downloads/{client,common}}/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBEXECDIR}/pkgconfig" "\''${CMAKE_INSTALL_LIBDIR}/pkgconfig"

    substituteInPlace src/{uploads,downloads}/daemon/*.service \
      --replace '/usr/bin' '${placeholder "out"}/bin'

    substituteInPlace CMakeLists.txt \
      --replace 'qt5/qml' 'qt-${qtbase.version}/qml'

    # Deprecation warnings on Qt 5.15
    # https://gitlab.com/ubports/development/core/lomiri-download-manager/-/issues/1
    substituteInPlace CMakeLists.txt \
      --replace "-Werror" ""
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    boost
    cmake-extras
    glog
    gtest
    lomiri-api
    qtbase
    qtdeclarative
  ];

  nativeCheckInputs = [
    dbus-test-runner
    xvfb-run
  ];
}
