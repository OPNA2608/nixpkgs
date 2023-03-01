# TODO
# - AA_EXEC_PATH apparmor path for by-hand apparmor usage (needed?)
# - docs
# - test
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, pkg-config
, gobject-introspection
, apparmor-bin-utils
, glib
, json-glib
, lomiri-click
, zeitgeist
, dbus
, dbus-test-runner
, lttng-ust
, curl
, lomiri-api
, gtest
, libxkbcommon
, properties-cpp
, systemd
}:

stdenv.mkDerivation rec {
  pname = "lomiri-app-launch";
  version = "0.1.6";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-app-launch";
    rev = version;
    hash = "sha256-952r6OsqthQJ7ACHsc3MsW+aTQnNpJJT2sMT9CGj1Y0=";
  };

  postPatch = ''
    # used pkg_get_variable, cannot replace prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_UNIT_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    curl
    dbus
    dbus-test-runner
    gobject-introspection
    gtest
    json-glib
    lomiri-api
    lomiri-click
    lttng-ust
    properties-cpp
    libxkbcommon
    zeitgeist
    systemd
  ];

  cmakeFlags = [
    "-DENABLE_MIRCLIENT=OFF"
    "-DLOMIRI_APP_LAUNCH_ARCH=${stdenv.hostPlatform.config}"
  ];
}
