{ stdenv
, lib
, requireFile
, makeWrapper
, ohrrpgce
}:

stdenv.mkDerivation rec {
  pname = "franken";
  version = "1.0"; # No version number

  src = requireFile rec {
    # rpg file hashes differ between Windows & macOS uploads
    name = "franken.rpg";
    message = ''
      Unfortunately, we cannot download the required ${name} file automatically.
      Please go to https://splendidland.itch.io/franken, download & unpack the Windows version, and add it to the Nix store
      using either
        nix-store --add-fixed sha256 ${name}
      or
        nix-prefetch-url --type sha256 file:///path/to/${name}
    '';
    sha256 = "sha256-RIciE407YGEh+ujf4Jq0deKVYGI1TvUG4GA5nen4Duc=";
  };

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    ohrrpgce.unstable
  ];

  installPhase = ''
    mkdir -p $out/{bin,share/franken}
    cp ${src} $out/share/franken/franken.rpg
    makeWrapper ${ohrrpgce.unstable}/bin/ohrrpgce-game $out/bin/franken \
      --add-flags $out/share/franken/franken.rpg
  '';

  meta = with lib; {
    description = "A hero fights monsters to become stronger so they can save the world";
    longDescription = ''
      FRANKEN draws near!

      A new RPG from splendidland appears out of nowhere!

      In "FRANKEN", a hero fights monsters to become stronger so they can save the world.

      Features:
      -the most rudimentary battle system imaginable
      -bestiary to read about all the monsters
      -find three magic orbs
      -explore the world and talk to characters

      Length:  30 mins - 1 hour.
    '';
    license = licenses.unfree;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
