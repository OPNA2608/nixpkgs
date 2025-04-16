{
  lib,
  callPackage,
  mitm-cache,
  replaceVars,
  symlinkJoin,
  concatTextFile,
  makeSetupHook,
  nix-update-script,
  runCommand,
  jdk11,
  jdk23,
}:
gradle-unwrapped: updateAttrPath:
lib.makeOverridable (
  args:
  let
    gradle = gradle-unwrapped.override args;
  in
  symlinkJoin {
    pname = "gradle";
    inherit (gradle) version;

    paths = [
      (makeSetupHook { name = "gradle-setup-hook"; } (concatTextFile {
        name = "setup-hook.sh";
        files = [
          (mitm-cache.setupHook)
          (replaceVars ./setup-hook.sh {
            # jdk used for keytool
            inherit (gradle) jdk;
            init_script = "${./init-build.gradle}";
          })
        ];
      }))
      gradle
      mitm-cache
    ];

    passthru =
      {
        fetchDeps = callPackage ./fetch-deps.nix { inherit mitm-cache; };
        inherit (gradle) jdk;
        unwrapped = gradle;
        tests = {
          toolchains =
            runCommand "detects-toolchains-from-nix-env"
              {
                # Use JDKs that are not the default for any of the gradle versions
                nativeBuildInputs = [
                  (gradle.override {
                    javaToolchains = [
                      jdk11
                      jdk23
                    ];
                  })
                ];
                src = ./tests/java-application;
              }
              ''
                cp -a $src/* .
                env GRADLE_USER_HOME=$TMPDIR/gradle org.gradle.native.dir=$TMPDIR/native \
                  gradle javaToolchains --no-daemon --quiet --console plain > $out
                cat $out | grep "Language Version:   11"
                cat $out | grep "Detected by:        environment variable 'JAVA_TOOLCHAIN_NIX_0'"
                cat $out | grep "Language Version:   23"
                cat $out | grep "Detected by:        environment variable 'JAVA_TOOLCHAIN_NIX_1'"
              '';
        } // gradle.tests;
      }
      // lib.optionalAttrs (updateAttrPath != null) {
        updateScript = nix-update-script {
          attrPath = updateAttrPath;
          extraArgs = [
            "--url=https://github.com/gradle/gradle"
            # Gradle’s .0 releases are tagged as `vX.Y.0`, but the actual
            # release version omits the `.0`, so we’ll wanto to only capture
            # the version up but not including the the trailing `.0`.
            "--version-regex=^v(\\d+\\.\\d+(?:\\.[1-9]\\d?)?)(\\.0)?$"
          ];
        };
      };

    meta = gradle.meta // {
      # prefer normal gradle/mitm-cache over this wrapper, this wrapper only provides the setup hook
      # and passthru
      priority = (gradle.meta.priority or lib.meta.defaultPriority) + 1;
    };
  }
) { }
