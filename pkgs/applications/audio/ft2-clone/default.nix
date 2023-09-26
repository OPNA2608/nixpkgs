{ lib, stdenv
, fetchFromGitHub
, fetchpatch
, cmake
, nixosTests
, alsa-lib
, SDL2
, libiconv
, CoreAudio
, CoreMIDI
, CoreServices
, Cocoa
}:

stdenv.mkDerivation rec {
  pname = "ft2-clone";
  version = "1.69";

  src = fetchFromGitHub {
    owner = "8bitbubsy";
    repo = "ft2-clone";
    rev = "v${version}";
    sha256 = "sha256-tm0yTh46UKnsjH9hv3cMW0YL2x3OTRL+14x4c7w124U=";
  };

  patches = [
    # Adapt CMake script to be Darwin-compatible
    # Remove when version > 1.69
    (fetchpatch {
      name = "0001-ft2-clone-Fix-CMakeLists.txt-for-Darwin.patch";
      url = "https://github.com/8bitbubsy/ft2-clone/commit/b859dd5bbe22356ebbd152e4b9c166024ba4df7d.patch";
      hash = "sha256-W2kPi208qjJWNRkEE6RKR/11pCPBX+KIgGoF7gljh74=";
    })
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ SDL2 ]
    ++ lib.optional stdenv.isLinux alsa-lib
    ++ lib.optionals stdenv.isDarwin [
         libiconv
         CoreAudio
         CoreMIDI
         CoreServices
         Cocoa
       ];

  passthru.tests = {
    ft2-clone-starts = nixosTests.ft2-clone;
  };

  meta = with lib; {
    description = "A highly accurate clone of the classic Fasttracker II software for MS-DOS";
    homepage = "https://16-bits.org/ft2.php";
    license = licenses.bsd3;
    maintainers = with maintainers; [ fgaz ];
    # From HOW-TO-COMPILE.txt:
    # > This code is NOT big-endian compatible
    platforms = platforms.littleEndian;
  };
}

