{ stdenv
, lib
, fetchFromGitLab
, fetchpatch
, gitUpdater
, ayatana-indicator-datetime
, biometryd
, boost
, cmake
, cmake-extras
, dbus-test-runner
, deviceinfo
, geonames
, glib
, glm
, gnome-desktop
, gsettings-qt
, gtk3
, hfd-service
, libevdev
, libqtdbustest
, libqtdbusmock
, libusermetrics
, libuuid
, lightdm_qt
, lomiri-api
, lomiri-app-launch
, lomiri-download-manager
, lomiri-indicator-network
, lomiri-ui-toolkit
, lomiri-settings-components
, lomiri-system-settings
, lomiri-schemas
, lomiri-notifications
, lomiri-thumbnailer
, maliit-keyboard
, mir
, nixos-artwork
, nixos-icons
, pam
, pkg-config
, properties-cpp
, protobuf
, python3
, qmenumodel
, qtbase
, qtdeclarative
, qtmir
, qtmultimedia
, qtsvg
, telephony-service
, wrapGAppsHook
, wrapQtAppsHook
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri";
  version = "0.1.4";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri";
    rev = finalAttrs.version;
    hash = "sha256-zul4Rk8gmoqac5BGsPlrkoqVd8kMYaOOBE5RQ2EiTWo=";
  };

  patches = [
    # Convert to miroil for Mir 2.x support
    # Remove when https://gitlab.com/ubports/development/core/lomiri/-/merge_requests/72 merged & in release
    (fetchpatch {
      name = "0001-lomiri-Support-qtmir-with-MirOil.patch";
      url = "https://gitlab.com/ubports/development/core/lomiri/-/commit/af6bfc41d73984e11e9a1ce7d61cb96ef00d6715.patch";
      hash = "sha256-m8QeRYf67AyK0k9C5HdnjnRyR0sVXjvqTOPuxh0e1Dc=";
    })

    ./0099-lomiri-Disable-Wizard.patch
  ];

  # TODO: improve NixOS-ification, fix lomiri-greeter-wrapper?
  postPatch = ''
    # This just doesn't seem to work?
    substituteInPlace tests/uqmlscene/CMakeLists.txt \
      --replace 'set_target_properties(uqmlscene PROPERTIES INCLUDE_DIRECTORIES ''${XCB_INCLUDE_DIRS})' 'target_include_directories(uqmlscene PRIVATE ''${XCB_INCLUDE_DIRS})'

    # Uses pkg_get_variable, cannot replace prefix
    substituteInPlace data/systemd-user/CMakeLists.txt \
      --replace "\''${SYSTEMD_USERUNITDIR}" "$out/lib/systemd/user"

    # Bad path concatenation
    substituteInPlace include/paths.h.in data/{indicators-client,lomiri,lomiri-greeter}.desktop.in.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

    # Lights plugin was replaced with Leds from Hfd
    substituteInPlace qml/Panel/Indicators/IndicatorsLight.qml \
      --replace  'Lights.Off' 'Leds.Off'

    # NixOS-ify
    install -Dm644 ${./lomiri-launcher-logo.svg} $out/share/icons/hicolor/scalable/apps/lomiri-launcher-logo.svg
    substituteInPlace plugins/Utils/constants.cpp \
      --replace '/usr/share/backgrounds/warty-final-ubuntu.png' '${nixos-artwork.wallpapers.simple-dark-gray.gnomeFilePath}'
    substituteInPlace qml/Launcher/LauncherPanel.qml \
      --replace 'LomiriColors.orange' '"#6586c8"' \
      --replace '"graphics/home.svg"' '"${placeholder "out"}/share/icons/hicolor/scalable/apps/lomiri-launcher-logo.svg"'

    # Exclude broken tests (Mir headers these relied on were removed in mir 2.9)
    sed -i tests/mocks/CMakeLists.txt \
      -e '/add_subdirectory(QtMir\/Application)/d'

    # Mir 2.15.0 uses std::optional, C++17 feature
    substituteInPlace CMakeLists.txt \
      --replace 'CMAKE_CXX_STANDARD 14' 'CMAKE_CXX_STANDARD 17'
  '' + lib.optionalString finalAttrs.doCheck ''
    patchShebangs tests/whitespace/check_whitespace.py
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    glib # populates GSETTINGS_SCHEMAS_PATH
    pkg-config
    wrapGAppsHook # XDG_DATA_DIRS wrapper flags for schemas
    wrapQtAppsHook
  ];

  buildInputs = [
    ayatana-indicator-datetime
    boost
    cmake-extras
    dbus-test-runner
    deviceinfo
    geonames
    glib
    glm
    gnome-desktop
    gsettings-qt
    gtk3
    libevdev
    libusermetrics
    libuuid
    lightdm_qt
    lomiri-api
    lomiri-app-launch
    lomiri-download-manager
    lomiri-indicator-network
    lomiri-schemas
    lomiri-system-settings
    lomiri-ui-toolkit
    maliit-keyboard
    mir
    pam
    properties-cpp
    protobuf
    qmenumodel
    qtbase
    qtdeclarative
    qtmir
    qtsvg

    # QML import path
    biometryd
    hfd-service
    lomiri-notifications
    lomiri-settings-components
    lomiri-thumbnailer
    qtmultimedia
    telephony-service
  ];

  nativeCheckInputs = [
    libqtdbustest
    (python3.withPackages (ps: with ps; [
      python-dbusmock
    ]))
  ];

  checkInputs = [
    libqtdbustest
    libqtdbusmock
  ];

  dontWrapGApps = true;

  cmakeFlags = [
    "-DNO_TESTS=${lib.boolToString (!finalAttrs.doCheck)}"
  ];

  postInstall = ''
    # Broken on non-Ubuntu, likely requires patch similar to this (errors the same way):
    # https://salsa.debian.org/ubports-team/lomiri-session/-/raw/58b8e4e8b8316cdacfde942b8288f792beb65cd5/debian/patches/0003_lomiri-session-Properly-differentiate-between-Ubuntu.patch
    # install -Dm755 ../data/lomiri-greeter-wrapper $out/bin/lomiri-greeter-wrapper
  '';

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  preCheck = ''
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}
    export XDG_DATA_DIRS=${libqtdbusmock}/share
  '';

  preFixup = ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  passthru.updateScript = gitUpdater { };

  meta = with lib; {
    description = "Shell of the Lomiri Operating environment";
    longDescription = ''
      Shell of the Lomiri Operating environment optimized for touch based human-machine interaction, but also supporting
      convergence (i.e. switching between tablet/phone and desktop mode).

      Lomiri is the user shell driving Ubuntu Touch based mobile devices.
    '';
    homepage = "https://lomiri.com/";
    license = licenses.gpl3Only;
    mainProgram = "lomiri";
    maintainers = teams.lomiri.members;
    platforms = platforms.linux;
  };
})
