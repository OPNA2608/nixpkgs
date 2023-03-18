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
, libqofono
, lomiri-ui-toolkit
, lomiri-system-settings-online-accounts
, pkg-config
, python3
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, qtpim
, qtsystems
, telephony-service
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "dialer-app";
  version = "unstable-2023-03-02";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "03256914d63992c890acb91c78304f0515861028";
    hash = "sha256-HL4T5eMtPec840k53rh0o9AJzIiAkqhyLq2jAuEg69s=";
  };

  postPatch = ''
    substituteInPlace tests/CMakeLists.txt \
      --replace 'python3 -c "from distutils.sysconfig import get_python_lib; print (get_python_lib())"' 'echo "${placeholder "out"}/${python3.sitePackages}/dialer_app"'
    substituteInPlace src/dialer-app.desktop.in.in \
      --replace 'Exec=dialer-app' 'Exec=${placeholder "out"}/bin/dialer-app'
    substituteInPlace config.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'

    # This was recently renamed upstream, name here is from a weird in-between phase?
    substituteInPlace src/qml/SettingsPage/OnlineAccountsHelper.qml \
      --replace 'Lomiri.OnlineAccounts 0.1' 'SSO.OnlineAccounts 0.1'
  '';

  preConfigure = ''
    # Cannot add flags with spaces to cmakeFlags
    # - deprecated-declarations: Qt 5.15 deprecations
    # - nonnull: with GCC 11, report upstream!
    cmakeFlagsArray+=(
      '-DCMAKE_CXX_FLAGS=-Wno-error=deprecated-declarations -Wno-error=nonnull'
    )
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtdeclarative
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
    qtfeedback
    qtgraphicaleffects
    qtsystems
    telephony-service
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DCLICK_MODE=OFF"
  ];

  # TODO
  doCheck = false;
}
