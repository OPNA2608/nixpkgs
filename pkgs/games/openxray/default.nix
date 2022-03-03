{ lib
, stdenv
, fetchFromGitHub
, cmake
, glew
, freeimage
, liblockfile
, openal
, libtheora
, SDL2
, lzo
, libjpeg
, libogg
, pcre
, makeWrapper
, enableMultiplayer ? false # Requires old, insecure Crypto++ version
}:

stdenv.mkDerivation rec {
  pname = "openxray";
  version = "unstable-2022-02-20";

  src = fetchFromGitHub {
    owner = "OpenXRay";
    repo = "xray-16";
    rev = "35fbe9728941dda2654dd62249c3a22c8b758e3b";
    fetchSubmodules = true;
    sha256 = "0afgg97g4dqg7kazrybkcq00y916pdibncnca09nc1c4fqva0kjh";
  };

  buildInputs = [
    glew
    freeimage
    liblockfile
    openal
    libtheora
    SDL2
    lzo
    libjpeg
    libogg
    pcre
  ];

  nativeBuildInputs = [ cmake makeWrapper ];

  cmakeFlags = [
    "-DUSE_CRYPTOPP=${if enableMultiplayer then "ON" else "OFF"}"
  ];

  postInstall = ''
    # needed because of SDL_LoadObject library loading code
    wrapProgram $out/bin/xr_3da \
      --prefix LD_LIBRARY_PATH : $out/lib
  '';

  meta = with lib; {
    description = "Improved version of the X-Ray Engine, the game engine used in the world-famous S.T.A.L.K.E.R. game series by GSC Game World";
    homepage = src.meta.homepage;
    license = licenses.unfree // {
      url = "https://github.com/OpenXRay/xray-16/blob/xd_dev/License.txt";
    };
    knownVulnerabilities = lib.optionals enableMultiplayer [
      "CVE-2019-14318"
      "outdated in general"
    ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
}
