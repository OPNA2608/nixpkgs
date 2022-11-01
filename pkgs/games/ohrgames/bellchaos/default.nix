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

  meta = with lib; {
    description = "Bell Of Chaos";
    longDescription = ''
      Having failed in his quest for immortality, King Gilgamesh has
      declared war upon the gods and is building a Tower to Heaven on
      the plain of Babel. The gods place a powerful curse in a bronze
      bell, and entrust it to one young Demigoddess. She must carry
      the Bell of Chaos to the top of the tower and ring it to complete
      the curse and topple the tower.
    '';
    license = licenses.gpl2; # Not clarified if Only or Plus
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
