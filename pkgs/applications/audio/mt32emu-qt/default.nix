{ lib
, stdenv
, mkDerivation
, fetchFromGitHub
, cmake
, pkg-config
, mt32emu
, qtbase
, qtmultimedia
, alsa-lib
, portaudio
, libpulseaudio
, withJack ? stdenv.hostPlatform.isUnix, libjack2
}:

mkDerivation rec {
  pname = "mt32emu-qt";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "munt";
    repo = "munt";
    rev = "mt32emu_qt_${lib.replaceChars [ "." ] [ "_" ] version}";
    sha256 = "12p6y8d8icil1g6wxvcwbqfqi7g3kghbdpl0k2vx1m35m82akxpn";
  };

  postPatch = ''
    sed -i -e '/add_subdirectory(mt32emu)/d' CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    mt32emu
    qtbase
    qtmultimedia
    portaudio
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ alsa-lib libpulseaudio ]
  ++ lib.optional withJack libjack2;

  dontFixCmake = true;

  cmakeFlags = [
    "-Dmunt_WITH_MT32EMU_SMF2WAV=OFF"
    "-Dmunt_WITH_MT32EMU_QT=ON"
    "-Dmt32emu-qt_USE_PULSEAUDIO_DYNAMIC_LOADING=OFF"
  ];

  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir $out/Applications
    mv $out/bin/${meta.mainProgram}.app $out/Applications/
    ln -s $out/{Applications/${meta.mainProgram}.app/Contents/MacOS,bin}/${meta.mainProgram}
  '';

  meta = with lib; {
    homepage = "http://munt.sourceforge.net/";
    description = "Munt mt32emu-qt: Uses mt32emu library for realtime synthesis and conversion of pre-recorded Standard MIDI files to WAVE files";
    license = with licenses; [ gpl3Plus ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.all;
    mainProgram = "mt32emu-qt";
  };
}
