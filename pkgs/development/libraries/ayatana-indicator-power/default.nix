{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, dbus
, dbus-test-runner
, glib
, gtest
, intltool
, libayatana-common
, libnotify
, lomiri-schemas
, lomiri-sounds
, pkg-config
, python3
, systemd
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ayatana-indicator-power";
  version = "22.9.4";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-power";
    rev = version;
    hash = "sha256-7pmLtxmgks19ZqIM46TlrDGSOOBjGK3MRiCHDnjd34U=";
  };

  postPatch = ''
    # Queries systemd user unit dir via pkg_get_variable, can't override prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"' \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}"

    # Bad hardcoded path
    substituteInPlace src/CMakeLists.txt \
      --replace '/usr/share/accountsservice' '${lomiri-schemas}/share/accountsservice'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    intltool
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    cmake-extras
    glib
    libayatana-common
    libnotify
    lomiri-schemas
    lomiri-sounds
    systemd
  ];

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
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DENABLE_LOMIRI_FEATURES=ON"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

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
}
