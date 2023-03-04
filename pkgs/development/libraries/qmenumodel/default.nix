{ stdenv
, lib
, fetchFromGitHub
, cmake
, cmake-extras
, dbus
, dbus-test-runner
, glib
, pkg-config
, python3
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "qmenumodel";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "AyatanaIndicators";
    repo = "qmenumodel";
    rev = version;
    hash = "sha256-cKolDRMamLWV8ASFLp1k0xslNAqVRCuM3/xvvBG98RI=";
  };

  postPatch = ''
    substituteInPlace libqmenumodel/src/qmenumodel.pc.in \
      --replace "\''${exec_prefix}/@CMAKE_INSTALL_LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace "\''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@" '@CMAKE_INSTALL_FULL_INCLUDEDIR@'

    substituteInPlace libqmenumodel/QMenuModel/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" "\''${CMAKE_INSTALL_LIBDIR}/qt-${qtbase.version}/qml"
  '' + lib.optionalString doCheck ''
    patchShebangs tests/{client,script}/*.py
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    glib
    qtbase
    qtdeclarative
  ];

  nativeCheckInputs = [
    dbus
    dbus-test-runner
    (python3.withPackages (ps: with ps; [
      dbus-python
      pygobject3
    ]))
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  # Tests are extremely flaky
  doCheck = false;

  preCheck = ''
    # Tests all need some Qt stuff
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/lib/qt-${qtbase.version}/plugins
  '';

  meta = with lib; {
    description = "Qt5 renderer for Ayatana Indicators";
    longDescription = ''
      QMenuModel - a Qt/QML binding for GMenuModel
      (see http://developer.gnome.org/gio/unstable/GMenuModel.html)
    '';
    homepage = "https://github.com/AyatanaIndicators/qmenumodel";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
