{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, dbus
, glib
, gtest
, intltool
, libayatana-common
, pkg-config
, systemd
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ayatana-indicator-session";
  version = "22.9.0";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-session";
    rev = version;
    hash = "sha256-nQukI0ClG5DoallzMvODRPUZzar5rTBxwcAaEMvdVYo=";
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
    cmake-extras
    glib
    libayatana-common
    systemd
  ];

  nativeCheckInputs = [
    dbus
  ];

  checkInputs = [
    gtest
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
}
