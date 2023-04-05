# TODO
# - Thumbnailer: RequestImpl::dbusCallFinished(): D-Bus error: Handler::createFinished(): could not get thumbnail for thumbnail: <any file> (152,152): ERROR
# - maybe patch to fix missing modules & migrate away from qt5_use_modules
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitLab
, cmake
, exiv2
, libGL
, libmediainfo
, lomiri-thumbnailer
, lomiri-ui-extras
, lomiri-ui-toolkit
, pkg-config
, qqc2-suru-style
, qtbase
, qtdeclarative
, qtfeedback
, qtgraphicaleffects
, qtmultimedia
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "lomiri-gallery-app";
  version = "3.0.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/${pname}";
    rev = "v${version}";
    hash = "sha256-+QykoMe0ZUcTIS5FhLbWarTtiiIqnx5sOV/LQ26gLUA=";
  };

  postPatch = let
    missingModules = [ "Widgets" "Xml" "DBus" ];
  in ''
    # Missing modules
    # Deprecation warnings, no option to disable Werror: https://gitlab.com/ubports/development/apps/lomiri-gallery-app/-/issues/113
    sed -i \
      -e '/find_package(Qt5Core)/a ${lib.strings.concatMapStringsSep "\\n" (mod: "find_package(Qt5${mod})") missingModules}' \
      -e 's/-Werror//g' \
      CMakeLists.txt
  '' + lib.optionalString (!doCheck) ''
    sed -i \
      -e '/add_subdirectory(tests)/d' \
      CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    exiv2
    libGL
    libmediainfo
    qtbase
    qtdeclarative

    # QML
    lomiri-thumbnailer
    lomiri-ui-extras
    lomiri-ui-toolkit
    qqc2-suru-style
    qtfeedback
    qtgraphicaleffects
    qtmultimedia
  ];

  cmakeFlags = [
    "-DCLICK_MODE=OFF"
    "-DINSTALL_TESTS=OFF"
    "-DOpenGL_GL_PREFERENCE=GLVND"

    # TODO Variable missing from non-click build, fix upstream!
    "-DSPLASH=${placeholder "out"}/share/lomiri-gallery-app/lomiri-gallery-app-splash.svg"
  ];

  # TODO
  doCheck = false;

  postInstall = ''
    # Splash not handled outside of click build
    install -Dm644 {../desktop,$out/share/lomiri-gallery-app}/lomiri-gallery-app-splash.svg

    # Wrong (old?) name
    mv $out/share/content-hub/peers/{,lomiri-}gallery-app
  '';
}
