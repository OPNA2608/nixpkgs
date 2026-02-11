{
  stdenv,
}:
stdenv.mkDerivation {
  pname = "ppm2osbadgeicon";
  version = "3";

  src = ./ppm2osbadgeicon.c;

  dontUnpack = true;
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    $CC -std=c99 -Wall -Wextra -pedantic -Werror $src -o ppm2osbadgeicon -lm

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 -t $out/bin ppm2osbadgeicon

    runHook postInstall
  '';
}
