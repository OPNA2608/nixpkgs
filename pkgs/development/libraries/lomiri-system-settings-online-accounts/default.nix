{ stdenv
, lib
, fetchFromGitLab
, accounts-qt
, json-glib
, libapparmor
, libnotify
, lomiri-system-settings-unwrapped
, pkg-config
, qmake
, qtbase
, qtdeclarative
, signond
, ubports-click
}:

stdenv.mkDerivation rec {
  pname = "lomiri-system-settings-online-accounts";
  version = "unstable-2023-02-22";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = "3601dad3d6c8392bda028ae2e0f973af988a104f";
    hash = "sha256-lURMW0dMljejJOoVJODpczSE90xvBkcRLFMN4CEIiwM=";
  };

  postPatch = ''
    substituteInPlace po/po.pro \
      --replace '""' '" "'
    substituteInPlace common-project-config.pri \
      --replace '/usr' "$out"
    substituteInPlace client/module/module.pro \
      --replace '$$[QT_INSTALL_QML]' '${placeholder "out"}/${qtbase.qtQmlPrefix}'

    # We don't have Qt's doc generation tool
    sed -i \
      -e '/include(doc\/doc.pri)/d' \
      client/client.pro

    # This was recently renamed upstream, name here is from a weird in-between phase?
    # Used in too many places
    for qmlfile in $(find . -name '*.qml'); do
      substituteInPlace $qmlfile \
        --replace 'Lomiri.OnlineAccounts 0.1' 'SSO.OnlineAccounts 0.1'
    done
  '';

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    qmake
    qtdeclarative # qmake not smart enough
  ];

  buildInputs = [
    accounts-qt
    json-glib
    libapparmor
    libnotify
    lomiri-system-settings-unwrapped
    qtbase
    qtdeclarative
    signond
    ubports-click
  ];

  dontWrapQtApps = true;

  qmakeFlags = [
    "CONFIG+=no_tests"
  ];

  postConfigure = ''
    make qmake_all
  '';

  buildTargets = toString [
    "all"
    "pot"
  ];

  NIX_CFLAGS_COMPILE = toString [
    "-I${lib.getDev json-glib}/include/json-glib-1.0"
    # Qt 5.15 deprecation
    "-Wno-error=deprecated-declarations"
  ];
}
