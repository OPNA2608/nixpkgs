{
  stdenv,
  lib,
  fetchFromGitLab,
  accounts-qt,
  ayatana-indicator-messages,
  cmake,
  dconf,
  dbus,
  dbus-test-runner,
  evolution-data-server,
  folks,
  gettext,
  gobject-introspection,
  libaccounts-glib,
  libnotify,
  libphonenumber,
  lomiri-url-dispatcher,
  pkg-config,
  protobuf,
  python3,
  qtbase,
  qtpim,
  runCommand,
  shared-mime-info,
  systemdLibs,
  vala,
  xmlstarlet,
}:

let
  testDbusServicesDir = runCommand "lomiri-address-book-service-test-services" {} ''
    mkdir $out
    cp ${dconf}/share/dbus-1/services/ca.desrt.dconf.service $out/
  '';
  testDbusConfig = runCommand "lomiri-address-book-service-test-session.conf" {
    nativeBuildInputs = [
      xmlstarlet
    ];
  } ''
    xmlstarlet edit -s '/busconfig' -t elem -n servicedir -v '${testDbusServicesDir}' '${dbus-test-runner}/share/dbus-test-runner/session.conf' > $out
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-address-book-service";
  version = "0.1.7-unstable-2025-02-07";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-address-book-service";
    rev = "ae1bdbb41d4af668144da9226c8a2c606533ca73";
    hash = "sha256-QELbqeC5VCuSGJLBl2pvTo2sVr84v/40iwzVHqHLo+c=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    substituteInPlace contacts/CMakeLists.txt \
      --replace-fail "\''${CMAKE_INSTALL_LIBDIR}/qt5/plugins" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtPluginPrefix}"

    # libebackend-1.2's moduledir doesn't let us substitute prefix
    substituteInPlace eds-extension/CMakeLists.txt \
      --replace-fail 'pkg-config --variable=moduledir libebackend-1.2' "echo $out/lib/evolution-data-server/registry-modules"

    substituteInPlace systemd/CMakeLists.txt \
      --replace-fail 'pkg_get_variable(SYSTEMD_USER_UNIT_DIR systemd systemduserunitdir)' 'pkg_get_variable(SYSTEMD_USER_UNIT_DIR systemd systemduserunitdir DEFINE_VARIABLES prefix=''${CMAKE_INSTALL_PREFIX})'
  '' + lib.optionalString finalAttrs.finalPackage.doInstallCheck ''
    substituteInPlace tests/CMakeLists.txt \
      --replace-fail 'PATHS /usr/lib/evolution/' 'PATHS ${evolution-data-server}/libexec/'

    substituteInPlace tests/unittest/run-eds-test.sh \
      --replace-fail '--keep-env --max-wait' '--keep-env --dbus-config=${testDbusConfig} --max-wait'

    substituteInPlace tests/unittest/contact-avatar-test.cpp \
      --replace-fail 'file:///tmp' "file://$TMPDIR"

    patchShebangs tests/tst_tools/mock/*.py

    # Debugging
    substituteInPlace tests/unittest/contact-collection-test.cpp \
      --replace-fail 'QVERIFY(c.id().toString().startsWith' 'qDebug() << c.id().toString(); qDebug() << contact.id().toString(); QVERIFY(c.id().toString().startsWith'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
  ];

  buildInputs = [
    accounts-qt
    ayatana-indicator-messages
    evolution-data-server
    folks
    libaccounts-glib
    libnotify
    libphonenumber
    lomiri-url-dispatcher
    protobuf # needed by libphonenumber
    qtbase
    qtpim
    systemdLibs
  ];

  nativeInstallCheckInputs = [
    dbus
    dbus-test-runner
    gobject-introspection
    evolution-data-server
    (python3.withPackages (ps: with ps; [
      dbus-python
      pygobject3
    ]))
    vala
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_TESTS" finalAttrs.finalPackage.doInstallCheck)
  ];

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  # checkTarget = "test";
  installCheckTarget = "check";

  # Spins up D-Bus
  enableParallelChecking = false;

  preInstallCheck =
    let
      listToQtVar = lib.makeSearchPathOutput "bin";
    in
    ''
      export HOME=$TMPDIR
      export QT_PLUGIN_PATH=${
        listToQtVar qtbase.qtPluginPrefix [
          qtpim
        ]
      }
      export XDG_DATA_DIRS="$XDG_DATA_DIRS''${XDG_DATA_DIRS:+:}${shared-mime-info}/share"
      export EDS_EXTRA_PREFIXES=$out
    '';

  /*
  installCheckPhase = ''
    runHook preInstallCheck

    make check -j1

    runHook postInstallCheck
  '';
  */

  meta = {
    pkgConfigModules = [
      "evolution-data-server-ubuntu"
    ];
  };
})
