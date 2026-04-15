{
  lib,
  jam,
  fetchgit,
}:

jam.overrideAttrs (oa: rec {
  pname = "jam-haiku";
  version = "43224";

  src = fetchgit {
    url = "https://review.haiku-os.org/buildtools";
    rev = "btrev${version}";
    hash = "sha256-nt5gHWvsKq69XGl4PfHEWNYdiBiure1MJGaaJYdw9ls=";
  };

  sourceRoot = "${src.name}/jam";

  # jam is an stdenv dep here, can't just execute pkgsBuildTarget CC
  # TODO Maybe implement by inspecting stdenv.targetPlatform
  postPatch = ''
    substituteInPlace jam.h \
      --replace-fail 'ifdef linux' 'ifdef __linux__'
  '';

  # This Jambase *doesn't* expect ar to have flags
  preConfigure = "";

  env = oa.env // {
    # Uses _GNU_SOURCE-gated things
    NIX_CFLAGS_COMPILE = "-std=gnu89";
  };

  meta = oa.meta // {
    description = "${oa.meta.description} (HaikuOS version)";
    maintainers = oa.meta.maintainers ++ [
      lib.maintainers.OPNA2608
    ];
    platforms = oa.meta.platforms ++ lib.platforms.haiku;
  };
})
