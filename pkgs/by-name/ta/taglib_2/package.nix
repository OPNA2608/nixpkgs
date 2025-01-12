{
  lib,
  fetchFromGitHub,
  taglib,
  utf8cpp,
}:

taglib.overrideAttrs (
  finalAttrs: oldAttrs: {
    version = "2.0.2";

    src = fetchFromGitHub {
      owner = "taglib";
      repo = "taglib";
      rev = "v${finalAttrs.version}";
      hash = "sha256-3cJwCo2nUSRYkk8H8dzyg7UswNPhjfhyQ704Fn9yNV8=";
    };

    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
      utf8cpp
    ];

    # Make sure position is correct, and fix missing platform until https://github.com/NixOS/nixpkgs/pull/373233
    meta = {
      inherit (oldAttrs.meta)
        description
        longDescription
        homepage
        license
        mainProgram
        maintainers
        pkgConfigModules
        ;
      platforms = lib.platforms.all;
    };
  }
)
