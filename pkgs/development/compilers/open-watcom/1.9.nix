{
  stdenv,
  lib,
  fetchurl,
  open-watcom-bin-unwrapped,
  which,

  # Docs cause an immense increase in build time, up to 2 additional hours
  withDocs ? false,
  ghostscript,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "${finalAttrs.passthru.prettyName}-unwrapped";
  version = "1.9";

  src = fetchurl {
    url = "https://openwatcom.org/ftp/source/open_watcom_1.9.0-src.tar.bz2";
    hash = "sha256-bTAzJ5iO4t2mDPq+vz9FqXWK7k2hF9Qc8xU/zLfl5L8=";
  };

  postPatch = ''
    patchShebangs *.sh
  ''
  # source called in build.sh can't find setvars.sh
  + ''
    substituteInPlace build.sh \
      --replace-fail '. setvars' '. ./setvars'
  ''
  # w32loadr just seems borked, can't get it to compile
  /*+ ''
    substituteInPlace bld/lang.ctl \
      --replace-fail \
        '[ INCLUDE <DEVDIR>/w32loadr/prereq.ctl ]' \
        '#[ INCLUDE <DEVDIR>/w32loadr/prereq.ctl ]' \
      --replace-fail \
        '[ INCLUDE <DEVDIR>/w32loadr/lang.ctl ]' \
        '#[ INCLUDE <DEVDIR>/w32loadr/lang.ctl ]'
  ''*/
  # Seems to be missing a clib3r at link time (which happens during installPhase?)
  /*+ ''
    substituteInPlace bld/boot.ctl \
      --replace-fail \
        '[ INCLUDE <DEVDIR>/dip/boot.ctl ]' \
        '#[ INCLUDE <DEVDIR>/dip/boot.ctl ]' \
      --replace-fail \
        '[ INCLUDE <DEVDIR>/mad/boot.ctl ]' \
        '#[ INCLUDE <DEVDIR>/mad/boot.ctl ]'

    substituteInPlace bld/lang.ctl \
      --replace-fail \
        '[ INCLUDE <DEVDIR>/dip/lang.ctl ]' \
        '#[ INCLUDE <DEVDIR>/dip/lang.ctl ]' \
      --replace-fail \
        '[ INCLUDE <DEVDIR>/mad/lang.ctl ]' \
        '#[ INCLUDE <DEVDIR>/mad/lang.ctl ]'
  ''*/
  # Don't build wstub. Build script wants to build it before clib, but linking it requires clib.
  /*+ ''
    substituteInPlace bld/lang.ctl \
      --replace-fail \
        '[ INCLUDE <DEVDIR>/wstub/lang.ctl ]' \
        '#[ INCLUDE <DEVDIR>/wstub/lang.ctl ]'
  ''*/;

  nativeBuildInputs = [
    which
  ]
  ++ lib.optionals withDocs [
    ghostscript
  ];

  configurePhase = ''
    runHook preConfigure

    substituteInPlace setvars.sh \
      --replace-fail 'WATCOM=$OWROOT/rel2' 'WATCOM=${open-watcom-bin-unwrapped}' \
      --replace-fail 'OWROOT=' "OWROOT=$PWD #" \
      --replace-fail 'DOC_BUILD=0' 'DOC_BUILD=${if withDocs then "1" else "0"}' \
      --replace-fail 'GHOSTSCRIPT=/usr/bin' 'GHOSTSCRIPT=${lib.optionalString withDocs "${lib.makeBinPath [ ghostscript ]}"}'

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
  ''
  # Bootstrap new Linux-native binaries (open-watcom-bin binaries run under slow qemu-user emulation due to kernel incompatibilities)
  # - wmake first, otherwise build process is done completely under qemu-user
  # - then builder, to orchestrate the rest of the build
  # - then the rest of the Linux toolchain, via freshly build wmake & builder
  + ''
    (
      source ./setvars.sh
      cd bld

      pushd wmake
      $MAKE -f gnumake
      popd

      pushd builder
      mkdir build
      cd build
      wmake -h -f ../linux386/makefile builder.exe
      popd

      builder rel2 os_linux
    ) 2>&1 | tee bootstrap.log
    tail -n1 bootstrap.log | grep -q "Build failed" && exit 1 || true
  ''
  # Do full build with freshly built Linux toolchain now
  + ''
    (
      source ./setvars.sh

      cd bld

      builder rel2
    ) 2>&1 | tee build.log
    tail -n1 build.log | grep -q "Build failed" && exit 1 || true

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Move everything to final location
    mv rel2 $out

    runHook postInstall
  '';

  # Stripping breaks many tools
  dontStrip = true;

  env.NIX_CFLAGS_COMPILE = toString [
    # Source is *ooooooooold*, defines its requirements very poorly
    "-std=gnu99"

    # For now, just accept that const'ness in pointer args isn't always being considered
    "-Wno-error=incompatible-pointer-types"
  ];

  hardeningDisable = [
    # For now, just accept that this isn't always being considered
    "format"

    # https://github.com/open-watcom/open-watcom-v2/issues/1608
    "strictflexarrays1"
  ];

  passthru = {
    prettyName = "open-watcom";
  };

  meta = {
    description = "TODO";
    homepage = "https://openwatcom.org/";
    license = lib.licenses.watcom;
    platforms = lib.platforms.windows ++ [
      "i686-linux"
    ];
    maintainers = with lib.maintainers; [ OPNA2608 ];
  };
})
