# TODO
# - tests
# - meta
{ stdenv
, lib
, fetchFromGitHub
, glib
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "libdsme";
  version = "0.66.8";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "libdsme";
    rev = version;
    hash = "sha256-5lo99k8nbLdCV6MSaghPXV/vT6rNa78gymSJLQKe2yQ=";
  };

  postPatch = ''
    substituteInPlace *.pc Makefile \
      --replace '/usr' "$out"
  '' + lib.optionalString (!doCheck) ''
    substituteInPlace Makefile \
      --replace 'TARGETS_UT_BIN += tests/ut_libdsme' 'TARGET_UT_BIN ='
  '';

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    glib
  ];

  installTargets = [
    # all target tries to install tests
    "install_main"
    "install_devel"
  ];

  installFlags = [
    "DESTDIR="
  ];

  postInstall = ''
    # Upstream expects ldconfig to generate missing symlink from solib.MAJOR_VERSION to solib.FULL_VERSION
    for library in $out/lib/*.so.*; do
      solib_MAJOR=$out/lib/$(echo $(basename $library) | cut -d. -f-3)
      [ -e $solib_MAJOR ] && continue
      ln -vsf $(basename $library) $solib_MAJOR
    done
  '';

  # TODO
  doCheck = false;
}
