{ stdenvNoCC
, lib
, fetchFromGitLab
}:

stdenvNoCC.mkDerivation rec {
  pname = "lomiri-wallpapers";
  version = "20.04.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/${pname}";
    rev = version;
    hash = "sha256-n8+vY+MPVqW6s5kSo4aEtGZv1AsjB3nNEywbmcNWfhI=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r ${lib.versions.majorMinor version} $out/share/wallpapers
    rm $out/share/wallpapers/.placeholder

    # The eternal hardwiredfallback/default
    install -Dm644 {.,$out/share/wallpapers}/warty-final-ubuntu.png

    runHook postInstall
  '';

  meta = with lib; {
    description = "Wallpapers for the Lomiri Operating Environment, gathered frompeople of the Ubuntu Touch / UBports community";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-wallpapers";
    license = with licenses; [ cc-by-sa-30 ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.all;
  };
}
