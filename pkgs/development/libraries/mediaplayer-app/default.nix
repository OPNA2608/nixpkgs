# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, gettext
, lomiri-action-api
, lomiri-ui-toolkit
, pkg-config
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, qtmultimedia
, qtxmlpatterns
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "mediaplayer-app";
  version = "1.0.2";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-5k2/ItNrNIUaDhxGrf/s+NAXV4TWVOX4fJVNa+glfbc=";
  };

  postPatch = ''
    substituteInPlace config.h.in \
      --replace '@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_BINDIR@' '@CMAKE_INSTALL_FULL_BINDIR@'
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
    qtmultimedia

    # QML
    lomiri-action-api
    lomiri-ui-toolkit
    qtdeclarative
    qtfeedback
    qtgraphicaleffects
    qtxmlpatterns
  ];

  cmakeFlags = [
    "-DUSE_XVFB=${lib.boolToString doCheck}"
  ];

  # TODO
  doCheck = false;
}
