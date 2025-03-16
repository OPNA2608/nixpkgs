{
  stdenv,
  lib,
  fetchFromGitLab,
  fetchpatch,
  accounts-qml-module,
  buteo-syncfw-qml,
  cmake,
  gsettings-qt,
  libqofono,
  lomiri-address-book-service,
  lomiri-content-hub,
  lomiri-telephony-service,
  lomiri-ui-toolkit,
  pkg-config,
  qtbase,
  qtdeclarative,
  qtgraphicaleffects,
  qtpim,
  qtquickcontrols2,
  qtsystems,
  wrapQtAppsHook,
  xvfb-run,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-addressbook-app";
  version = "0.9.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-addressbook-app";
    tag = finalAttrs.version;
    hash = "sha256-jEr7y5YVQpW+mMc2oUYLni3cH4RnrCpdeezvsafR4Eg=";
  };

  patches = [
    # Remove when version > 0.9.0
    (fetchpatch {
      name = "0001-lomiri-addressbook-app-Update-content-hub-file-location.patch";
      url = "https://gitlab.com/ubports/development/core/lomiri-addressbook-app/-/commit/8c26eddc362cfb79c32c8b779b893c75985fde66.patch";
      hash = "sha256-LnrPWEMaiICIWX6b9EGlTyis6xu7KsqOYpKPe487Vec=";
    })

    # TODO: Copy in-tree, not merged yet
    # Remove when https://gitlab.com/ubports/development/core/lomiri-addressbook-app/-/merge_requests/252 merged & in release
    (fetchpatch {
      name = "1001-lomiri-addressbook-app-Replacef-Lomiri.Keyboard-usage-with-plain-property.patch";
      url = "https://gitlab.com/ubports/development/core/lomiri-addressbook-app/-/commit/92d503e90f3ca3e8d2009158b9483ecc98c46aff.patch";
      hash = "sha256-FfpFNfTsXh4/EjhTHH1NwPL0msuKohUhxKeXygrWVz4=";
    })
  ];

  postPatch =
    ''
      substituteInPlace CMakeLists.txt \
        --replace-fail "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}"

      substituteInPlace tests/qml/CMakeLists.txt \
        --replace-fail 'NO_DEFAULT_PATH' ""
    ''
    + lib.optionalString (!finalAttrs.finalPackage.doCheck) ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'add_subdirectory(tests)' '# add_subdirectory(tests)'
    '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    libqofono
    qtbase
    qtpim

    # QML
    accounts-qml-module
    buteo-syncfw-qml
    gsettings-qt
    lomiri-content-hub
    # lomiri-online-accounts # Lomiri.OnlineAccounts.Client
    lomiri-telephony-service
    lomiri-ui-toolkit
    qtdeclarative
    qtsystems
  ];

  nativeCheckInputs = [
    qtdeclarative # qmltestrunner
    xvfb-run
  ];

  cmakeFlags = [
    (lib.cmakeBool "CLICK_MODE" false)
    (lib.cmakeBool "INSTALL_TESTS" false)
  ];

  #doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  doCheck = false;

  preCheck =
    let
      listToQtVar = lib.makeSearchPathOutput "bin";
    in
    ''
      export QT_QPA_PLATFORM=minimal
      export QT_PLUGIN_PATH=${listToQtVar qtbase.qtPluginPrefix [ lomiri-address-book-service qtbase qtpim ]}
      export QML2_IMPORT_PATH=${listToQtVar qtbase.qtQmlPrefix [ buteo-syncfw-qml gsettings-qt libqofono lomiri-content-hub lomiri-telephony-service lomiri-ui-toolkit qtgraphicaleffects qtpim qtquickcontrols2 ]}
    '';
})
