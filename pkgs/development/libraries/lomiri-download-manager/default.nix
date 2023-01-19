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
  version = "0.1.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-wGvzPSToPTfoR3OdthjxkgwPpvGvBkNmo/DshZ8z+D0=";
  };

  postPatch = ''
    substituteInPlace src/{uploads,downloads}/daemon/CMakeLists.txt \
      --replace '/usr/share' "\''${CMAKE_INSTALL_DATADIR}/share" \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}"

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
    mv $out/lib{exec,}/pkgconfig
  '';
}
