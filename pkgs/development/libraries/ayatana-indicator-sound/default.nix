{ stdenv
, lib
, fetchFromGitHub
, accountsservice
, cmake
, cmake-extras
, dbus
, dbus-test-runner
, glib
, gmenuharness
, gobject-introspection
, gtest
, intltool
, libayatana-common
, libgee
, libnotify
, libpulseaudio
, libqtdbusmock
, libqtdbustest
, libxml2
, lomiri-api
, lomiri-schemas
, pkg-config
, python3
, qtbase
, systemd
, vala
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ayatana-indicator-sound";
  version = "22.9.2";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-sound";
    rev = version;
    hash = "sha256-4oBNmIHhmey3YMcB1af1Av72+ZDExiuQyCMnIkPJdMY=";
  };

  postPatch = ''
    # Queries systemd user unit dir via pkg_get_variable, can't override prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"' \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}"

    # Bad hardcoded path
    substituteInPlace src/CMakeLists.txt \
      --replace '/usr/share/gir-1.0/AccountsService-1.0.gir' '${lib.getDev accountsservice}/share/gir-1.0/AccountsService-1.0.gir'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gobject-introspection
    intltool
    libpulseaudio # vala files(?)
    pkg-config
    vala
    wrapGAppsHook
  ];

  buildInputs = [
    accountsservice
    cmake-extras
    glib
    gobject-introspection
    libayatana-common
    libgee
    libnotify
    libpulseaudio
    libxml2
    lomiri-api
    lomiri-schemas
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
    gmenuharness
    gtest
    libqtdbusmock
    libqtdbustest
    qtbase
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DENABLE_LOMIRI_FEATURES=ON"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  dontWrapQtApps = true;

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  meta = with lib; {
    description = "Ayatana Indicator for managing system sound";
    longDescription = ''
      Ayatana Indicator Sound that provides easy control of the PulseAudio
      sound daemon.
    '';
    homepage = "https://github.com/AyatanaIndicators/ayatana-indicator-sound";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
