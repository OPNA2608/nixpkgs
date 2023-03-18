# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, accounts-qml-module
, address-book-app
, buteo-syncfw-qml
, cmake
, content-hub
, gettext
, gsettings-qt
, history-service
, libnotify
, libqofono
, lomiri-ui-toolkit
, lomiri-system-settings-online-accounts
, lomiri-thumbnailer
, pkg-config
, python3
, qtbase
, qtfeedback
, qtgraphicaleffects
, qtmultimedia
, qtpim
, telephony-service
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "messaging-app";
  version = "1.0.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-Eo9A6aLTqk3th8ljAZAbE5YfWbe4jEIFu6SvxGphJvc=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
    ./0002-Drop-deprecated-Q_FOREACH-for-Qt-5.15-support.patch
  ];

  postPatch = ''
    substituteInPlace tests/CMakeLists.txt \
      --replace 'python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"' 'echo "${placeholder "out"}/${python3.sitePackages}/messaging_app"'
    substituteInPlace src/messaging-app.desktop.in.in \
      --replace 'Exec=messaging-app' 'Exec=${placeholder "out"}/bin/messaging-app'
    substituteInPlace config.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

    # This was recently renamed upstream, name here is from a weird in-between phase?
    substituteInPlace src/qml/OnlineAccountsHelper.qml \
      --replace 'Lomiri.OnlineAccounts 0.1' 'SSO.OnlineAccounts 0.1'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    libnotify
    qtbase
    qtmultimedia
    qtpim

    # QML
    accounts-qml-module
    address-book-app
    buteo-syncfw-qml
    content-hub
    gsettings-qt
    history-service
    libqofono
    lomiri-ui-toolkit
    lomiri-system-settings-online-accounts
    lomiri-thumbnailer
    qtfeedback
    qtgraphicaleffects
    telephony-service
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DCLICK_MODE=OFF"
  ];

  # TODO
  doCheck = false;
}
