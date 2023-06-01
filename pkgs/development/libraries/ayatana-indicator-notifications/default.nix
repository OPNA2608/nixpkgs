{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, glib
, intltool
, pkg-config
, systemd
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ayatana-indicator-notifications";
  version = "22.9.0";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-notifications";
    rev = version;
    hash = "sha256-uP0fnTjMD6CceBRdS6djjR7jJ/cvReU/wYX6mFsj7Wc=";
  };

  postPatch = ''
    # Queries systemd user unit dir via pkg_get_variable, can't override prefix
    # Bad path concatenation
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"' \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}" \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${CMAKE_INSTALL_DATADIR}" "\''${CMAKE_INSTALL_DATADIR}"
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
    systemd
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  meta = with lib; {
    description = "Ayatana Indicator for viewing recent notifications";
    longDescription = ''
      An Ayatana Indicator applet to display recent notifications sent to a
      notification daemon such as notify-osd.

      Using dconf-editor, you can blacklist certain notifications, so that
      they are not shown anymore by the notifications indicator.
    '';
    homepage = "https://github.com/AyatanaIndicators/ayatana-indicator-notifications";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
