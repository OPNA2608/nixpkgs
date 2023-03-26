# TODO
# - cleanup imports
# - plugins can access each others' QML files, which is a nightmare to manage when collecting paths and passing them via envvars.
#   symlink all plugins' files into one derivation (symlinkJoin or lndir) instead
#   - revise custom patch in unwrapped once done
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
#, lndir

, lomiri-system-settings-unwrapped
, lomiri-system-settings-online-accounts
, lomiri-system-settings-security-privacy
}:

let
  lssPlugins = [
    lomiri-system-settings-online-accounts
    lomiri-system-settings-security-privacy
  ];
  lssAll = [
    lomiri-system-settings-unwrapped
  ] ++ lssPlugins;
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
    #lndir
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
      --prefix XDG_DATA_DIRS : ${lib.strings.concatMapStringsSep ":" (plugin: "${plugin}/share") lssAll} \
      --set NIX_LSS_PLUGIN_MODULE_DIR ${lib.strings.concatMapStringsSep ":" (plugin: "${plugin}/lib/lomiri-system-settings") lssAll} \
      --set NIX_LSS_PLUGIN_PRIVATE_MODULE_DIR ${lib.strings.concatMapStringsSep ":" (plugin: "${plugin}/lib/lomiri-system-settings/private") lssPlugins} \
      --set NIX_LSS_PLUGIN_QML_DIR ${lib.strings.concatMapStringsSep ":" (plugin: "${plugin}/share/lomiri-system-settings/qml-plugins") lssPlugins} #\
      #--set NIX_LSS_I18N_DIRECTORY "$out/share/locale"

    # Installed Lomiri cares about this
    mkdir $out/share
    ln -s ${lomiri-system-settings-unwrapped}/share/lomiri-url-dispatcher $out/share/lomiri-url-dispatcher

    # Hardcode to this wrapped one if not already, replace hardcoding to wrapped one just in case this ever changes
    mkdir $out/share/applications
    cp ${lomiri-system-settings-unwrapped}/share/applications/* $out/share/applications
    substituteInPlace $out/share/applications/* \
      --replace '${lomiri-system-settings-unwrapped}/bin' "$out/bin" \
      --replace 'Exec=lomiri-system-settings' "Exec=$out/bin/lomiri-system-settings"

    # Localisations only supported in single dir
    #mkdir $out/share/locale
    #for lssI18n in ${lib.strings.concatMapStringsSep " " (lssPlugin: "${lssPlugin}/share/locale") lssAll}; do
    #  lndir $lssI18n $out/share/locale
    #done

    runHook postFixup
  '';
}
