# TODO
# - tests
# - meta
# - audio only via ALSA, is this designed to go through ALSA compat plugins in PA / PW or missing wrapping?
{ stdenv
, lib
, fetchFromGitLab
, cmake
, gettext
, libapparmor
, lomiri-action-api
, lomiri-ui-extras
, lomiri-ui-toolkit
, pkg-config
, qtbase
, qtdeclarative
, qtgraphicaleffects
, qtquickcontrols2
, qtsystems
, qtwebengine
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "morph-browser";
  version = "1.0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-D/FyAj34lBQy04XdhahuDs917FLzZcZQKSt4SfqCIB8=";
  };

  postPatch = ''
    substituteInPlace src/{Morph,Ubuntu}/CMakeLists.txt \
      --replace '/usr/lib/''${CMAKE_LIBRARY_ARCHITECTURE}/qt5/qml' '${qtbase.qtQmlPrefix}'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    libapparmor
    qtbase
    qtdeclarative
    qtwebengine

    # QML
    lomiri-action-api
    lomiri-ui-extras
    lomiri-ui-toolkit
    qtgraphicaleffects
    qtquickcontrols2
    qtsystems
  ];

  # TODO
  doCheck = false;
}
