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
  version = "1144-december-2021-rc1";

  src = fetchFromGitHub {
    owner = "OpenXRay";
    repo = "xray-16";
    rev = version;
    fetchSubmodules = true;
    sha256 = "07qj1lpp21g4p583gvz5h66y2q71ymbsz4g5nr6dcys0vm7ph88v";
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
