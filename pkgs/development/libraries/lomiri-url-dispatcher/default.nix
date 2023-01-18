{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, intltool
, cmake-extras
, dbus-test-runner
, glib
, gtest
, json-glib
, libapparmor
, lomiri-app-launch
, mir_1
, python3
, sqlite
, systemd
, libxkbcommon
}:

stdenv.mkDerivation rec {
  pname = "lomiri-url-dispatcher";
  version = "0.1.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-url-dispatcher";
    rev = version;
    hash = "sha256-RsTmcrnd+7gdkxi43lSWFCniAGWKS+Rau0jUHAJpXmE=";
  };

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace "\''${SYSTEMD_USER_UNIT_DIR}" "\''${CMAKE_INSTALL_LIBDIR}/systemd/user"

    substituteInPlace tests/url_dispatcher_testability/CMakeLists.txt \
      --replace "\''${PYTHON_PACKAGE_DIR}" "$out/${python3.sitePackages}"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    glib # for gdbus-codegen
    intltool
    python3
  ];

  buildInputs = [
    cmake-extras
    dbus-test-runner
    glib
    gtest
    json-glib
    libapparmor
    lomiri-app-launch
    mir_1
    sqlite
    systemd
    libxkbcommon
  ];

  cmakeFlags = [
    "-DLOCAL_INSTALL=ON"
  ];
}
