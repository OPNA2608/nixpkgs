{ stdenv
, lib
, fetchFromGitHub
, gitUpdater
, nixosTests
, cmake
, dbus
, glib
, gnome
, gsettings-desktop-schemas
, gtest
, intltool
, libayatana-common
, librda
, lomiri
, mate
, pkg-config
, systemd
, wrapGAppsHook
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ayatana-indicator-session";
  version = "23.10.0";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-session";
    rev = finalAttrs.version;
    hash = "sha256-oYdA9fPJvFnxuGOWh8nFCsMdoKzcX7rPlZb+E+5DF6s=";
  };

  postPatch = ''
    # Queries systemd user unit dir via pkg_get_variable, can't override prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"' \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    intltool
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    lomiri.cmake-extras
    glib
    gsettings-desktop-schemas
    libayatana-common
    librda
    systemd

    # TODO this bloats the closure size alot, only so the indicator doesn't crash.
    # is there a better way to give it access to DE-specific schemas as needed?
    # https://github.com/AyatanaIndicators/ayatana-indicator-session/blob/88846bad7ee0aa8e0bb122816d06f9bc887eb464/src/service.c#L1387-L1413
    gnome.gnome-settings-daemon
    mate.mate-settings-daemon
  ];

  nativeCheckInputs = [
    dbus
  ];

  checkInputs = [
    gtest
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString finalAttrs.doCheck}"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  # Currently broken: https://github.com/AyatanaIndicators/ayatana-indicator-session/issues/90
  doCheck = false;

  # DBus communication
  enableParallelChecking = false;

  passthru = {
    ayatana-indicators = [ "ayatana-indicator-session" ];
    tests.vm = nixosTests.ayatana-indicators;
    updateScript = gitUpdater { };
  };

  meta = with lib; {
    description = "Ayatana Indicator showing session management, status and user switching";
    longDescription = ''
      This Ayatana Indicator is designed to be placed on the right side of a
      panel and give the user easy control for
      - changing their instant message status,
      - switching to another user,
      - starting a guest session, or
      - controlling the status of their own session.
    '';
    homepage = "https://github.com/AyatanaIndicators/ayatana-indicator-session";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
})
