# TODO
# - cleanup imports
# - maybe do with symlinkJoin instead?
# - meta
{ stdenvNoCC
, lib
, qtbase
, qtdeclarative
, geonames
, ubports-click
, accountsservice
, gsettings-qt
, gnome-desktop
, gtk3
, upower
, icu
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
, lomiri-online-accounts
, biometryd
, accounts-qml-module
, qtmultimedia
, lndir

, lomiri-system-settings-unwrapped
, lomiri-system-settings-online-accounts
, lomiri-system-settings-security-privacy
}:

let
  lssAll = [
    lomiri-system-settings-unwrapped
    lomiri-system-settings-online-accounts
    lomiri-system-settings-security-privacy
  ];
in
stdenvNoCC.mkDerivation rec {
  pname = "lomiri-system-settings";
  inherit (lomiri-system-settings-unwrapped) version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontInstall = true;

  strictDeps = true;

  nativeBuildInputs = [
    lndir
    wrapGAppsHook
    wrapQtAppsHook
  ];

  buildInputs = [
    # which ones here are needed at runtime?
    accountsservice
    geonames
    gnome-desktop
    gtk3
    gsettings-qt
    icu
    ubports-click
    qtbase
    qtdeclarative
    upower
    lomiri-ui-toolkit
    lomiri-settings-components
    lomiri-system-settings-unwrapped

    # QML
    qtfeedback # lomiri-ui-toolkit
    qtgraphicaleffects # lomiri-ui-toolkit
    qmenumodel
    qtsystems
    lomiri-indicator-network
    libqofono
    lomiri-online-accounts
    biometryd
    accounts-qml-module
    lomiri-system-settings-online-accounts
    qtmultimedia

    # Schemas
    lomiri-schemas
    ayatana-indicator-datetime
    content-hub
    lomiri-keyboard
  ];

  dontWrapGApps = true;
  dontWrapQtApps = true;

  fixupPhase = ''
    runHook preFixup

    # XDG_DATA_DIRS so l-s-s can find all plugins' manifest files
    # All the NIX_LSS_* variables override hardcoded paths pointing into unwrapped's prefix
    makeWrapper ${lomiri-system-settings-unwrapped}/bin/lomiri-system-settings $out/bin/lomiri-system-settings \
      "''${qtWrapperArgs[@]}" \
      "''${gappsWrapperArgs[@]}" \
      --prefix XDG_DATA_DIRS : "$out/share" \
      --set NIX_LSS_PLUGIN_MODULE_DIR "$out/lib/lomiri-system-settings" \
      --set NIX_LSS_PLUGIN_PRIVATE_MODULE_DIR "$out/lib/lomiri-system-settings/private" \
      --set NIX_LSS_PLUGIN_QML_DIR "$out/share/lomiri-system-settings/qml-plugins" \
      --set NIX_LSS_I18N_DIRECTORY "$out/share/locale"

    # Installed Lomiri cares about l-u-d data
    mkdir -p $out/share/lomiri-url-dispatcher
    lndir -silent ${lomiri-system-settings-unwrapped}/share/lomiri-url-dispatcher $out/share/lomiri-url-dispatcher

    # Hardcode to wrapped one if not already, replace hardcoding to wrapped one just in case this ever changes
    mkdir -p $out/share/applications
    cp ${lomiri-system-settings-unwrapped}/share/applications/* $out/share/applications
    substituteInPlace $out/share/applications/* \
      --replace '${lomiri-system-settings-unwrapped}/bin' "$out/bin" \
      --replace 'Exec=lomiri-system-settings' "Exec=$out/bin/lomiri-system-settings"

    # Large parts of the application logic expect all plugins to live under the same prefix
    # symlinking everything together is simpler than implementing proper handling of multiple prefixes
    for requiredPath in lib/lomiri-system-settings share/lomiri-system-settings share/locale; do
      mkdir -p $out/$requiredPath
      for lssPrefix in ${lib.strings.concatStringsSep " " lssAll}; do
        lndir -silent $lssPrefix/$requiredPath $out/$requiredPath
      done
    done

    runHook postFixup
  '';
}
