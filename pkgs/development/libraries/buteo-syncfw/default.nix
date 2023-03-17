# TODO
# - meta
# - tests?
{ stdenv
, lib
, fetchFromGitHub
, accounts-qt
, dbus
, doxygen
, glib
, libiphb
, libmce-qt
, pkg-config
, qmake
, qtdeclarative
, signond
, wrapGAppsHook
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "buteo-syncfw";
  version = "0.11.3";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "buteo-syncfw";
    rev = version;
    hash = "sha256-Bgs6us3p5J/MQz5Ft9GCMPG93NvU+8xxYzPIRoKiYsQ=";
  };

  postPatch = ''
    substituteInPlace declarative/declarative.pro libbuteosyncfw/libbuteosyncfw.pro oopp-runner/oopp-runner.pro \
      msyncd/msyncd-app.pro msyncd/bin/msyncd.service msyncd/com.meego.msyncd.service doc/doc.pri \
      --replace '$$[QT_INSTALL_QML]' "$out/$qtQmlPrefix" \
      --replace '$$[QT_INSTALL_LIBS]' "$out/lib" \
      --replace '/usr' "$out" \
      --replace '/etc' "$out/etc" \
      --replace '$${PWD}/html/*' '$$files($${PWD}/html/*)'

    # Don't want to bother with packaging Sailfish OS' way of launching applications
    # Just make the service launch the binary directly
    sed -i \
      -e 's,ExecStart=.*,ExecStart=${placeholder "out"}/bin/msyncd,g' \
      msyncd/bin/msyncd.service
  '' + lib.optionalString (!doCheck) ''
    sed -i -e '/unittests/d' buteo-sync.pro
  '';

  strictDeps = true;

  nativeBuildInputs = [
    doxygen
    glib # glib-compile-schemas, schema hook
    pkg-config
    qmake
    wrapGAppsHook
    wrapQtAppsHook

    # qmake too stupid
    qtdeclarative
  ];

  buildInputs = [
    accounts-qt
    dbus
    libiphb
    libmce-qt
    qtdeclarative
    signond
  ];

  dontWrapGApps = true;

  postConfigure = ''
    make qmake_all
  '';

  buildTargets = [
    "all"
    "doc"
  ];

  # TODO
  doCheck = false;

  postInstall = ''
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  preFixup = ''
    qtWrapperArgs+=(
      "''${gappsWrapperArgs[@]}"
    )
  '';
}
