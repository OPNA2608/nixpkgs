{ codename
, rev
, isRelease ? false
, sha256
}:

{ stdenv, lib, fetchsvn
, fbc
, openeuphoria
, scons
, libX11
, libXext
, libXinerama
, libXpm
, libXrandr
, libXrender
, ncurses
, SDL2
, SDL2_mixer
, xorgproto
, libxml2
}:

let
  dir = if isRelease then "rel/${codename}" else "wip";
  includeflagDeps = [
    ncurses
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    libX11
    libXinerama
    xorgproto
  ];
  linkflagDeps = [
    ncurses
    SDL2
    SDL2_mixer
    libxml2
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    libX11
    libXext
    libXinerama
    libXpm
    libXrandr
    libXrender
  ];
in
stdenv.mkDerivation rec {
  pname = "ohrrpgce-${codename}";
  version = "${lib.optionalString (!isRelease) "unstable-"}${rev}";

  src = fetchsvn {
    name = "${pname}-r${rev}";
    url = "https://rpg.hamsterrepublic.com/source/${dir}";
    inherit rev sha256;
  };

  postPatch = let
    linkflagName = if (lib.versionAtLeast rev "12996") then "CCLINKFLAGS" else "CXXLINKFLAGS";
  in ''
    patchShebangs .
    substituteInPlace SConscript \
      --replace "CFLAGS = ['-Wall'" "CFLAGS = ['-Wall','${lib.strings.concatMapStringsSep "','" (x: "-isystem" + lib.getDev x + "/include") includeflagDeps}'" \
      --replace "${linkflagName} = [" "${linkflagName} = ['${lib.strings.concatMapStringsSep "','" (x: "-L" + lib.makeLibraryPath [ x ]) linkflagDeps}'" \
      ${lib.optionalString (lib.versionOlder rev "12996") ''--replace "'common_libraries': libfbgfx" "'common_libraries': 'fbgfxmt fbmt'"''} \

    # For test that checks access to file without permissions
    substituteInPlace filetest.bas \
      --replace "/etc/sudoers" "$PWD/unreadable"
    touch unreadable
    chmod a-r unreadable
  '';

  preConfigure = ''
    echo 'Revision: ${rev}' > svninfo.txt
  '';

  nativeBuildInputs = [
    scons
    fbc
  ];

  buildInputs = linkflagDeps ++ [
    openeuphoria
  ];

  sconsFlags = [
    # "gfx=sdl2+fb"
    "gfx=sdl2"
    "music=sdl2"
    # "release=1" needs nixpkgs-compiled openeuphoria, https://github.com/ohrrpgce/ohrrpgce/issues/1119
    "lto=0"
    "asan=0"
    "profile=0"
    "asm=0"
    "portable=0"
  ];

  enableParallelBuilding = true;

  buildFlags = [
    "ohrrpgce-game"
    "ohrrpgce-custom"
    "unlump"
    "relump"
    "hspeak"
    "reload2xml"
    "xml2reload"
  ];

  # doCheck = true;
  doCheck = false;

  # checkFlags doesn't work
  checkFlagsArray = [
    "reloadtest"
    "rbtest"
    "vectortest"
    "utiltest"
    "filetest"
    "commontest"
    # "hspeaktest" bad exit code despite passing with all errors marked as known-failures
    # "miditest" expects interactive input, passes but not sure if useful
    # "autotest" needs graphics
    # "interactivetest" needs graphics
  ];

  # Manually run tests that don't get executed by scons targets
  postCheck = ''
    for test in ${toString checkFlagsArray}; do
      echo $test
      ./$test
    done
  '';

  postInstall = ''
    mv $out/{games,bin}
    for extraTool in reload2xml xml2reload; do
      install -m755 $extraTool $out/bin/$extraTool
    done
  '';

  passthru.updateScript = lib.optional (!isRelease) ./update.sh;
}

