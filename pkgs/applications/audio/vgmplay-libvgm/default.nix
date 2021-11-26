{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, nix-update-script
, cmake
, pkg-config
, zlib
, libvgm
, inih
, libiconv
}:

stdenv.mkDerivation rec {
  pname = "vgmplay-libvgm";
  version = "0.51.0";

  src = fetchFromGitHub {
    owner = "ValleyBell";
    repo = "vgmplay-libvgm";
    rev = version;
    sha256 = "18s8zazg72sz3fammx6aippa4f7ry6afjb5d3fvsar2ai01zhlgv";
  };

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = [ zlib libvgm inih ]
    ++ lib.optional stdenv.hostPlatform.isDarwin libiconv;

  postInstall = ''
    install -Dm644 ../VGMPlay.ini $out/share/vgmplay/VGMPlay.ini
  '';

  passthru.updateScript = nix-update-script {
    attrPath = pname;
  };

  meta = with lib; {
    mainProgram = "vgmplay";
    homepage = "https://github.com/ValleyBell/vgmplay-libvgm";
    description = "New VGMPlay, based on libvgm";
    license = licenses.unfree; # no licensing text anywhere yet
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.all;
  };
}
