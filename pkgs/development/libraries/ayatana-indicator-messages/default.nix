{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, pkg-config
, accountsservice
, glib
, gobject-introspection
, vala
, systemd
, intltool
, gtk-doc
, docbook_xsl
, docbook_xml_dtd_45
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
    pkg-config
    vala
    intltool
    gtk-doc
    docbook_xsl
    docbook_xml_dtd_45
    glib # For glib-compile-schemas
    wrapGAppsHook
  ];

  buildInputs = [
    cmake-extras
    accountsservice
    glib
    gobject-introspection
    systemd
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
  ];

  makeFlags = [
    "LD=${stdenv.cc.targetPrefix}cc"
  ];

  preInstall = ''
    # gtkdoc-mkhtml generates images without write permissions, errors out during install
    chmod +w doc/reference/html/*
  '';
}
