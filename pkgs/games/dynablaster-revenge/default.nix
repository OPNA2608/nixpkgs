{ stdenv
, lib
, mkDerivation
, fetchFromGitHub
, qtbase
, qmake
, wrapQtAppsHook
, libGLU
, SDL2
, alsa-lib

, isServer ? false
, isHeadless ? false
}:

assert isHeadless -> isServer;

mkDerivation rec {
  pname = "dynablaster-revenge"
    + lib.optionalString isServer "-server"
    + lib.optionalString isHeadless "-headless";
  version = "unstable-2021-01-02";

  src = fetchFromGitHub {
    owner = "varnholt";
    repo = "dynablaster_revenge";
    rev = "75538ac3f1080fbdf91c58b533e487ceb6eb2aec";
    sha256 = "0qpdq8x3sjwgrqrfyfjwsf90rklf3lj0l0x7s8d0ss3yadq110la";
  };

  postUnpack = ''
    export sourceRoot=$sourceRoot/${if isServer then "server" else "client"}
  '';

  postPatch = lib.optionalString isServer ''
    substituteInPlace server.pro \
      --replace 'TARGET = server' 'TARGET = ${meta.mainProgram}' \
      ${lib.optionalString isHeadless "--replace 'DEFINES += USE_GUI' '# Building headless'"}
  '';

  nativeBuildInputs = [
    qmake
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
  ] ++ lib.optionals (!isServer) ([
    libGLU
    SDL2
  ] ++ lib.optionals stdenv.isLinux [
    alsa-lib
  ]);

  installPhase = ''
    runHook preInstall

  '' + (if stdenv.isDarwin then ''
    mkdir -p $out/{Applications,bin}
    mv {,$out/Applications/}${meta.mainProgram}.app
    ln -s $out/{Applications/${meta.mainProgram}.app/Contents/MacOS,bin}/${meta.mainProgram}
  '' else ''
    install -Dm755 {,$out/bin/}${meta.mainProgram}
  '') + lib.optionalString (!isServer) ''
    mkdir -p $out/share/dynablaster
    cp -R data $out/share/dynablaster/
  '' + ''

    runHook postInstall
  '';

  preFixup = lib.optionalString (!isServer) ''
    qtWrapperArgs+=(
      # --chdir "$out/share/dynablaster"
      --run "cd $out/share/dynablaster"
    )
  '';

  meta = with lib; {
    description = "This is a remake of the game Dynablaster, released by Hudson Soft in 1991"
      + lib.optionalString isServer " (dedicated${lib.optionalString isHeadless " headless"} server)";
    mainProgram = "dynablaster" + lib.optionalString isServer "-server";
    homepage = "https://github.com/varnholt/dynablaster_revenge";
    maintainers = with maintainers; [ luz ];
    license = with licenses; [ zlib lgpl3Only ];
    platforms = platforms.all;
    broken = (!isServer) && stdenv.isDarwin; # Missing audio backend code, unplayable even when patched
  };
}
