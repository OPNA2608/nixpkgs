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
, accountsservice
, cmake
, cmake-extras
, content-hub
, dbus
, geonames
, gettext
, glib
, gnome-desktop
, gsettings-qt
, gtk3
, icu
, intltool
, json-glib
, libqofono
, libqtdbustest
, libqtdbusmock
, lomiri-indicator-network
, lomiri-schemas
, lomiri-settings-components
, lomiri-ui-toolkit
, pkg-config
, python3
, qmenumodel
, qtbase
, qtdeclarative
, qtgraphicaleffects
, qtmultimedia
, ubports-click
, upower
, wrapGAppsHook
, wrapQtAppsHook
, xvfb-run
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-system-settings";
  version = "1.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-system-settings";
    rev = finalAttrs.version;
    hash = "sha256-7XJ2mvqcI+tBEpT6tAVJrcEzyDhiY1ttB1X1e24kmd8=";
  };

  patches = [
    # Introduce custom envvars checks to find plugins and their i18n
    #./Find-plugins-and-i18n-via-envvars.patch

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
    # Make it work with regular accountsservice
    # https://gitlab.com/ubports/development/core/lomiri-system-settings/-/issues/341
    (fetchpatch {
      name = "2001-lomiri-system-settings-disable-current-language-switching.patch";
      url = "https://sources.debian.org/data/main/l/lomiri-system-settings/1.0.1-2/debian/patches/2001_disable-current-language-switching.patch";
      hash = "sha256-ZOFYwxS8s6+qMFw8xDCBv3nLBOBm86m9d/VhbpOjamY=";
    })
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}" \
      --replace 'LIBDIR ''${CMAKE_INSTALL_LIBDIR}' 'LIBDIR lib'

    # Look up translations from current system, so plugin translations work
    substituteInPlace src/CMakeLists.txt \
      --replace 'I18N_DIRECTORY="''${CMAKE_INSTALL_PREFIX}' 'I18N_DIRECTORY="/run/current-system/sw'

    # Add current-system path to QML hardcoding for plugin lookups
    for definition in PLUGIN_PRIVATE_MODULE_DIR PLUGIN_QML_DIR; do
      sed -i src/CMakeLists.txt \
        -e "/-D''${definition}=/a string(REPLACE \"\''${CMAKE_INSTALL_PREFIX}\" \"/run/current-system/sw\" ''${definition}_GLOBAL \"\''${''${definition}}\")\nadd_definitions(-D''${definition}_GLOBAL=\"\''${''${definition}_GLOBAL}\")"
      sed -i src/main.cpp \
        -e "/mountPoint + ''${definition}/a view.engine()->addImportPath(mountPoint + ''${definition}_GLOBAL);"
    done
    cat src/CMakeLists.txt
    cat src/main.cpp

    # Decide which entries should be visible based on the current system
    substituteInPlace plugins/*/*.settings \
      --replace '/etc' '/run/current-system/sw/etc'

    # Icon is named "unity-battery-80" in (current?) Suru theme
    substituteInPlace plugins/battery/battery.settings \
      --replace 'battery-080' 'unity-battery-080'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    glib # glib-compile-schemas
    intltool
    pkg-config
    wrapGAppsHook # for schema envvars
    wrapQtAppsHook
  ];

  buildInputs = [
    accountsservice
    cmake-extras
    content-hub
    geonames
    glib
    gnome-desktop
    gsettings-qt
    gtk3
    icu
    json-glib
    libqofono
    libqtdbustest
    libqtdbusmock
    lomiri-indicator-network
    lomiri-schemas
    lomiri-settings-components
    lomiri-ui-toolkit
    qmenumodel
    qtbase
    qtdeclarative
    qtmultimedia
    ubports-click
    upower
  ];

  nativeCheckInputs = [
    dbus
    (python3.withPackages (ps: with ps; [
      python-dbusmock
    ]))
    xvfb-run
  ];

  checkInputs = [
    qtgraphicaleffects
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString finalAttrs.doCheck}"
  ] ++ lib.optionals finalAttrs.doCheck [
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
    export QML2_IMPORT_PATH=${lib.makeSearchPathOutput "bin" qtbase.qtQmlPrefix ([ qtdeclarative lomiri-ui-toolkit lomiri-settings-components ] ++ lomiri-ui-toolkit.propagatedBuildInputs)}

    dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- \
      make test

    runHook postCheck
  '';

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=(
      --prefix QML2_IMPORT_PATH : "$out/share/lomiri-system-settings/qml-plugins"
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ accountsservice ]}
      "''${gappsWrapperArgs[@]}"
    )
  '';
})
