{ stdenv
, lib
, fetchFromGitHub
, cmake
, pkg-config
, qttools
, wrapQtAppsHook
, qtbase
, qt5compat
, rtaudio
, rtmidi
}:

stdenv.mkDerivation rec {
  pname = "bambootracker";
  version = "unstable-2022-04-06";

  src = fetchFromGitHub {
    owner = "BambooTracker";
    repo = "BambooTracker";
    rev = "7d7ba47dea4782f1b13c95b9648e4b1865cf68af";
    fetchSubmodules = true;
    sha256 = "0kxksc9whsq7v05skiaszybmsfj80c59wfa9ypn3n6mk8lfnpg23";
  };

  nativeBuildInputs = [ cmake qttools pkg-config wrapQtAppsHook ];

  buildInputs = [ qtbase qt5compat rtaudio rtmidi ];

  cmakeFlags = [ "-DSYSTEM_RTAUDIO=ON" "-DSYSTEM_RTMIDI=ON" ];

  # Darwin untested on Qt6, I only have x86_64-darwin hardware
  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir -p $out/Applications
    mv $out/{bin,Applications}/BambooTracker.app
    ln -s $out/{Applications/BambooTracker.app/Contents/MacOS,bin}/BambooTracker
  '';

  meta = with lib; {
    description = "A tracker for YM2608 (OPNA) which was used in NEC PC-8801/9801 series computers";
    homepage = "https://bambootracker.github.io/BambooTracker/";
    license = licenses.gpl2Plus;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
