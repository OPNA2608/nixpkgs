{ stdenv
, lib
, fetchFromGitLab
, cmake
, docbook-xsl-nons
, gettext
, gtk-doc
, pkg-config
, glib
}:

stdenv.mkDerivation rec {
  pname = "geonames";
  version = "0.3.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/geonames";
    rev = version;
    hash = "sha256-Mo7Khj2pgdJ9kT3npFXnh1WTSsY/B1egWTccbAXFNY8=";
  };

  postPatch = ''
    patchShebangs src/generate-locales.sh tests/setup-test-env.sh
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    docbook-xsl-nons
    gettext
    pkg-config
    gtk-doc
    glib # glib-compile-resources
  ];

  buildInputs = [
    glib
  ];

  makeFlags = [
    "LD=${stdenv.cc.targetPrefix}cc"
  ];
}
