{ stdenv
, lib
, fetchFromGitHub
, accountsservice
, cmake
, cmake-extras
, glib
, intltool
, libayatana-common
, libX11
, libxkbcommon
, libxklavier
, pkg-config
, systemd
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ayatana-indicator-keyboard";
  version = "22.9.1";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-keyboard";
    rev = version;
    hash = "sha256-fZFONSfirMsCJv5u37gXJKkY4h75+8H1ObGQy6elc0A=";
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
    accountsservice
    cmake-extras
    glib
    libayatana-common
    libX11
    libxkbcommon
    libxklavier
    systemd
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "$out/lib"
    )
  '';

  meta = with lib; {
    description = "Ayatana Indicator Keyboard Applet";
    longDescription = ''
      A keyboard indicator, which should show as an
      icon in the top panel of indicator-aware desktop environments.

      It can be used to switch key layouts or languages, and helps the user
      identifying which layouts are currently in use.
    '';
    homepage = "https://github.com/AyatanaIndicators/ayatana-indicator-keyboard";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
