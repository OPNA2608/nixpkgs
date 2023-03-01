# TODO
# - tests
# - meta
# - see other TODO
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
      --replace '/usr/share' "\''${CMAKE_INSTALL_DATADIR}/share" \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}" \
      --replace '/usr/lib' "\''${CMAKE_INSTALL_LIBDIR}"

    # Deprecation warnings on Qt 5.15
    # https://gitlab.com/ubports/development/core/lomiri-download-manager/-/issues/1
    substituteInPlace CMakeLists.txt \
      --replace "-Werror" ""
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
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

  dontWrapQtApps = true;

  postInstall = ''
    # TODO fix these before installing instead
    mv $out/lib{exec,}/pkgconfig
    mv $out/lib/qt{5,-${qtbase.version}}
    mv $out/share/share/dbus-1/* $out/share/dbus-1/
  '';
}
