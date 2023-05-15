# TODO
# - tests
# - meta
# - check if there's a better solution for all the patching
{ stdenv
, lib
, fetchFromGitLab
, dbus-test-runner
, dpkg
, gdb
, glib
, lttng-ust
, perl
, pkg-config
, python3
, qmake
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, qtpim
, qtquickcontrols2
, qtsystems
, wrapQtAppsHook
, xvfb-run
}:

let
  listToQtVar = list: suffix: lib.strings.concatMapStringsSep ":" (drv: "${lib.getBin drv}/${suffix}") list;
  qtPluginPaths = listToQtVar [ qtbase qtpim ] qtbase.qtPluginPrefix;
  qtQmlPaths = listToQtVar [ qtdeclarative qtfeedback qtgraphicaleffects ] qtbase.qtQmlPrefix;
in
stdenv.mkDerivation rec {
  pname = "lomiri-ui-toolkit";
  version = "1.3.5010";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-ui-toolkit";
    rev = version;
    hash = "sha256-RH9xhbII2GfpxPg6QcPrBFIoI1/Ol7WmNdd0j9FkNs8=";
  };

  postPatch = ''
    patchShebangs documentation/docs.sh tests/

    substituteInPlace tests/tests.pro \
      --replace "\''$\''$PYTHONDIR" "$out/${python3.sitePackages}"

    for subproject in po app-launch-profiler lomiri-ui-toolkit-launcher apicheck; do
      substituteInPlace $subproject/$subproject.pro \
        --replace "\''$\''$[QT_INSTALL_PREFIX]" "$out" \
        --replace "\''$\''$[QT_INSTALL_LIBS]" "$out/lib"
    done
  '';

  nativeBuildInputs = [
    qmake
    perl
    pkg-config
    python3
    wrapQtAppsHook
  ];

  buildInputs = [
    glib
    qtbase
    qtdeclarative
    qtpim
    qtquickcontrols2
    qtsystems
    lttng-ust
  ];

  propagatedBuildInputs = [
    qtfeedback
    qtgraphicaleffects
  ];

  nativeCheckInputs = [
    dbus-test-runner
    dpkg # `dpkg-architecture -qDEB_HOST_ARCH` responds decides how tests are run
    gdb
    xvfb-run
  ];

  dontWrapQtApps = true;

  qmakeFlags = [
    "CONFIG+=no_docs"
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  checkPhase = ''
    runHook preCheck

    # Test checks for correct qmlplugindump output
    # Imports itself, needs its dependencies
    env QT_PLUGIN_PATH=${qtPluginPaths} QML2_IMPORT_PATH=${qtQmlPaths} tests/xvfb.sh make check ''${enableParallelChecking:+-j''${NIX_BUILD_CORES}}

    runHook postCheck
  '';

  preInstall = ''
    # wrapper script calls qmlplugindump, crashes due to lack of minimal platform plugin
    # Could not find the Qt platform plugin "minimal" in ""
    # Available platform plugins are: wayland-egl, wayland, wayland-xcomposite-egl, wayland-xcomposite-glx.
    export QT_PLUGIN_PATH=${qtPluginPaths}

    # Qt-generated wrapper script lacks QML paths to dependencies
    for qmlModule in Components PerformanceMetrics Test; do
      substituteInPlace src/imports/$qmlModule/wrapper.sh \
        --replace 'QML2_IMPORT_PATH=' 'QML2_IMPORT_PATH=${qtQmlPaths}:'
    done
  '';

  postInstall = ''
    # Qt-generated pkg-config files have qtbase's prefix
    for pcFile in Lomiri{Gestures,Metrics,Toolkit}.pc; do
      substituteInPlace $out/lib/pkgconfig/$pcFile \
        --replace "prefix=${if (lib.versions.majorMinor qtbase.version) == "5.12" then qtbase.out else qtbase.dev}" "prefix=$out" \
        --replace "libdir=${qtbase.out}" 'libdir=''${prefix}/lib'
    done
  '';
}
