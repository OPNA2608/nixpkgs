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
, libnotify
, libqofono
, lomiri-ui-toolkit
, lomiri-system-settings-online-accounts
, pkg-config
, python3
, qtbase
, qtfeedback
, qtgraphicaleffects
, qtmultimedia
, qtpim
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
    address-book-app
    buteo-syncfw-qml
    gsettings-qt
    libqofono
    lomiri-ui-toolkit
    lomiri-system-settings-online-accounts
    qtfeedback
    qtgraphicaleffects
  ];

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
    "-DCLICK_MODE=OFF"
  ];

  # TODO
  doCheck = false;
}
