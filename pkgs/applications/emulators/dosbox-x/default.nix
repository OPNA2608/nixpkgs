{ lib
, stdenv
, fetchFromGitHub
, alsa-lib
, autoreconfHook
, ffmpeg
, fluidsynth
, freetype
, glib
, libpcap
, libpng
, libslirp
, libxkbfile
, libXrandr
, makeWrapper
, ncurses
, pkg-config
, SDL2
, SDL2_net
, yad
, zlib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dosbox-x";
  version = "2023.09.01";

  src = fetchFromGitHub {
    owner = "joncampbell123";
    repo = "dosbox-x";
    rev = "dosbox-x-v${finalAttrs.version}";
    hash = "sha256-gEqIPXrq16p6VC9aGW2sRSWE0SG9hiMWeRzSoDvUbB0=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    autoreconfHook
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    alsa-lib
    ffmpeg
    fluidsynth
    freetype
    glib
    libpcap
    libpng
    libslirp
    libxkbfile
    libXrandr
    ncurses
    SDL2
    SDL2_net
    yad
    zlib
  ];

  configureFlags = [ "--enable-sdl2" ];

  enableParallelBuilding = true;

  hardeningDisable = [ "format" ]; # https://github.com/joncampbell123/dosbox-x/issues/4436

  postInstall = ''
    wrapProgram $out/bin/dosbox-x \
      --prefix PATH : ${lib.makeBinPath [ yad ]}
  '';

  meta = {
    homepage = "https://dosbox-x.com";
    description = "A cross-platform DOS emulator based on the DOSBox project";
    longDescription = ''
      DOSBox-X is an expanded fork of DOSBox with specific focus on running
      Windows 3.x/9x/Me, PC-98 and 3D support via 3dfx.

      The full expanded feature list is available here:
      https://dosbox-x.com/wiki/DOSBox%E2%80%90X%E2%80%99s-Feature-Highlights
    '';
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ hughobrien OPNA2608 ];
    platforms = lib.platforms.linux;
    mainProgram = "dosbox-x";
  };
})
