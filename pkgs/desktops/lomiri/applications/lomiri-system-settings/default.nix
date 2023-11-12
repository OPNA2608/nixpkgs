# TODO
# - some of the plugin detection needs to be patched to check /run/current-system/sw
#   i.e. whether battery entry should be displayed:
#   "visible-if-file-exists": "/etc/dbus-1/system.d/com.lomiri.Repowerd.conf"
#   verify that everything is handled & makes sense
{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, gitUpdater
, testers
, accountsservice
, ayatana-indicator-datetime
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
, maliit-keyboard
, pkg-config
, python3
, qmenumodel
, qtbase
, qtdeclarative
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
    # Fix broken linking (linking against C-compiled accountsservice from C++ requires more care about name mangling differences)
    # Check if upstream wants this? Not sure how this currently works for them.
    ./0001-lomiri-system-settings-plugins-language-Fix-linking.patch

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
    # LIBDIR is not expected to be absolute, gets concated with other variables
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

    # Method is declared but not implemented, causes error at runtime
    sed -i plugins/gestures/gestures_dbushelper.h \
      -e '/handleDT2WEnabledChanged/d'

    # Port from lomiri-keyboard to maliit-keyboard
    substituteInPlace plugins/language/CMakeLists.txt \
      --replace 'LOMIRI_KEYBOARD_PLUGIN_PATH=\\"''${CMAKE_INSTALL_PREFIX}/lib/lomiri-keyboard/plugins\\"' 'LOMIRI_KEYBOARD_PLUGIN_PATH=\\"${lib.getLib maliit-keyboard}/lib/maliit/keyboard2/languages\"'
    substituteInPlace plugins/language/{PageComponent,SpellChecking,ThemeValues}.qml plugins/language/onscreenkeyboard-plugin.cpp plugins/sound/PageComponent.qml \
      --replace 'com.lomiri.keyboard.maliit' 'org.maliit.keyboard.maliit'

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
    ayatana-indicator-datetime
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
    maliit-keyboard
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

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString finalAttrs.doCheck}"
  ] ++ lib.optionals finalAttrs.doCheck [
    # https://gitlab.com/ubports/development/core/lomiri-system-settings/-/issues/327
    "-DMODERN_PYTHON_DBUSMOCK=ON"
  ];

  # The linking for this normally ignores missing symbols, which is inconvenient for figuring out
  # when the linker is ignoring missing symbols. Force it to report them at linktime instead of runtime.
  env.NIX_LDFLAGS = "--unresolved-symbols=report-all";

  postInstall = ''
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  # Hits OpenGL context issue inside LUITK
  doCheck = false;

  enableParallelChecking = false;

  preCheck = ''
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}
    export QML2_IMPORT_PATH=${lib.makeSearchPathOutput "bin" qtbase.qtQmlPrefix ([ qtdeclarative lomiri-ui-toolkit lomiri-settings-components ] ++ lomiri-ui-toolkit.propagatedBuildInputs)}
  '';

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=(
      "''${gappsWrapperArgs[@]}"
    )
  '';

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
    updateScript = gitUpdater { };
  };

  meta = with lib; {
    description = "System Settings application for Lomiri";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-system-settings";
    license = licenses.gpl3Only;
    mainProgram = "lomiri-system-settings";
    maintainers = teams.lomiri.members;
    platforms = platforms.linux;
    pkgConfigModules = [
      "LomiriSystemSettings"
    ];
  };
})
