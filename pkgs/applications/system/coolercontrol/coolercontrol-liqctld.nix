{ python3
}:

{ version
, src
, meta
}:

python3.pkgs.buildPythonApplication {
  pname = "coolercontrol-liqctld";
  inherit version src;
  sourceRoot = "${src.name}/coolercontrol-liqctld";
  format = "pyproject";

  pythonRelaxDeps = true;

  nativeBuildInputs = with python3.pkgs; [
    poetry-core
    setuptools
    pythonRelaxDepsHook
  ];

  propagatedBuildInputs = with python3.pkgs; [
    liquidctl
    setproctitle
    fastapi
    uvicorn
    orjson
  ];

  postInstall = ''
    install -Dm444 "${src}/packaging/systemd/coolercontrol-liqctld.service" -t "$out/lib/systemd/system"
    substituteInPlace "$out/lib/systemd/system/coolercontrol-liqctld.service" \
      --replace '/usr/bin' "$out/bin"
  '';

  meta = meta // {
    description = "${meta.description} (Liquidctl Daemon)";
  };
}
