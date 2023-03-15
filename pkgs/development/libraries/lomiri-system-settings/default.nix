# TODO
# - tests
# - meta
# - some of the plugin detection needs to be rewritten to check /run/current-system/sw
#   i.e. whether battery entry should be displayed:
#   "visible-if-file-exists": "/etc/dbus-1/system.d/com.lomiri.Repowerd.conf"
# - Debian patches:
#   - make compatible with regular accountsservice?
#   - patch to use regular maliit-keyboard instead?
{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, cmake
, pkg-config
, qtbase
, qtdeclarative
, glib
, geonames
, ubports-click
, gettext
, intltool
, libqtdbustest
, libqtdbusmock
, accountsservice
, gsettings-qt
, gnome-desktop
, gtk3
, upower
, icu
, cmake-extras
, xvfb-run
, dbus
, lomiri-ui-toolkit
, lomiri-settings-components
, qtgraphicaleffects
, python3
, wrapQtAppsHook
, qtfeedback
, qmenumodel
, qtsystems
, lomiri-indicator-network
, libqofono
, wrapGAppsHook
, lomiri-schemas
, ayatana-indicator-datetime
, content-hub
, lomiri-keyboard
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    python-dbusmock
  ]);
in
stdenv.mkDerivation rec {
  pname = "lomiri-system-settings";
  version = "1.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-system-settings";
    rev = version;
    hash = "sha256-7XJ2mvqcI+tBEpT6tAVJrcEzyDhiY1ttB1X1e24kmd8=";
  };

  patches = [
    # Fix tests on newer python-dbusmock
    # https://gitlab.com/ubports/development/core/lomiri-system-settings/-/merge_requests/354
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/lomiri-system-settings/-/commit/b6c7a807daa85ab8a28b80564a3e29d50946145a.patch";
      hash = "sha256-CrtisskULD7zFMJMe0Ebusgxso6WPAN3hk8egxElnK8=";
    })
    (fetchpatch {
      url = "https://gitlab.com/ubports/development/core/lomiri-system-settings/-/commit/8698bf41f21456a866baa52849a7fd200470e1c9.patch";
      hash = "sha256-cEldfwQl2Uuk80Myaf9w4aOmHGDphK20I7GrhuotNrU=";
    })
    # Make it work with accountsservice without Ubuntu-specific changes
    # https://gitlab.com/ubports/development/core/lomiri-system-settings/-/issues/341
    (fetchpatch {
      name = "2001-lomiri-system-settings-disable-current-language-switching.patch";
      url = "https://sources.debian.org/data/main/l/lomiri-system-settings/1.0.1-2/debian/patches/2001_disable-current-language-switching.patch";
      hash = "sha256-ZOFYwxS8s6+qMFw8xDCBv3nLBOBm86m9d/VhbpOjamY=";
    })
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace '/qt5/qml' '/qt-${qtbase.version}/qml' \
      --replace "\''${CMAKE_INSTALL_PREFIX}/\''${LIBDIR}" "\''${CMAKE_INSTALL_LIBDIR}"

    substituteInPlace lib/LomiriSystemSettings/LomiriSystemSettings.pc.in \
      --replace "\''${prefix}/@LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    gettext
    glib # glib-compile-schemas
    intltool
    wrapGAppsHook
    wrapQtAppsHook
  ];

  buildInputs = [
    accountsservice
    cmake-extras
    glib
    geonames
    gnome-desktop
    gtk3
    gsettings-qt
    icu
    libqtdbustest
    libqtdbusmock
    ubports-click
    qtbase
    qtdeclarative
    upower
    lomiri-ui-toolkit
    lomiri-settings-components

    # QML
    qtfeedback # lomiri-ui-toolkit
    qtgraphicaleffects # lomiri-ui-toolkit
    qmenumodel
    qtsystems
    lomiri-indicator-network
    libqofono

    # Schemas
    lomiri-schemas
    ayatana-indicator-datetime
    content-hub
    lomiri-keyboard
  ];

  nativeCheckInputs = [
    dbus
    pythonEnv
    xvfb-run
  ];

  checkInputs = [
    qtgraphicaleffects # tests-only?
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ] ++ lib.optionals doCheck [
    # https://gitlab.com/ubports/development/core/lomiri-system-settings/-/issues/327
    "-DMODERN_PYTHON_DBUSMOCK=ON"
  ];

  postInstall = ''
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  # TODO Failing with 2 segfaults
  doCheck = false;

  enableParallelChecking = false;

  checkPhase = ''
    runHook preCheck

    export QT_PLUGIN_PATH=${lib.getBin qtbase}/lib/qt-${qtbase.version}/plugins
    export QML2_IMPORT_PATH=${lib.getBin qtdeclarative}/lib/qt-${qtbase.version}/qml:${lib.getBin lomiri-ui-toolkit}/lib/qt-${qtbase.version}/qml:${lib.getBin lomiri-settings-components}/lib/qt-${qtbase.version}/qml:${lib.getBin qtgraphicaleffects}/lib/qt-${qtbase.version}/qml

    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- \
      make test

    runHook postCheck
  '';

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=(
      "''${gappsWrapperArgs[@]}"
    )
  '';
}
