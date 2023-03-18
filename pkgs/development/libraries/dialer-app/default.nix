# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, address-book-app
, buteo-syncfw-qml
, cmake
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
      --replace 'python3 -c "from distutils.sysconfig import get_python_lib; print (get_python_lib())"' 'echo "${placeholder "out"}/${python3.sitePackages}/messaging_app"'
    substituteInPlace src/dialer-app.desktop.in.in \
      --replace 'Exec=dialer-app' 'Exec=${placeholder "out"}/bin/dialer-app'
    substituteInPlace config.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'
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
    address-book-app
    buteo-syncfw-qml
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
    # Qt 5.15 deprecations
    "-DCMAKE_CXX_FLAGS=-Wno-error=deprecated-declarations"
  ];

  # TODO
  doCheck = false;
}
