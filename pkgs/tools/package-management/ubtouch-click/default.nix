{ stdenv
, lib
, fetchFromGitLab
, autoreconfHook
, ensureNewerSourcesForZipFilesHook
, perl
, pkg-config
, python3
, util-linux
, vala
, dbus-test-runner
, glib
, gobject-introspection
, gtest
, json-glib
, libgee
, process-cpp
, properties-cpp
, withSystemd ? true
, systemd
}:

python3.pkgs.buildPythonApplication rec {
  pname = "click";
  version = "unstable-2022-12-25";
  format = "other";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/click";
    rev = "89338f9aa6f35d46c67cf67bbad11dab1c5dc609";
    hash = "sha256-HIYE0V4unJZO3r4DNYA+O8kOff/9y+4qt2sIyWivV9w=";
  };

  postPatch = ''
    substituteInPlace click_package/tests/Makefile.am \
      --replace 'PKG_CONFIG_PATH=$(top_builddir)/lib/click' 'PKG_CONFIG_PATH=$(top_builddir)/lib/click:''${PKG_CONFIG_PATH}'

    substituteInPlace Makefile.am \
      --replace 'conf debhelper init' 'conf init'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    ensureNewerSourcesForZipFilesHook
    gobject-introspection # hook & autoconf macro
    perl
    pkg-config
    util-linux # getopt in valac-wrapper
    vala
  ];

  buildInputs = [
    dbus-test-runner
    glib
    gobject-introspection
    gtest
    json-glib
    libgee
    process-cpp
    properties-cpp
  ] ++ lib.optionals withSystemd [
    systemd
  ];

  propagatedBuildInputs = with python3.pkgs; [
    chardet
    debian
    pygobject3
    setuptools
  ];

  configureFlags = [
    (lib.strings.enableFeature withSystemd "systemd")
    "--with-systemdsystemunitdir=${placeholder "out"}/lib/systemd/system"
    "--with-systemduserunitdir=${placeholder "out"}/lib/systemd/user"
  ];

  enableParallelBuilding = true;

  preInstall = ''
    export PYTHON_INSTALL_FLAGS="--prefix=$out"
  '';

  preFixup = ''
    makeWrapperArgs+=(
      --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH"
      --prefix LD_LIBRARY_PATH : "$out/lib"
    )
  '';

  meta = with lib; {
    description = "The package manager for Ubuntu mobile applications";
    homepage = "https://click.readthedocs.io/en/latest/index.html";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
