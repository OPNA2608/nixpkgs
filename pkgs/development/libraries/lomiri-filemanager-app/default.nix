# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, biometryd
, cmake
, content-hub
, gettext
, lomiri-thumbnailer
, lomiri-ui-extras
, lomiri-ui-toolkit
, pkg-config
, python3
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, samba
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-filemanager-app";
  version = "1.0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/${pname}";
    rev = "v${version}";
    hash = "sha256-W83mplQj/J8YPXVCCcCtmHT2KVYqx8tWnx0V8Dv2Xqg=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    substituteInPlace tests/autopilot/CMakeLists.txt \
      --replace 'python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"' 'echo "${placeholder "out"}/${python3.sitePackages}/lomiri_filemanager_app"'
    substituteInPlace src/plugin/folderlistmodel/CMakeLists.txt \
      --replace 'HINTS /usr/include/smbclient' "HINTS $(pkg-config --variable=includedir smbclient)"
    substituteInPlace CMakeLists.txt \
      --replace 'EXEC "''${APP_NAME}"' 'EXEC "''${CMAKE_INSTALL_FULL_BINDIR}/''${APP_NAME}"'

    substituteInPlace src/plugin/*/CMakeLists.txt \
      --replace "\''${QT_IMPORTS_DIR}" '${placeholder "out"}/${qtbase.qtQmlPrefix}'
  '' + lib.optionalString (!doCheck) ''
    sed -i \
      -e '/add_subdirectory(tests)/d' \
      CMakeLists.txt
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
    samba

    # QML
    biometryd
    content-hub
    lomiri-thumbnailer
    lomiri-ui-extras
    lomiri-ui-toolkit
    qtfeedback
    qtgraphicaleffects
  ];

  cmakeFlags = [
    "-DINSTALL_TESTS=OFF"
    "-DCLICK_MODE=OFF"
  ];

  # TODO
  doCheck = false;
}
