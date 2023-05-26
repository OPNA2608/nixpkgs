# TODO
# - AA_EXEC_PATH apparmor path for by-hand apparmor usage (needed?)
# - meta
{ stdenv
, lib
, fetchFromGitLab
#, apparmor-bin-utils
, cmake
, cmake-extras
, curl
, dbus
, dbus-test-runner
#, glib
, gobject-introspection
, gtest
, json-glib
, libxkbcommon
, lomiri-api
, lttng-ust
, pkg-config
, properties-cpp
, python3
, systemd
, ubports-click
, zeitgeist
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    python-dbusmock
  ]);
in
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
    patchShebangs tests/{desktop-hook-test.sh.in,repeat-until-pass.sh}

    # used pkg_get_variable, cannot replace prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_UNIT_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"'

    substituteInPlace tests/jobs-systemd.cpp \
      --replace '^(/usr)?' '^(/nix/store/\\w+-bash-.+)?'
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
    gobject-introspection
    json-glib
    libxkbcommon
    lomiri-api
    lttng-ust
    properties-cpp
    systemd
    ubports-click
    zeitgeist
  ];

  nativeCheckInputs = [
    dbus
    pythonEnv
  ];

  checkInputs = [
    dbus-test-runner
    gtest
  ];

  cmakeFlags = [
    "-DENABLE_MIRCLIENT=OFF"
    "-DLOMIRI_APP_LAUNCH_ARCH=${stdenv.hostPlatform.config}"
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  meta = with lib; {
    description = "System and associated utilities to launch applications in a standard and confined way";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-app-launch";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
