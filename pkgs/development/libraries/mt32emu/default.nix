{ lib
, stdenv
, fetchFromGitHub
, cmake
}:

stdenv.mkDerivation rec {
  pname = "mt32emu";
  version = "2.5.3";

  src = fetchFromGitHub {
    owner = "munt";
    repo = "munt";
    rev = "libmt32emu_${lib.replaceChars [ "." ] [ "_" ] version}";
    sha256 = "0vifdsb0nw1fsdzxwqyw1vzh1blp1aqvmxv482ax7mi15kjmb5cz";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    cmake
  ];

  dontFixCmake = true;

  cmakeFlags = [
    "-Dmunt_WITH_MT32EMU_SMF2WAV=OFF"
    "-Dmunt_WITH_MT32EMU_QT=OFF"
  ];

  meta = with lib; {
    description = "Munt mt32emu: Library which allows to emulate (approximately) the Roland MT-32, CM-32L, CM-64 and LAPC-I synthesiser modules";
    homepage = "http://munt.sourceforge.net/";
    license = with licenses; [ lgpl21Plus ];
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
