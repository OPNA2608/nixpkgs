# TODO
# - tests
# - check if there's a better solution for all the patching
# - "localisation through gettext" is broken
#   - if multiple QML modules from different packages use this API and get used in the same application,
#     the textdomain will be wrong for at least 1 of them
#   - lomiri-system-settings has an awkward workaround, but we should try to fix this in here instead
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
, ubuntu-themes
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

    substituteInPlace tests/unit/visual/tst_visual.cpp \
      --replace '/usr/share' '${ubuntu-themes}/share'
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
    dpkg # `dpkg-architecture -qDEB_HOST_ARCH` response decides how tests are run
    gdb
    xvfb-run
  ];

  dontWrapQtApps = true;

  qmakeFlags = [
    # docs require Qt's qdoc, which we don't have(?)
    "CONFIG+=no_docs"
  ];

  # TODO the checks need to import its QML modules, but they seem to override the envvars that would allow us to satisfy its QML dependencies, leading to import errors?
  doCheck = false;

  checkPhase = ''
    runHook preCheck

    # Test checks for correct qmlplugindump output
    # Imports itself, needs its dependencies
    export QT_PLUGIN_PATH=${qtPluginPaths}
    export QML_IMPORT_PATH=${qtQmlPaths}
    export QML2_IMPORT_PATH=${qtQmlPaths}
    export XDG_DATA_DIRS=${ubuntu-themes}/share

    tests/xvfb.sh make check ''${enableParallelChecking:+-j''${NIX_BUILD_CORES}}

    unset XDG_DATA_DIRS
    unset QML2_IMPORT_PATH
    unset QML_IMPORT_PATH
    unset QT_PLUGIN_PATH

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

  meta = with lib; {
    description = "QML components to ease the creation of beautiful applications in QML";
    longDescription = ''
      This project consists of a set of QML components to ease the creation of beautiful applications in QML for Lomiri.

      QML alone lacks built-in components for basic widgets like Button, Slider, Scrollbar, etc, meaning a developer has to build them from scratch.
      This toolkit aims to stop this duplication of work, supplying beautiful components ready-made and with a clear and consistent API.

      These components are fully themeable so the look and feel can be easily customized. Resolution independence technology is built in so UIs are scaled
      to best suit the display.

      Other features:
        - localisation through gettext
    '';
    homepage = "https://gitlab.com/ubports/development/core/lomiri-ui-toolkit";
    license = with licenses; [ gpl3Only cc-by-sa-30 ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
