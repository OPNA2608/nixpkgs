{ stdenv
, lib
, fetchFromGitHub
, ayatana-indicator-messages
, cmake
, cmake-extras
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
, lomiri-schemas
, lomiri-sounds
, lomiri-url-dispatcher
, pkg-config
, properties-cpp
, python3
, systemd
, wrapGAppsHook
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    python-dbusmock
  ]);
in
stdenv.mkDerivation rec {
  pname = "ayatana-indicator-datetime";
  version = "22.9.1";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-datetime";
    rev = version;
    hash = "sha256-ovg54yQfxbl6IjXgCHfIfSx0zE68Rkc5+8IL9CdWqZM=";
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
    glib # for schema hook
    intltool
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    ayatana-indicator-messages
    cmake-extras
    evolution-data-server
    glib
    gst_all_1.gstreamer
    libaccounts-glib
    libayatana-common
    libical
    libnotify
    libuuid
    lomiri-schemas
    lomiri-sounds
    lomiri-url-dispatcher
    properties-cpp
    systemd
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
    "-DENABLE_LOMIRI_FEATURES=ON"
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
}
