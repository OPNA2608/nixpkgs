{ stdenv
, lib
, fetchFromGitLab
, cmake
, cmake-extras
, pkg-config
, glib
, gtest
, libqtdbustest
, qtbase
, qtdeclarative
, python3
}:

stdenv.mkDerivation rec {
  pname = "lomiri-api";
  version = "0.2.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-api";
    rev = version;
    hash = "sha256-84iM4N6vEn6nmZMTBsUOCtR0WkYfoowsJhhIlQoaq1c=";
  };

  postPatch = ''
    for pyscript in $(find test -name '*.py'); do
      patchShebangs $pyscript
    done

    for pc in data/*.pc.in; do
      substituteInPlace $pc \
        --replace "\''${prefix}/include" '@CMAKE_INSTALL_FULL_INCLUDEDIR@' \
        --replace "\''${prefix}/@CMAKE_INSTALL_LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@'
    done

    # TODO not the correct way of handling this.
    # SHELL_PLUGINDIR is intended to be relative to prefix so reverse-dependencies can replace the prefix
    # and get the correct path for their plugin installs
    # But the CMAKE_INSTALL_LIBDIR we pass in is absolute (which is permitted by the CMake specs)
    # so it produces garbage in the pkg-config and rever-dependencies cannot resolve this properly,
    # not without hacks of their own anyway
    # Also, must have the Qt5 version in it, otherwise wrappers won't pick these up
    substituteInPlace CMakeLists.txt \
      --replace 'SHELL_PLUGINDIR ''${CMAKE_INSTALL_LIBDIR}/lomiri/qml' 'SHELL_PLUGINDIR lib/qt-${qtbase.version}/qml'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    glib
    gtest
    libqtdbustest
    qtbase
    qtdeclarative
  ];

  nativeCheckInputs = [
    python3
  ];

  dontWrapQtApps = true;

  # Fails rn
  #doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
}
