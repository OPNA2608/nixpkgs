{ stdenv
, lib
, fetchFromGitHub
, fetchFromGitLab
, cmake
, content-hub
, intltool
, lomiri-indicator-network
, lomiri-push-qml
, lomiri-thumbnailer
, lomiri-ui-toolkit
, pkg-config
, qqc2-suru-style
, qtbase
, qtmultimedia
, qtpositioning
, qtquickcontrols2
, quazip
, quickflux
, rlottie
, rlottie-qml
, tdlib
, wrapQtAppsHook
}:

let
  tdlib-185 = tdlib.overrideAttrs (oa: fa: {
    version = "1.8.5";
    src = fetchFromGitHub {
      owner = "tdlib";
      repo = "td";
      rev = "d9cfcf88fe4ad06dae1716ce8f66bbeb7f9491d9";
      # TODO too flaky, hash keeps changing - get it building without .git
      leaveDotGit = true;
      hash = "sha256-PUqiWC77igUEgu88BCYnf3utcbZu/86sayu7PaWqzYI=";
    };
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "teleports";
  version = "1.19";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/teleports";
    rev = "v${finalAttrs.version}";
    hash = "sha256-cgzHIhJJ1q6RCQlvYWbdwcy33eBMfyE/JkAYX2yNQIQ=";
  };

  postPatch = ''
    substituteInPlace libs/qtdlib/CMakeLists.txt \
      --replace 'Td 1.8.2' 'Td'

    # TODO install assets to share & point code at it
    substituteInPlace push/pushhelper.cpp libs/qtdlib/client/qtdclient.cpp app/main.cpp \
      --replace 'QGuiApplication::applicationDirPath()' 'QString("${placeholder "out"}")'

    # System theme doesn't seem to exist in LUITK, default to Ambiance instead
    substituteInPlace app/qml/stores/SettingsStore.qml \
      --replace 'Lomiri.Components.Themes.System' 'Lomiri.Components.Themes.Ambiance'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    intltool
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    content-hub
    lomiri-indicator-network
    lomiri-push-qml
    lomiri-thumbnailer
    lomiri-ui-toolkit
    rlottie-qml
    qqc2-suru-style
    qtbase
    qtmultimedia
    qtpositioning
    qtquickcontrols2
    quazip
    quickflux
    rlottie
    tdlib-185
  ];
})
