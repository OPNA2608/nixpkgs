{ stdenv
, lib
, fetchFromGitHub
, gitUpdater
, nixosTests
, testers
, cmake
, dbus
, dbus-test-runner
, glib
, gtest
, intltool
, libayatana-common
, libnotify
, librda
, lomiri
, pkg-config
, python3
, systemd
, wrapGAppsHook
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ayatana-indicator-power";
  version = "23.10.0";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-power";
    rev = finalAttrs.version;
    hash = "sha256-U4UYQV1GPhSMj/Y/yyDsYDXFI4ggcZyCcGeAs9+rLlU=";
  };

  postPatch = ''
    # Queries systemd user unit dir via pkg_get_variable, can't override prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"' \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}"

    # Bad hardcoded path, for codegen to a Lomiri interface
    substituteInPlace src/CMakeLists.txt \
      --replace '/usr/share/accountsservice' '${lomiri.lomiri-schemas}/share/accountsservice'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    intltool
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    glib
    libayatana-common
    libnotify
    librda
    systemd
  ] ++ (with lomiri; [
    cmake-extras
    lomiri-schemas
    lomiri-sounds
  ]);

  nativeCheckInputs = [
    dbus
    (python3.withPackages (ps: with ps; [
      python-dbusmock
    ]))
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

  passthru = {
    ayatana-indicators = [ "ayatana-indicator-power" ];
    tests.vm = nixosTests.ayatana-indicators;
    updateScript = gitUpdater { };
  };

  meta = with lib; {
    description = "Ayatana Indicator showing power state";
    longDescription = ''
      This Ayatana Indicator displays current power management information and
      gives the user a way to access power management preferences.
    '';
    homepage = "https://github.com/AyatanaIndicators/ayatana-indicator-power";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
})
