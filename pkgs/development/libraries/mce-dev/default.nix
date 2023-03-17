# TODO
# - meta
{ stdenvNoCC
, lib
, fetchFromGitHub
, withDocumentation ? true
, doxygen
}:

stdenvNoCC.mkDerivation rec {
  pname = "mce-dev";
  version = "1.32.0";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "mce-dev";
    rev = version;
    hash = "sha256-fpbwaZ0AjBdVL5fIA6+fCtcikc5JbKBqw6Yrwu+Agm4=";
  };

  postPatch = ''
    substituteInPlace mce.pc \
      --replace '/usr' "$out"
  '';

  strictDeps = true;

  nativeBuildInputs = lib.optionals withDocumentation [
    doxygen
  ];

  buildFlags = [
    "build"
  ] ++ lib.optionals withDocumentation [
    "doc"
  ];

  installFlags = [
    "DESTDIR="
    "PCDIR=${placeholder "out"}/lib/pkgconfig"
    "INCLUDEDIR=${placeholder "out"}/include/mce"
  ];

  postInstall = lib.optionalString withDocumentation ''
    mkdir -p $out/share/doc
    cp -R doc $out/share/doc/mce-dev
  '';
}
