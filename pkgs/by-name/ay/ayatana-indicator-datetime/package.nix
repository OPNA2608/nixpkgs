{ stdenv
, lib
, fetchFromGitHub
, gitUpdater
, nixosTests
, ayatana-indicator-messages
, cmake
, dbus
, dbus-test-runner
, evolution-data-server
, glib
, gst_all_1
, gtest
, intltool
, libaccounts-glib
, libayatana-common
, libical
, libnotify
, libuuid
, lomiri
, pkg-config
, properties-cpp
, python3
, systemd
, tzdata
, wrapGAppsHook
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ayatana-indicator-datetime";
  version = "23.10.0";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-datetime";
    rev = finalAttrs.version;
    hash = "sha256-Ba7Csk7HzhmXzzm4SiwTXHBDKc42wIKX+MHDRpHgK+w=";
  };

  postPatch = ''
    # Queries systemd user unit dir via pkg_get_variable, can't override prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"' \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}"

    # Bad hardcoded path
    substituteInPlace src/CMakeLists.txt \
      --replace '/usr/share/accountsservice' '${lomiri.lomiri-schemas}/share/accountsservice'

    # Disable evolution-data-server tests. They have been silently failing on upstream CI for awhile,
    # recent release has fixed the silentness but left the tests broken.
    # https://github.com/AyatanaIndicators/ayatana-indicator-datetime/commit/3e65062b5bb0957b5bb683ff04cb658d9d530477
    substituteInPlace tests/CMakeLists.txt \
      --replace 'add_eds_ics_test_by_name(' '#add_eds_ics_test_by_name('
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    glib # for schema hook
    intltool
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    ayatana-indicator-messages
    evolution-data-server
    glib
    gst_all_1.gstreamer
    libaccounts-glib
    libayatana-common
    libical
    libnotify
    libuuid
    properties-cpp
    systemd
  ] ++ (with lomiri; [
    cmake-extras
    lomiri-schemas
    lomiri-sounds
    lomiri-url-dispatcher
  ]);

  nativeCheckInputs = [
    dbus
    (python3.withPackages (ps: with ps; [
      python-dbusmock
    ]))
    tzdata
  ];

  checkInputs = [
    dbus-test-runner
    gtest
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString finalAttrs.doCheck}"
    "-DENABLE_LOMIRI_FEATURES=ON"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  enableParallelChecking = false;

  preCheck = ''
    export XDG_DATA_DIRS=${libayatana-common}/share/gsettings-schemas/${libayatana-common.name}
  '';

  passthru = {
    ayatana-indicators = [
      "ayatana-indicator-datetime"
    ];
    tests = {
      inherit (nixosTests) ayatana-indicators ayatana-indicators-with-lomiri;
    };
    updateScript = gitUpdater { };
  };

  meta = with lib; {
    description = "Ayatana Indicator providing clock and calendar";
    longDescription = ''
      This Ayatana Indicator provides a combined calendar, clock, alarm and
      event management tool.
    '';
    homepage = "https://github.com/AyatanaIndicators/ayatana-indicator-datetime";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
})
