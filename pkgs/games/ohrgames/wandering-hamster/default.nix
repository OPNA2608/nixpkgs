{ stdenv
, lib
, fetchFromGitHub
, makeWrapper
, ohrrpgce
}:

stdenv.mkDerivation rec {
  pname = "wandering-hamster";
  version = "unstable-2022-10-09";

  src = fetchFromGitHub {
    owner = "bob-the-hamster";
    repo = "wander";
    rev = "0b7d5327ab281c9936198782fd986f7ac4710311";
    sha256 = "sha256-DKGrOAC1l7N22bt0YbncyC8YipteZmQBY7uhMIkYgos=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    ohrrpgce.unstable
  ];

  installPhase = ''
    mkdir -p $out/{bin,share/wander}
    cp -R wander.rpgdir $out/share/wander/
    makeWrapper ${ohrrpgce.unstable}/bin/ohrrpgce-game $out/bin/wander \
      --add-flags $out/share/wander/wander.rpgdir
  '';

  meta = with lib; {
    # Attribute naming conflict
    mainProgram = "wander";
    description = "Wandering Hamster OHRRPGCE Game";
    longDescription = ''
      Lord Hasim has been overthrown, plips run rampant, and a menacing evil lurks in the shadows... or is it a cactus?
      What hamster is spiffy enough to save the world? Bob!
    '';
    license = licenses.gpl2; # Not clarified if Only or Plus
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
