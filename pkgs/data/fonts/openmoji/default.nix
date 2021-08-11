{ stdenv
, lib
, fetchFromGitHub
, scfbuild
, nodejs
, nodePackages
, variant ? "color" # "color" or "black"
}:

let
  filename = builtins.replaceStrings
    [ "color"              "black"              ]
    [ "OpenMoji-Color.ttf" "OpenMoji-Black.ttf" ]
    variant;

in stdenv.mkDerivation rec {
  pname = "openmoji";
  version = "13.1.0";

  src = fetchFromGitHub {
    owner = "hfg-gmuend";
    repo = "openmoji";
    rev = version;
    sha256 = "0adi9xh9vyjqn3f5fnjz1sdi5pr7a8c0wrzqr3ixkvvan7w9lvpc";
  };

  nativeBuildInputs = [
    scfbuild
    nodejs
    nodePackages.glob
    nodePackages.lodash
  ];

  buildPhase = ''
    runHook preBuild

    node helpers/generate-font-glyphs.js

    cd font
    scfbuild -c scfbuild-${variant}.yml

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 ${filename} $out/share/fonts/truetype/${filename}

    runHook postInstall
  '';

  meta = with lib; {
    license = licenses.cc-by-sa-40;
    maintainers = with maintainers; [ fgaz OPNA2608 ];
    platforms = platforms.all;
    homepage = "https://openmoji.org/";
    downloadPage = "https://github.com/hfg-gmuend/openmoji/releases";
    description = "Open-source emojis for designers, developers and everyone else";
  };
}


