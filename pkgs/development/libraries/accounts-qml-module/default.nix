# TODO
# - docs
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, accounts-qt
, pkg-config
, qmake
, qtbase
, qtdeclarative
, signond
}:

stdenv.mkDerivation rec {
  pname = "accounts-qml-module";
  version = "unstable-2022-10-12";

  src = fetchFromGitLab {
    owner = "accounts-sso";
    repo = "accounts-qml-module";
    rev = "4119d52cb969b57fcab63f6bdf543e73c9c17092";
    hash = "sha256-oixpmNJfmaPqQeAlPuKh+yj2PkXza0EHqF34Do3y4Fk=";
  };

  postPatch = ''
    substituteInPlace src/src.pro \
      --replace '$$[QT_INSTALL_BINS]/qmlplugindump' 'qmlplugindump' \
      --replace '$$[QT_INSTALL_QML]' '${placeholder "out"}/${qtbase.qtQmlPrefix}'
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/tests/d' accounts-qml-module.pro
  '';

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    qmake
    qtbase # minimal platform plugin
    qtdeclarative # qmlplugindump & qmake not smart enough
  ];

  buildInputs = [
    accounts-qt
    qtdeclarative
    signond
  ];

  dontWrapQtApps = true;

  qmakeFlags = [
    "CONFIG+=no_docs"
  ];

  postConfigure = ''
    make qmake_all
  '';

  # TODO
  doCheck = false;

  preInstall = ''
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}
  '';
}
