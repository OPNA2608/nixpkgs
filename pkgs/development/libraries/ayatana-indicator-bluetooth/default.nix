{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, glib
, gobject-introspection
, intltool
, libayatana-common
, pkg-config
, systemd
, vala
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ayatana-indicator-bluetooth";
  version = "22.9.1";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-bluetooth";
    rev = version;
    hash = "sha256-sEx8EHephxuJJXzCW4zjuVaGOt+5HOr4Nw7teoE4Qs4=";
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
    libayatana-common
    vala
    wrapGAppsHook
  ];

  buildInputs = [
    cmake-extras
    glib
    gobject-introspection
    libayatana-common
    systemd
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
}
