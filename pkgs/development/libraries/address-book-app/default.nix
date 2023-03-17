# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, accounts-qml-module
, buteo-syncfw-qml
, cmake
, gsettings-qt
, pkg-config
, libqofono
, lomiri-keyboard
, lomiri-system-settings-online-accounts
, lomiri-ui-toolkit
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, qtpim
, qtquickcontrols2
, qtsystems
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "address-book-app";
  version = "unstable-2023-03-01";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "a5120c5dc1cfef8084d0eaa62ff6497e87df679b";
    hash = "sha256-4umSKUS2Sg0ZUlNtB2fS1xZWiwgDpgtiRWGevwlkmxk=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" '${qtbase.qtQmlPrefix}' \
      --replace 'DESKTOP_EXEC "address-book-app"' 'DESKTOP_EXEC "${placeholder "out"}/bin/address-book-app"'

    # This was recently renamed upstream, name here is from a weird in-between phase?
    substituteInPlace src/imports/Lomiri/Contacts/OnlineAccountsHelper.qml \
      --replace 'Lomiri.OnlineAccounts 0.1' 'SSO.OnlineAccounts 0.1'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtdeclarative
    qtpim

    # QML
    accounts-qml-module
    buteo-syncfw-qml
    gsettings-qt
    libqofono
    lomiri-keyboard
    lomiri-system-settings-online-accounts
    lomiri-ui-toolkit
    qtfeedback
    qtgraphicaleffects
    qtquickcontrols2
    qtsystems
  ];

  cmakeFlags = [
    "-DINSTALL_TESTS=OFF"
    "-DCLICK_MODE=OFF"
  ];
}
