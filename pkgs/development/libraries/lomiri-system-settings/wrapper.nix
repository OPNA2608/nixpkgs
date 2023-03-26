# TODO
# - cleanup imports
# - plugin i18n -> convert to symlinkJoin & envvar patch for i18nDirectory
#   https://gitlab.com/ubports/development/core/lomiri-system-settings/-/blob/1.0.1/src/main.cpp#L86
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

, lomiri-system-settings-unwrapped
, lomiri-system-settings-online-accounts
, lomiri-system-settings-security-privacy
}:

let
  plugins = [
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

    makeWrapper ${lomiri-system-settings-unwrapped}/bin/lomiri-system-settings $out/bin/lomiri-system-settings \
      "''${qtWrapperArgs[@]}" \
      "''${gappsWrapperArgs[@]}" \
      --prefix XDG_DATA_DIRS : ${lib.strings.concatMapStringsSep ":" (plugin: "${plugin}/share") ([ lomiri-system-settings-unwrapped ] ++ plugins)} \
      --set NIX_LSS_PLUGIN_PRIVATE_MODULE_DIR ${lib.strings.concatMapStringsSep ":" (plugin: "${plugin}/lib/lomiri-system-settings/private") plugins} \
      --set NIX_LSS_PLUGIN_QML_DIR ${lib.strings.concatMapStringsSep ":" (plugin: "${plugin}/share/lomiri-system-settings/qml-plugins") plugins}

    # Things the system will care about when this is installed
    mkdir -p $out/share/applications
    ln -s ${lomiri-system-settings-unwrapped}/share/lomiri-url-dispatcher $out/share/lomiri-url-dispatcher
    # Hardcode to this wrapped one if not already, replace hardcoding to wrapped one just in case this ever changes
    cp ${lomiri-system-settings-unwrapped}/share/applications/* $out/share/applications
    substituteInPlace $out/share/applications/* \
      --replace '${lomiri-system-settings-unwrapped}/bin' "$out/bin" \
      --replace 'Exec=lomiri-system-settings' "Exec=$out/bin/lomiri-system-settings"

    runHook postFixup
  '';
}
