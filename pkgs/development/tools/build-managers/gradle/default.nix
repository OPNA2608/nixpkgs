{
  fetchpatch,
  jdk17,
  jdk21,
}:

let
  bootstrapGen = import ./bootstrap.nix;
  gen = import ./generic.nix;
  wrapGradle = import ./wrapper.nix;
in
{
  inherit bootstrapGen gen wrapGradle;

  gradle_8-bootstrap = bootstrapGen {
    version = "8.13";
    hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
    defaultJava = jdk21;
  };
  gradle_8 = gradleBootstrap: gen {
    inherit gradleBootstrap;
    hash = "sha256-IUFNblQxOcli6pWkxhpYXrd7eo/UWqFvKBI0rksCxmE=";
    patches = [
      (fetchpatch {
        url = "https://github.com/gradle/gradle/commit/4bd1605f6197a88478c8b85527c70a9b4f8c6399.patch";
        includes = [ "gradle/gradle-daemon-jvm.properties" ];
        hash = "sha256-i5wC90obYZBr6B1UsmqxA3W1OmDkEGreeD8SeX0nSWk=";
      })
    ];
  };

  gradle_7-bootstrap = bootstrapGen {
    version = "7.6.4";
    hash = "sha256-vtHaM8yg9VerE2kcd/OLtnOIEZ5HlNET4FEDm4Cvm7E=";
    defaultJava = jdk17;
  };
  gradle_7 = gradleBootstrap: gen {
    inherit gradleBootstrap;
    hash = "";
  };
}
