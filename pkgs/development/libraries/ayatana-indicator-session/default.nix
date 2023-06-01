{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, cmake
, cmake-extras
, dbus
, glib
, gsettings-desktop-schemas
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

  patches = [
    # Full Lomiri integration, removes Unity7 support (which we don't have packaged)
    # Remove when version > 22.9.0
    (fetchpatch {
      url = "https://github.com/AyatanaIndicators/ayatana-indicator-session/commit/8c4df6215a986695edc6c6530f6d6388ea9640d5.patch";
      hash = "sha256-/9ibFQYtWGXAjgf3lcZvZ3QYJf9KTnlf9dluwzWo+hI=";
    })
  ];

  postPatch = ''
    # fetchpatch doesn't handle renames
    # Remove when version > 22.9.0
    mv -v src/backend-dbus/{org.ayatana.Desktop,com.lomiri.Shell}.Session.xml
    mv -v tests/backend-dbus/mock-{unity,lomiri}-session.cc
    mv -v tests/backend-dbus/mock-{unity,lomiri}-session.h

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
    gsettings-desktop-schemas
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

  meta = with lib; {
    description = "Ayatana Indicator showing session management, status and user switching";
    longDescription = ''
      This Ayatana Indicator is designed to be placed on the right side of a
      panel and give the user easy control for
      - changing their instant message status,
      - switching to another user,
      - starting a guest session, or
      - controlling the status of their own session.
    '';
    homepage = "https://github.com/AyatanaIndicators/ayatana-indicator-session";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
