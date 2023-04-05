# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, pkg-config
, qtbase
, qtdeclarative
}:

stdenv.mkDerivation rec {
  pname = "u1db-qt";
  version = "0.1.7";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-qlWkxpiVEUbpsKhzR0s7SKaEFCLM2RH+v9XmJ3qLoGY=";
  };

  postPatch = ''
    # QMake query response is broken
    substituteInPlace modules/U1db/CMakeLists.txt \
      --replace "\''${QT_IMPORTS_DIR}" "$out/$qtQmlPrefix"
  '' + lib.optionalString (!doCheck) ''
    # Other locations add dependencies to custom check target from tests
    substituteInPlace CMakeLists.txt \
      --replace 'add_subdirectory(tests)' 'add_custom_target(check COMMAND "echo check dummy")'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qtdeclarative # qmlplugindump
  ];

  buildInputs = [
    qtbase
    qtdeclarative
  ];

  dontWrapQtApps = true;

  preBuild = ''
    # Executes qmlplugindump
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}
  '';

  # TODO
  doCheck = false;

  postInstall = ''
    # Example only installs a desktop file that calls qmlscene, Icon entry expects theme-specific icon, depends on lomiri-ui-toolkit's legacy name
    rm -r $out/share/applications
  '';
}
