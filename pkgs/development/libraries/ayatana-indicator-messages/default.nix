{ stdenv
, lib
, fetchFromGitHub
# This should maybe be the lomiri-specific accountsservice?
, accountsservice
, cmake
, cmake-extras
, docbook_xsl
, docbook_xml_dtd_45
, glib
, gobject-introspection
, gtk-doc
, intltool
, pkg-config
, systemd
, vala
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ayatana-indicator-messages";
  version = "22.9.0";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "ayatana-indicator-messages";
    rev = version;
    hash = "sha256-7+Kq9LTGa87a6H3VNfWsaYicWKhTnK/G9tI/C8t8/8g=";
  };

  postPatch = ''
    # Uses pkg_get_variable, cannot substitute prefix with that
    substituteInPlace data/CMakeLists.txt \
      --replace "\''${SYSTEMD_USER_DIR}" "$out/lib/systemd/user"

    # Bad concatenation
    substituteInPlace libmessaging-menu/messaging-menu.pc.in \
      --replace "\''${exec_prefix}/@CMAKE_INSTALL_LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace "\''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@" '@CMAKE_INSTALL_FULL_INCLUDEDIR@'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    docbook_xsl
    docbook_xml_dtd_45
    glib # For glib-compile-schemas
    gtk-doc
    intltool
    pkg-config
    vala
    wrapGAppsHook
  ];

  buildInputs = [
    accountsservice
    cmake-extras
    glib
    gobject-introspection
    systemd
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  makeFlags = [
    # ld: ...: undefined reference to symbol 'qsort@@GLIBC_2.2.5'
    "LD=${stdenv.cc.targetPrefix}cc"
  ];

  preInstall = ''
    # gtkdoc-mkhtml generates images without write permissions, errors out during install
    chmod +w doc/reference/html/*
  '';

  meta = with lib; {
    description = "Ayatana Indicator Messages Applet";
    longDescription = ''
      The -messages Ayatana System Indicator is the messages menu indicator for Unity7, MATE and Lomiri (optionally for
      others, e.g. XFCE, LXDE).
    '';
    homepage = "https://github.com/AyatanaIndicators/ayatana-indicator-messages";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
