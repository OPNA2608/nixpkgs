{ stdenv
, lib
, nix-update-script
, fetchFromGitHub
, fetchpatch
, cmake
, pkg-config
, makeWrapper
, fmt_8
, libsndfile
, SDL2
, zlib
, withJACK ? stdenv.hostPlatform.isUnix
, libjack2
, withGUI ? true
, Cocoa
}:

let
  version = "0.5.5";
  src = fetchFromGitHub {
    owner = "tildearrow";
    repo = "furnace";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "sha256-8CHRrfCe/lLPH6LYpzJUqXPSAe83v0zU18ooIDLtF84=";
  };
  # SDL 2.0.18+ is needed, not packages yet
  # https://github.com/NixOS/nixpkgs/issues/154137
  vendoredSDL2 = SDL2.overrideAttrs (oa: {
    version = "2.0.x-furnace";
    src = "${src}/extern/SDL";
    patches = [];
  });
in
stdenv.mkDerivation rec {
  pname = "furnace";

  inherit version src;

  patches = [
    (fetchpatch {
      name = "0001-furnace-Fix-ObjC-code-linking.patch";
      url = "https://github.com/tildearrow/furnace/commit/f56d771a4dded1299fe4f0acb3382e2e4115dc74.patch";
      sha256 = "1vi6934fsld7kx9wyx0mhxvgkp0z95ar6q3zbj5i9kcdhfqa2cdw";
    })
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    makeWrapper
  ];

  buildInputs = [
    fmt_8
    libsndfile
    vendoredSDL2
    zlib
  ] ++ lib.optionals withJACK [
    libjack2
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    Cocoa
  ];

  cmakeFlags = [
    "-DBUILD_GUI=${if withGUI then "ON" else "OFF"}"
    "-DSYSTEM_FMT=ON"
    "-DSYSTEM_LIBSNDFILE=ON"
    "-DSYSTEM_ZLIB=ON"
    "-DSYSTEM_SDL2=ON"
    "-DWITH_JACK=${if withJACK then "ON" else "OFF"}"
    "-DWARNINGS_ARE_ERRORS=ON"
  ];

  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    # Normal CMake install phase on Darwin only installs the binary, the user is expected to use CPack to build a
    # bundle. That adds alot of overhead for not much benefit (CPack is currently abit broken, and needs impure access
    # to /usr/bin/hdiutil). So we'll manually assemble & install everything instead.

    mkdir -p $out/{Applications/Furnace.app/Contents/{MacOS,Resources},share/{,doc,licenses}/furnace}
    mv $out/{bin,Applications/Furnace.app/Contents/MacOS}/furnace
    makeWrapper $out/{Applications/Furnace.app/Contents/MacOS,bin}/furnace

    install -m644 {../res,$out/Applications/Furnace.app/Contents}/Info.plist
    install -m644 ../res/icon.icns $out/Applications/Furnace.app/Contents/Resources/Furnace.icns
    install -m644 {..,$out/share/licenses/furnace}/LICENSE
    cp -r ../papers $out/share/doc/furnace/
    cp -r ../demos $out/share/furnace/
  '';

  passthru.updateScript = nix-update-script {
    attrPath = pname;
  };

  meta = with lib; {
    description = "Multi-system chiptune tracker compatible with DefleMask modules";
    homepage = "https://github.com/tildearrow/furnace";
    license = with licenses; [ gpl2Plus ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.all;
  };
}
