{ stdenv
, lib
, fetchFromGitLab
, cmake
, gettext
, pkg-config
, qtdeclarative
, cmake-extras
, dbus
, glib
, libsecret
, lomiri-api
, lomiri-url-dispatcher
, networkmanager
, ofono
, qtbase
, libqofono
, intltool
, gtest
, libqtdbusmock
, libqtdbustest
, gmenuharness
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-indicator-network";
  version = "1.0.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-JrxJsdLd35coEJ0nYcYtPRQONLfKciNmBbLqXrEaOX0=";
  };

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace '/usr/lib/systemd/user' "$out/lib/systemd/user" \
      --replace '/etc/xdg/autostart' "$out/etc/xdg/autostart"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    intltool
    pkg-config
    qtdeclarative
    # Needed? works fine without, but shouldn't be able to find its schemas
    wrapGAppsHook
  ];

  buildInputs = [
    cmake-extras
    dbus
    glib
    gmenuharness
    gtest
    libqofono
    libqtdbusmock
    libqtdbustest
    libsecret
    lomiri-api
    lomiri-url-dispatcher
    networkmanager
    ofono
    qtbase
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];
}
