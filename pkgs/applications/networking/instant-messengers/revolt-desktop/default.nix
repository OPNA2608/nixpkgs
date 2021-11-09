{ stdenv
, lib
, fetchurl
, appimageTools
, makeWrapper
, electron
}:

stdenv.mkDerivation rec {
  pname = "revolt-desktop";
  version = "1.0.2";

  src = fetchurl {
    url = "https://github.com/revoltchat/desktop/releases/download/v${version}/Revolt-${version}.AppImage";
    sha256 = "1bfn0x337018zjlk5bxkzyg89lbjakfrjb8a7v0nvk29pkrmxlqv";
    name = "${pname}-${version}.AppImage";
  };

  appimageContents = appimageTools.extractType2 {
    name = "${pname}-${version}";
    inherit src;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/${pname} $out/share/applications
    cp -a ${appimageContents}/{locales,resources} $out/share/${pname}
    cp -a ${appimageContents}/revolt-desktop.desktop $out/share/applications/${pname}.desktop
    cp -a ${appimageContents}/usr/share/icons $out/share
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper ${electron}/bin/electron $out/bin/${pname} \
      --add-flags $out/share/${pname}/resources/app.asar \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ stdenv.cc.cc ]}"
  '';

  meta = with lib; {
    description = "User-first chat platform built with modern web technologies. (Desktop App)";
    homepage = "https://github.com/revoltchat/desktop";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = [ "x86_64-linux" ];
  };
}
