{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, cups
, exiv2
, lomiri-ui-toolkit
, pam
, pkg-config
, qtbase
, qtdeclarative
, xvfb-run
}:

stdenv.mkDerivation rec {
  pname = "lomiri-ui-extras";
  version = "0.6.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-aKce+w+ZROfxARBTyRRW136jfXZbucgQ0awTk7Faajk=";
  };

  patches = [
    ./0001-Drop-deprecated-qt5_use_modules.patch
  ];

  postPatch = ''
    substituteInPlace modules/Lomiri/Components/Extras{,/{plugin,PamAuthentication}}/CMakeLists.txt \
      --replace "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" '${qtbase.qtQmlPrefix}'

    # Don't disregard PATH when searching for qmltestrunner
    sed -i \
      -e '/NO_DEFAULT_PATH/d' \
      tests/qml/CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    cups
    exiv2
    pam
    qtbase
    qtdeclarative
  ];

  nativeCheckInputs = [
    qtdeclarative # qmltestrunner
    xvfb-run
  ];

  checkInputs = [
    lomiri-ui-toolkit
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DENABLE_TESTS=${lib.boolToString doCheck}"
  ];

  # QML tests work when run under nix-shell --pure / nix develop --ignore-environment, 1/3 consistently segfaults under nix-build
  # I do not understand why, and I can not debug why. I want to cry.
  doCheck = false;

  # Parallelism breaks the QML tests, seemingly ripping away the xvfb-run-launched server under their feet
  enableParallelChecking = false;

  preCheck = let
    qtToEnvvar = drvs: prefix: lib.strings.concatMapStringsSep ":" (drv: "${lib.getBin drv}/${prefix}") drvs;
  in ''
    export QT_PLUGIN_PATH=${qtToEnvvar [ qtbase] qtbase.qtPluginPrefix}
    export QML2_IMPORT_PATH=${qtToEnvvar ([ qtdeclarative lomiri-ui-toolkit ] ++ lomiri-ui-toolkit.propagatedBuildInputs) qtbase.qtQmlPrefix}
    export HOME=$PWD
    export XDG_RUNTIME_DIR=$PWD
  '';

  meta = with lib; {
    description = "Lomiri UI Extra Components";
    longDescription = ''
      A collection of UI components that for various reasons can't be included in
      the main Lomiri UI toolkit - mostly because of the level of quality, lack of
      documentation and/or lack of automated tests.
    '';
    homepage = "https://gitlab.com/ubports/development/core/lomiri-ui-extras";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
