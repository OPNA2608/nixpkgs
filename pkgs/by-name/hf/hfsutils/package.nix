{
  stdenv,
  lib,
  autoreconfHook,
  fetchzip,
  fetchDebianPatch,
  testers,
  withTclTk ? true,
  tcl,
  tk,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hfsutils";
  version = "3.2.6";

  src = fetchzip {
    url = "ftp://ftp.mars.org/pub/hfs/hfsutils-${finalAttrs.version}.tar.gz";
    hash = "sha256-GyfFhZLtaFB4VHV7eZTiMkZYxxpZeD+XmKFpKBHXY98=";
  };

  patches = [
    # Fix general issues with the build system
    (fetchDebianPatch {
      inherit (finalAttrs) pname version;
      debianRevision = "15";
      patch = "0001-Fix-build-system-issues.patch";
      hash = "sha256-GNEW6+9Wtne0FksuUVo0wGRYXW/oXno14YR2Uw+w2Yk=";
    })

    # Include errno properly, fix FTBFS with Tcl/Tk enabled
    (fetchDebianPatch {
      inherit (finalAttrs) pname version;
      debianRevision = "15";
      patch = "0002-Fix-FTBFS-with-gcc-3.4.patch";
      hash = "sha256-3xOuEFHJeuVBmdqT/fec1jOxdBiXoUFG7ixGztJlxic=";
    })

    # Support files > 2GB
    (fetchDebianPatch {
      inherit (finalAttrs) pname version;
      debianRevision = "15";
      patch = "0003-Add-support-for-files-larger-than-2GB.patch";
      hash = "sha256-vXRjfJE3mJZyt739Ji5PnMnb94X50QhF0gpwCxRYqc4=";
    })

    # interp->result was deprecated in Tcl, need to ask for it
    (fetchDebianPatch {
      inherit (finalAttrs) pname version;
      debianRevision = "15";
      patch = "0004-Add-DUSE_INTERP_RESULT-to-DEFINES-in-Makefile.in.patch";
      hash = "sha256-m0zDWZsMXcytaOyHUqo8Dbb5A9G2DyjX8TCGXvXVpmc=";
    })

    # Fix missing string.h
    (fetchDebianPatch {
      inherit (finalAttrs) pname version;
      debianRevision = "16";
      patch = "0005-Fix-missing-inclusion-of-string.h-in-hpwd.c.patch";
      hash = "sha256-PIksZZle+FCiexvecy4IOayNZD/X+Qa8DdE8Ej/p79U=";
    })
  ];

  strictDeps = true;

  postPatch = ''
    substituteInPlace Makefile.in \
      --replace-fail 'exec hfssh' "exec $out/bin/hfssh"
  '';

  nativeBuildInputs = [
    autoreconfHook
  ];

  buildInputs = lib.optionals withTclTk [
    tcl
    tk
  ];

  configureFlags = [
    (lib.strings.withFeatureAs withTclTk "tcl" tcl)
    (lib.strings.withFeatureAs withTclTk "tk" tk)
  ];

  enableParallelBuilding = true;

  # Some pointers should be passed as const to Tcl/Tk, but aren't
  env.NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";

  # Expects installation directories to already exist
  preInstall = ''
    mkdir -p $out/bin $out/share/man/man1
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "hvol --version";
  };

  meta = {
    description = "Comprehensive software package for manipulation of HFS volumes from UNIX and other systems";
    homepage = "https://www.mars.org/home/rob/proj/hfs/";
    # Website says GPLv2, running with --license says GPLv2+
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ OPNA2608 ];
    platforms = lib.platforms.unix;
  };
})
