{ stdenv
, lib
, fetchsvn
, makeWrapper
, ohrrpgce
}:

stdenv.mkDerivation rec {
  pname = "bellchaos";
  version = "unstable-2012-06-14";

  src = fetchsvn {
    url = "https://rpg.hamsterrepublic.com/source/games/bellchaos/";
    rev = "5232";
    sha256 = "sha256-8aRaAzSFSiInc1zR3N5fWvz8yxVhDink19NYVwNHeQU=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    ohrrpgce.unstable
  ];

  installPhase = ''
    mkdir -p $out/{bin,share/bellchaos}
    cp -R bellchaos.rpgdir $out/share/bellchaos/
    makeWrapper ${ohrrpgce.unstable}/bin/ohrrpgce-game $out/bin/bellchaos \
      --add-flags $out/share/bellchaos/bellchaos.rpgdir
  '';
}
