# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, accounts-qml-module
, cmake
, gettext
, lomiri-indicator-network
, lomiri-ui-toolkit
, lomiri-system-settings-online-accounts
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, qtpim
, sync-monitor
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-calendar-app";
  version = "1.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/${pname}";
    rev = "v${version}";
    hash = "sha256-5FThf1gd5Ccczb18HUD1lQOql0pBHUBmDGVdDarBA/M=";
  };

  postPatch = ''
    substituteInPlace lomiri-calendar-app.in \
      --replace 'qmlscene' '${lib.getDev qtdeclarative}/bin/qmlscene'

    # This was recently renamed upstream, name here is from a weird in-between phase?
    substituteInPlace qml/{CalendarChoicePopup,OnlineAccountsHelper}.qml \
      --replace 'Lomiri.OnlineAccounts 0.1' 'SSO.OnlineAccounts 0.1'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtdeclarative

    # QML
    accounts-qml-module
    lomiri-indicator-network
    lomiri-ui-toolkit
    lomiri-system-settings-online-accounts
    qtfeedback
    qtgraphicaleffects
    qtpim
    sync-monitor
  ];

  cmakeFlags = [
    "-DINSTALL_TESTS=OFF"
    "-DCLICK_MODE=OFF"
  ];

  # TODO
  doCheck = false;

  postFixup = ''
    wrapQtApp $out/bin/lomiri-calendar-app
  '';
}
