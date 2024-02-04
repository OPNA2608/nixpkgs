{ stdenv
, lib
, fetchFromGitLab
, buildGoPackage
, ayatana-indicator-messages
, gobject-introspection
, json-glib
, libgee
, lomiri-app-launch
, lomiri-url-dispatcher
, pkg-config
, python3
, ubports-click
, wrapGAppsHook
}:

buildGoPackage rec {
  pname = "lomiri-push-service";
  version = "0.90.0-unstable-2023-11-19";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-push-service";
    rev = "6de2a4beab52052a476000a1b257efd130f92f72";
    hash = "sha256-fPFHTP3HPMkhBeEdOSAJYm8Qh5kcqfM+dL5cffUjA+4=";
  };

  # Uses godeps to parse dependencies.tsv & fetch dependencies via Makefile target
  goPackagePath = "gitlab.com/ubports/development/core/lomiri-push-service";
  goDeps = ./deps.nix;

  postPatch = ''
    patchShebangs scripts/{goctest,connect-many.py}

    # .deps files produce weird results that the compiler doesn't like, and don't need to be needed
    substituteInPlace Makefile \
      --replace 'TOBUILD:.go=.go.deps' 'TOBUILD:.go'

    # Not sure if this is *exactly* the same, but gets it to launch
    substituteInPlace identifier/identifier.go \
      --replace 'machineIdPath = "/var/lib/dbus/machine-id"' 'machineIdPath = "/etc/machine-id"'

    # Point at something we can test with
    substituteInPlace config/config_test.go \
      --replace '"/root"' "\"$TMPDIR/test-noaccess\""

    # ...and set it up
    mkdir $TMPDIR/test-noaccess
    chmod 000 $TMPDIR/test-noaccess

    # Disable tests that don't work for us / seem borked

    # Expects a system-installed python, with a share/pixmaps/python<version>.xpm & share/desktop/python<version>.desktop
    substituteInPlace click/click_test.go \
      --replace 'func (cs *clickSuite) TestIcon(c *C) {' 'func (cs *clickSuite) TestIcon(c *C) { c.Skip("Skipping, Nixpkgs has no pixmap for python")' \
      --replace 'func (s *clickSuite) TestInstalledLegacy(c *C) {' 'func (s *clickSuite) TestInstalledLegacy(c *C) { c.Skip("Skipping, Nixpkgs has no desktop file for python")'

    # Test SSL key & certificate in server/acceptance/ssl fails to verify
    # tls: failed to verify certificate: x509: certificate relies on legacy Common Name field, use SANs instead
    substituteInPlace client/session/session_test.go \
      --replace 'func (cs *clientSessionSuite) TestDialWorksDirectSHA512Cert(c *C) {' 'func (cs *clientSessionSuite) TestDialWorksDirectSHA512Cert(c *C) { c.Skip("Skipping, test certificate fails to verify")'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    gobject-introspection
    pkg-config
    python3
    wrapGAppsHook
  ];

  buildInputs = [
    ayatana-indicator-messages
    json-glib
    libgee
    lomiri-app-launch
    lomiri-url-dispatcher
    (python3.withPackages (ps: with ps; [
      pygobject3
      pyxdg
    ]))
    ubports-click
  ];

  buildPhase = ''
    runHook preBuild

    cd go/src/gitlab.com/ubports/development/core/lomiri-push-service
    export LOMIRI_PUSH_TEST_RESOURCES_ROOT=$PWD
    make build-client build-server-dev ''${enableParallelBuilding:+-j $NIX_BUILD_CORES}

    runHook postBuild
  '';

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  checkPhase = ''
    runHook preCheck

    # For tests to produce correct results when determining if FHS paths in tests are treated as system-installed
    export XDG_DATA_DIRS=/usr/share

    make check ''${enableParallelChecking:+-j $NIX_BUILD_CORES}

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    make -C exec-tool install libdir=$out/lib

    # Most of the necessary installation is not handled by any scripts, just via Debian install files

    # lomiri-push-service.install
    install -Dm444 debian/config.json $out/etc/xdg/lomiri-push-service
    install -Dm444 debian/push-helper.hook $out/share/click/hooks/push-helper.hook
    install -Dm755 -t $out/lib/lomiri-push-service/ scripts/click-hook-{wrapper,build-helper-db,populate-settings}
    install -Dm444 lomiri-push-service.service $out/lib/systemd/user/lomiri-push-service.service
    install -Dm755 lomiri-push-service $out/lib/lomiri-push-service/lomiri-push-service

    patchShebangs $out/lib/lomiri-push-service/click-hook-*

    substituteInPlace \
      $out/lib/lomiri-push-service/click-hook-wrapper \
      $out/share/click/hooks/push-helper.hook \
      $out/lib/systemd/user/lomiri-push-service.service \
      --replace '/usr' "$out"

    # lomiri-push-dev-server.install
    install -Dm755 push-server-dev $out/bin/lomiri-push-dev-server

    runHook postInstall
  '';

  dontWrapGApps = true;

  postFixup = ''
    for tool in $out/lib/lomiri-push-service/click-hook-{build-helper-db,populate-settings}; do
      wrapGApp $tool
    done
  '';

  meta = with lib; {
    description = "Protocol, client, and development code for Lomiri Push Notifications";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-push-service";
    license = licenses.gpl3Only;
    maintainers = teams.lomiri.members;
    platforms = platforms.linux;
  };
}
