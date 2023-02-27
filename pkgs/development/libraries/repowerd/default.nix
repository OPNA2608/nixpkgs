{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, cmake-extras
, dbus
, deviceinfo
, glib
, gtest
, pkg-config
, systemd
}:

stdenv.mkDerivation rec {
  pname = "repowerd";
  version = "2022.01";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-9SudCqBiWpgFjI+rJflyux3Yw6xdRpIc2RfigkzJsvI=";
  };

  patches = [
    # Replaces libandroid-properties with deviceinfo
    # Remove when version > 2022.01
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/repowerd/-/commit/e963bc478700cd13733fb61385bc9cbc15dad93e.patch";
      hash = "sha256-vOsUlIz7nK22VlNzJbYKFnnGjQBIZv7dp5pzlUAH0SU=";
    })
    # Fixes GMock dependency for tests
    # Remove when version > 2022.01
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/repowerd/-/commit/4d1a97e3bc7c4255b242e0c487085bfd2e889af1.patch";
      hash = "sha256-v+0Tt2rFME+QrEoof1j3Y4xoClzKxrD7RF/bZ5uNF18=";
    })
    # Install systemd service via CMake
    # Remove when version > 2022.01
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/repowerd/-/commit/5d893cb82967edfc0667a1bc6ee0258e3a4aadfd.patch";
      hash = "sha256-HBandrQgMZqKX2SgXOldeCCUAIK6zwqc2jsOjd/3IBc=";
    })
  ];

  prePatch = ''
    # fetchpatch cannot handle renames
    # Remove these when version > 2022.01
    mv -v tests/adapter-tests/fake_android_properties.h tests/adapter-tests/fake_device_info.h
    mv -v debian/repowerd.service data/repowerd.service
  '';

  postPatch = ''
    # Help tests access the test dbus session
    substituteInPlace tests/adapter-tests/dbus_bus.cpp \
      --replace 'dbus-daemon --session' 'dbus-daemon --config-file=${dbus}/share/dbus-1/session.conf'

    # Uses pkg_get_variable to get systemd system unit install dir, cannot replace prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_SYSTEM_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/system"'

    # Bad hardcoded path
    substituteInPlace data/repowerd.service \
      --replace '/usr' "$out"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    deviceinfo
    glib
    systemd
  ];

  nativeCheckInputs = [
    dbus
  ];

  checkInputs = [
    gtest
  ];

  cmakeFlags = [
    "-DREPOWERD_BUILD_TESTS=${lib.boolToString doCheck}"
    "-DREPOWERD_ENABLE_HYBRIS=OFF"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  checkPhase = ''
    runHook preCheck

    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- make test

    runHook postCheck
  '';
}
