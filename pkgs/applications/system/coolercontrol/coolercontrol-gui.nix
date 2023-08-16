{ python3
, qtbase
, qtsvg
, qtimageformats
, qtwayland
, wrapQtAppsHook
}:

{ version
, src
, meta
}:

python3.pkgs.buildPythonApplication {
  pname = "coolercontrol";
  inherit version src;
  sourceRoot = "${src.name}/coolercontrol-gui";
  format = "pyproject";

  pythonRelaxDeps = true;

  pythonRemoveDeps = [ "pyside6" ]; # resolution issue with the wheel and relaxed dependencies

  nativeBuildInputs = [
    wrapQtAppsHook
  ] ++ (with python3.pkgs; [
    poetry-core
    setuptools
    pythonRelaxDepsHook
  ]);

  buildInputs = [
    qtbase
    qtimageformats
    qtsvg
    qtwayland
  ];

  propagatedBuildInputs = with python3.pkgs; [
    pyside6
    apscheduler
    matplotlib
    numpy
    setproctitle
    jeepney
    requests
    dataclass-wizard
  ];

  postInstall = ''
    install -Dm644 "${src}/packaging/metadata/org.coolercontrol.CoolerControl.desktop" -t "$out/share/applications/"
    install -Dm644 "${src}/packaging/metadata/org.coolercontrol.CoolerControl.metainfo.xml" -t "$out/share/metainfo/"
    install -Dm644 "${src}/packaging/metadata/org.coolercontrol.CoolerControl.png" -t "$out/share/icons/hicolor/256x256/apps/"
    install -Dm644 "${src}/packaging/metadata/org.coolercontrol.CoolerControl.svg" -t "$out/share/icons/hicolor/scalable/apps/"
  '';

  dontWrapQtApps = true;

  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  meta = meta // {
    description = "${meta.description} (GUI)";
  };
}
