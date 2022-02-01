{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, mt32emu
, glib
}:

stdenv.mkDerivation rec {
  pname = "mt32emu-smf2wav";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "munt";
    repo = "munt";
    rev = "mt32emu_smf2wav_${lib.replaceChars [ "." ] [ "_" ] version}";
    sha256 = "18pr91hnn05idwnnhji0sgfvk3apl18s3x4vm8cgxv2ykhlaawhn";
  };

  postPatch = ''
    sed -i -e '/add_subdirectory(mt32emu)/d' CMakeLists.txt
  '';

  dontFixCmake = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    mt32emu
    glib
  ];

  cmakeFlags = [
    "-Dmunt_WITH_MT32EMU_SMF2WAV=ON"
    "-Dmunt_WITH_MT32EMU_QT=OFF"
  ];

  meta = with lib; {
    homepage = "http://munt.sourceforge.net/";
    description = "Munt mt32emu-smf2wav: Uses mt32emu library to produce a WAVE file from a Standard MIDI file (SMF)";
    license = with licenses; [ gpl3Plus ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.all;
    mainProgram = "mt32emu-smf2wav";
  };
}
