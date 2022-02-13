{ stdenv, lib, fetchzip
, autoPatchelfHook
, makeWrapper
, libGL
, freetype
, alsa-lib
, libX11
, libXext
, libXcursor
, libXinerama
, libXrandr
, gnome
}:

let
  platformData = {
    x86_64-linux = {
      name = "Linux64";
      sha256 = "0rmrhmq8swcvs4mkwqzgs85piq1659r38mrai24j1zjwg0slgahl";
    };
    i686-linux = {
      name = "Linux32";
      sha256 = "0aalwryjmb86yras7a244c3gn1ldxlw3hxaphq0rdxgw4fa8jy5d";
    };
    x86_64-darwin = {
      name = "MacOsX";
      sha256 = lib.fakeSha256;
    };
  }.${stdenv.targetPlatform.system} or (throw "Unsupported system: ${stdenv.targetPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "arkostracker2";
  version = "2.0.1";

  src = fetchzip {
    url = "http://www.julien-nevo.com/arkostracker/release/${lib.toLower platformData.name}/Arkos%20Tracker%202%20${platformData.name}.zip";
    inherit (platformData) sha256;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc
    libGL
    freetype
    alsa-lib
    gnome.zenity
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/arkostracker2}
    cp -R * $out/lib/arkostracker2
    ln -s $out/{lib/arkostracker2,bin}/ArkosTracker2

    wrapProgram $out/bin/ArkosTracker2 \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libX11 libXext libXcursor libXinerama libXrandr ]} \
      --prefix PATH : ${lib.makeBinPath [ gnome.zenity ]}

    runHook postInstall
  '';
}
