{ stdenv
, lib
, fetchzip
, makeWrapper
, ohrrpgce
}:

stdenv.mkDerivation rec {
  pname = "vikings-of-midgard";
  version = "unstable-2021-04-12";

  src = fetchzip {
    url = "http://www.slimesalad.com/forum/download/file.php?id=7865";
    extension = "zip";
    stripRoot = false;
    sha256 = "sha256-rYb0K1+besCzSITO6zQ7Xm185M5VYOeHmCvBG2ilLzw=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    ohrrpgce.unstable
  ];

  installPhase = ''
    mkdir -p $out/{bin,share/viking}
    cp viking.rpg $out/share/viking/
    makeWrapper ${ohrrpgce.unstable}/bin/ohrrpgce-game $out/bin/viking \
      --add-flags $out/share/viking/viking.rpg
  '';

  meta = with lib; {
    description = "";
    longDescription = ''
    '';
    license = licenses.unfree;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
