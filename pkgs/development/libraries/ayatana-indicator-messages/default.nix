{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
# This should maybe be the lomiri-specific accountsservice?
, accountsservice
, cmake
, cmake-extras
, dbus-test-runner
, docbook_xsl
, docbook_xml_dtd_45
, glib
, gobject-introspection
, gtest
, gtk-doc
, intltool
, pkg-config
, python3
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

  patches = [
    (fetchpatch {
      url = "https://github.com/AyatanaIndicators/ayatana-indicator-messages/commit/720d830acdfdd836f4be8eeefae17f22c77459cf.patch";
      hash = "sha256-iAjPqB3CNzdzVG7SuPevsNvDkzJewueCjMQbYEBEKak=";
    })
    (fetchpatch {
      url = "https://github.com/AyatanaIndicators/ayatana-indicator-messages/commit/19b3d98bd069ad3a3b15cfa3a96af704fd1ab6dc.patch";
      hash = "sha256-zacT31gbxUTmmQ1Z+aE5MMj1Dy+4bipsclRQEB4e5J0=";
    })
  ];

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

  nativeCheckInputs = [
    (python3.withPackages (ps: with ps; [
      pygobject3
      python-dbusmock
    ]))
  ];

  checkInputs = [
    dbus-test-runner
    gtest
  ];

  cmakeFlags = [
    "-DGSETTINGS_LOCALINSTALL=ON"
    "-DGSETTINGS_COMPILE=ON"
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  makeFlags = [
    # ld: ...: undefined reference to symbol 'qsort@@GLIBC_2.2.5'
    "LD=${stdenv.cc.targetPrefix}cc"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  preCheck = ''
    # test-client imports gir, whose solib entry points to final store location
    install -Dm644 libmessaging-menu/libmessaging-menu.so.0.0.0 $out/lib/libmessaging-menu.so.0
  '';

  postCheck = ''
    # remove the above solib-installation, let it be done properly
    rm -r $out
  '';

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
