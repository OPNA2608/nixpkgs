{ lib, stdenv, fetchurl, fetchpatch, autoreconfHook, darwin }:

stdenv.mkDerivation rec {
  pname = "webrtc-audio-processing";
  version = "0.3.1";

  src = fetchurl {
    url = "https://freedesktop.org/software/pulseaudio/webrtc-audio-processing/webrtc-audio-processing-${version}.tar.xz";
    sha256 = "1gsx7k77blfy171b6g3m0k0s0072v6jcawhmx1kjs9w5zlwdkzd0";
  };

  patches = [
    ./enable-riscv.patch
    ./enable-powerpc.patch
    (fetchpatch {
      name = "enable-mips-and-big-endian.patch";
      url = "https://github.com/void-linux/void-packages/raw/0c9bd3db16797d6a5eb9319179ca3ed6d1cc083c/srcpkgs/webrtc-audio-processing/patches/mips.patch";
      sha256 = "sha256-lMRHLzjk7K5ZQB8G4WCmrH+y4+5G+Wbd4Hyl6kWDbrA=";
    })
  ];

  postPatch = ''
    # Remove failing statement PKG_CHECK_MODULE(GNUSTL, gnustl)
    sed -i configure.ac -e'/if test "x$with_gnustl" != "xno"; then/,+2d'
  '';

  nativeBuildInputs = [ autoreconfHook ];

  buildInputs = lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ ApplicationServices ]);

  patchPhase = lib.optionalString stdenv.hostPlatform.isMusl ''
    substituteInPlace webrtc/base/checks.cc --replace 'defined(__UCLIBC__)' 1
  '';

  meta = with lib; {
    homepage = "http://www.freedesktop.org/software/pulseaudio/webrtc-audio-processing";
    description = "A more Linux packaging friendly copy of the AudioProcessing module from the WebRTC project";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
