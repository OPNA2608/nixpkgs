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
}:

stdenv.mkDerivation rec {
  pname = "lomiri-indicator-network";
  version = "unstable-2023-01-17";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "1adddec1163e9f5f21ceab71cc0410fd764884a3";
    hash = "sha256-JT9K3h0pBstmXVO74YQZlrHaQ7rNCR2Z7ypJQnTIjDk=";
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
  ];
}
