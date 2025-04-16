{
  gradleBootstrap,
  hash,
  patches ? [ ],
}:

{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  unzip,
  ncurses5,
  ncurses6,
  udev,
  testers,
  runCommand,
  writeText,
  autoPatchelfHook,
  buildPackages,

  # The JDK/JRE used for running Gradle.
  java ? gradleBootstrap.passthru.jdk,
}:

let
  inherit (gradleBootstrap) version;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle";
  inherit version;

  src = fetchurl {
    inherit hash;
    url = "https://services.gradle.org/distributions/gradle-${version}-src.zip";
  };

  inherit patches;

  strictDeps = true;

  nativeBuildInputs = [
    gradleBootstrap
    unzip
  ];

  mitmCache = gradleBootstrap.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./. + "/gradle-${version}-deps.json";
  };

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = ''
        env GRADLE_USER_HOME=$TMPDIR/gradle org.gradle.native.dir=$TMPDIR/native \
          gradle --version
      '';
    };

    java-application = testers.testEqualContents {
      assertion = "can build and run a trivial Java application";
      expected = writeText "expected" "hello\n";
      actual =
        runCommand "actual"
          {
            nativeBuildInputs = [ finalAttrs.finalPackage ];
            src = ./tests/java-application;
          }
          ''
            cp -a $src/* .
            env GRADLE_USER_HOME=$TMPDIR/gradle org.gradle.native.dir=$TMPDIR/native \
              gradle run --no-daemon --quiet --console plain > $out
          '';
    };
  };
  passthru.jdk = java;

  meta =
    {
      description = "Enterprise-grade build system";
      longDescription = ''
        Gradle is a build system which offers you ease, power and freedom.
        You can choose the balance for yourself. It has powerful multi-project
        build support. It has a layer on top of Ivy that provides a
        build-by-convention integration for Ivy. It gives you always the choice
        between the flexibility of Ant and the convenience of a
        build-by-convention behavior.
      '';
      homepage = "https://www.gradle.org/";
      changelog = "https://docs.gradle.org/${version}/release-notes.html";
      downloadPage = "https://gradle.org/next-steps/?version=${version}";
      sourceProvenance = with lib.sourceTypes; [
        binaryBytecode
        binaryNativeCode
      ];
      license = lib.licenses.asl20;
      maintainers =
        with lib.maintainers;
        [
          britter
          liff
          lorenzleutgeb
        ]
        ++ lib.teams.java.members;
      mainProgram = "gradle";
    };
})
