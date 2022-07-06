{ lib, stdenv, fetchFromGitHub
, SDL2, SDL2_image
, alsa-lib
, pkg-config
, withDebug ? false
}:

let
  cfg = if withDebug then "debug" else "release";
in
stdenv.mkDerivation rec {
  pname = "klystrack-plus";
  version = "unstable-2022-07-06";

  src = fetchFromGitHub {
    owner = "LTVA1";
    repo = "klystrack";
    rev = "8bc2ba5c8f61b15779d98b8a1076be2cc5a0dbd9";
    fetchSubmodules = true;
    sha256 = "sha256-uAX8pZL8i4vyTnldheyu/NBHpuaLz2QPZMZcse5HyMs=";
  };

  postPatch = ''
    # fix hardcoded / non-overridable compiler
    for file in klystron{,/tools/{editor,makebundle}}/Makefile; do
      substituteInPlace $file \
        --replace 'gcc' '${stdenv.cc.targetPrefix}cc'
    done

    # replace impure build dates
    for file in {,klystron/}Makefile; do
      substituteInPlace $file \
        --replace '$(Q)date' '$(Q)date -ud "@''${SOURCE_DATE_EPOCH}"'
    done
  '' + lib.optionalString (!stdenv.hostPlatform.isLinux) ''
    substituteInPlace Makefile \
      --replace "-lasound" ""
  '';

  nativeBuildInputs = [
    pkg-config
  ] ++ lib.optional stdenv.hostPlatform.isLinux [
    # Can't find alsa/asoundlib.h without
    alsa-lib.dev
  ];

  buildInputs = [
    SDL2
    SDL2_image
  ] ++ lib.optional stdenv.hostPlatform.isLinux [
    alsa-lib
  ];

  # Parallelism looks like it works, but resource compilation has a
  # very high chance of going wrong without causing a build failure
  enableParallelBuilding = false;

  buildFlags = [
    "PREFIX=${placeholder "out"}"
    "CC=${stdenv.cc.targetPrefix}cc"
    "CFG=${cfg}"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 bin.${cfg}/klystrack $out/bin/klystrack

    mkdir -p $out/lib/klystrack
    cp -R res $out/lib/klystrack
    cp -R key $out/lib/klystrack

    install -DT icon/256x256.png $out/share/icons/hicolor/256x256/apps/klystrack.png
    mkdir -p $out/share/applications
    substitute linux/klystrack.desktop $out/share/applications/klystrack.desktop \
      --replace "klystrack %f" "$out/bin/klystrack %f"

    runHook postInstall
  '';

  dontStrip = withDebug;

  meta = with lib; {
    description = "A fork of a chiptune tracker";
    homepage = "https://github.com/LTVA1/klystrack";
    license = licenses.mit;
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.all;
  };
}
