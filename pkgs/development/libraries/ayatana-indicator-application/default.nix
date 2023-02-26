{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, dbus-glib
, gdk-pixbuf
, glib
, gtk3
, intltool
, libayatana-appindicator
, libayatana-indicator
, libdbusmenu-gtk3
, pkg-config
, systemd
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ayatana-indicator-application";
  version = "22.2.0";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-application";
    rev = version;
    hash = "sha256-sijDi49nkzPPgj7bwjdkllHPS9gTXLJWO+Yc20TT9l4=";
  };

  postPatch = ''
    # Queries systemd user unit dir via pkg_get_variable, can't override prefix
    substituteInPlace data/CMakeLists.txt \
      --replace 'DESTINATION "''${SYSTEMD_USER_DIR}"' 'DESTINATION "${placeholder "out"}/lib/systemd/user"' \
      --replace '/etc' "\''${CMAKE_INSTALL_SYSCONFDIR}"

    # Queries ayatana indicator dir via pkg_get_variable, can't override prefix
    # TODO This seems like a weird path, is this broken in libayatana-indicator?
    substituteInPlace src/CMakeLists.txt \
      --replace 'DESTINATION "''${indicatordir}"' 'DESTINATION "${placeholder "out"}/lib/ayatana-indicators3/7/"'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    glib # glib-genmarshal
    intltool
    pkg-config
    wrapGAppsHook
  ];

  buildInputs = [
    cmake-extras
    dbus-glib
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
    libayatana-indicator
    libdbusmenu-gtk3
    systemd
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];
}
