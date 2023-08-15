{ rustPlatform
, testers
, coolercontrol
}:

{ version
, src
, meta
}:

rustPlatform.buildRustPackage {
  pname = "coolercontrold";
  inherit version src;
  sourceRoot = "source/coolercontrold";

  cargoHash = "sha256-Zgm1ROgZ4Ph/fPdIYW3OqTj2BtZ4KT7TNqCx5K2ZkCc=";

  postInstall = ''
    install -Dm444 "${src}/packaging/systemd/coolercontrold.service" -t "$out/lib/systemd/system"
    substituteInPlace "$out/lib/systemd/system/coolercontrold.service" \
      --replace '/usr/bin' "$out/bin"
  '';

  passthru.tests.version = testers.testVersion {
    package = coolercontrol.coolercontrold;
    # coolercontrold prints its version with "v" prefix
    version = "v${version}";
  };

  meta = meta // {
    description = "${meta.description} (Main Daemon)";
  };
}
