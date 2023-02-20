{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, pkg-config
, intltool
, cmake-extras
, dbus
, dbus-test-runner
, glib
, gtest
, json-glib
, libapparmor
, lomiri-app-launch
, python3
, sqlite
, systemd
, libxkbcommon
}:

stdenv.mkDerivation rec {
  pname = "lomiri-url-dispatcher";
  version = "0.1.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-url-dispatcher";
    rev = version;
    hash = "sha256-dOzoGH1BxCaMpWjMInwVS0lMNgxGgLzOB8IBqp9dcls=";
  };

  patches = [
    # Fix case-sensitivity in tests
    # Remove when https://gitlab.com/ubports/development/core/lomiri-url-dispatcher/-/merge_requests/8 merged & in release
    (fetchpatch {
      url = "https://gitlab.com/sunweaver/lomiri-url-dispatcher/-/commit/ebdd31b9640ca243e90bc7b8aca7951085998bd8.patch";
      hash = "sha256-g4EohB3oDcWK4x62/3r/g6CFxqb7/rdK51+E/Fji1Do=";
    })
  ];

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace "\''${SYSTEMD_USER_UNIT_DIR}" "\''${CMAKE_INSTALL_LIBDIR}/systemd/user"

    substituteInPlace tests/url_dispatcher_testability/CMakeLists.txt \
      --replace "\''${PYTHON_PACKAGE_DIR}" "$out/${python3.sitePackages}"
  '' + lib.optionalString doCheck ''
    patchShebangs tests/test-sql.sh
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
    sqlite
    systemd
    libxkbcommon
  ];

  nativeCheckInputs = [
    dbus
    (python3.withPackages (ps: with ps; [
      python-dbusmock
    ]))
    sqlite
  ];

  cmakeFlags = [
    "-DLOCAL_INSTALL=ON"
    "-Denable_mirclient=OFF"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  # Tests work with an sqlite db, cannot handle >1 test at the same time
  enableParallelChecking = false;
}
