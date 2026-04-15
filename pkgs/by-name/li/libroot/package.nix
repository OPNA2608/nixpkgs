{
  stdenvNoLibc,
  lib,
  fetchgit,
  attr,
  jam-haiku,
  nasm,
  python3,
}:

stdenvNoLibc.mkDerivation (finalAttrs: {
  pname = "libroot";
  version = "59630";

  src = fetchgit {
    url = "https://review.haiku-os.org/haiku";
    rev = "hrev${finalAttrs.version}";
    hash = "sha256-SYfzvPKK/OFnIGTCqAcrcr+uKnlGrOKu7/0j8gzcBfk=";
  };

  # Don't care about building the 32-bit boot loader
  postPatch = ''
    substituteInPlace configure \
      --replace-fail 'if [ "$bootLibSupCxx" = "libsupc++.a" ]; then' 'if false; then'
  '';

  nativeBuildInputs = [
    attr
    jam-haiku
    nasm
    python3
  ];

  configureFlags = [
    "--no-downloads"
  ]
  ++ lib.optionals (!lib.systems.equals stdenvNoLibc.buildPlatform stdenvNoLibc.hostPlatform) [
    "--cross-tools-prefix"
    "${stdenvNoLibc.cc}/bin/${stdenvNoLibc.cc.targetPrefix}"
  ];

  # Not recognised
  dontAddPrefix = true;

  # Handled via --cross-tools-prefix instead
  configurePlatforms = [ ];

  buildPhase = ''
    runHook preBuild

    cd src/system/libroot
    jam ''${enableParallelBuilding:+-j$NIX_BUILD_CORES}

    runHook postBuild
  '';

  env = {
    HAIKU_REVISION = "hrev${finalAttrs.version}";
  };

  meta = {
    description = "Haiku's C library";
    homepage = "https://www.haiku-os.org";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.OPNA2608 ];
    platforms = lib.platforms.haiku;
  };
})
